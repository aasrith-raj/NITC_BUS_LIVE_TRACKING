import hmac
import logging

from fastapi import FastAPI
from sqlalchemy import text, func

from jose import jwt
import os
from datetime import datetime, timedelta, timezone
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError

from dotenv import load_dotenv

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError

from app.database.connection import engine

from fastapi import Depends
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.database.dependencies import get_db
from app.models import Bus
from app.schemas.bus import CreateBus, UpdateBus

from app.models import Route
from app.schemas.route import CreateRoute, UpdateRoute

from app.models import Stop
from app.schemas.stop import CreateStop, UpdateStop

from app.models import RouteStop, Route, Stop
from app.schemas.route_stop import CreateRouteStop, UpdateRouteStop

from app.models import Driver, User, Assignment, BreakdownReport
from app.schemas.driver import CreateDriver, UpdateDriver

from app.models import User, Driver, Announcement
from app.schemas.user import CreateUser, UpdateUser

from app.schemas.user import CreateDriverAccount
from app.schemas.fcm import RegisterFCMToken
from app.schemas.user import CreateDriverAccount, CreateAdminAccount

from app.models import Assignment, Bus, Driver, Route, Schedule
from app.schemas.assignment import CreateAssignment, UpdateAssignment

from app.models import Schedule, Assignment
from app.schemas.schedule import CreateSchedule, UpdateSchedule
from datetime import time
from app.schemas.user import LoginRequest

from app.models import BusLocation, Bus
from app.schemas.bus_location import CreateBusLocation, UpdateBusLocation

from app.models import BreakdownReport, Bus, Driver
from app.schemas.breakdown_report import (
    CreateBreakdownReport,
    UpdateBreakdownReport
)

from app.services.notification_service import (
    send_announcement_notification
)

from app.models import Announcement, User, FCMDeviceToken
from app.schemas.announcement import CreateAnnouncement, UpdateAnnouncement

# Load environment variables
load_dotenv()

# JWT configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "30")
)

if not SECRET_KEY:
    raise RuntimeError("JWT_SECRET_KEY is missing from .env")

security = HTTPBearer(auto_error=False)

# Generate JWT access token
def create_access_token(user_id: int):

    expire = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "exp": expire
    }

    token = jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return token

app = FastAPI(title="NITC Bus Tracking API")

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    # Check whether token is provided
    if credentials is None:
        raise HTTPException(
            status_code=401,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"}
        )

    token = credentials.credentials

    try:
        # Decode and validate JWT
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        # Extract user ID
        user_id = payload.get("sub")

        if user_id is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid token"
            )

        user_id = int(user_id)

    except (JWTError, ValueError, TypeError):
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Find user in database
    current_user = db.query(User).filter(
        User.user_id == user_id
    ).first()

    if current_user is None:
        raise HTTPException(
            status_code=401,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"}
        )

    return current_user

def get_current_admin(
    current_user: User = Depends(get_current_user)
):
    if str(current_user.role).upper() != "ADMIN":
        raise HTTPException(
            status_code=403,
            detail="Administrator access required"
        )

    return current_user


@app.post("/fcm/register")
def register_fcm_token(
    data: RegisterFCMToken,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Register or reactivate an FCM device token
    for the authenticated STUDENT or STAFF user.
    """

    # Only students and staff receive announcements
    user_role = str(current_user.role).upper()

    if user_role not in ["STUDENT", "STAFF"]:
        raise HTTPException(
            status_code=403,
            detail="Only students and staff can register FCM tokens"
        )

    token = data.token.strip()
    device_type = data.device_type.strip().upper()

    if not token:
        raise HTTPException(
            status_code=400,
            detail="FCM token cannot be empty"
        )

    if device_type not in ["ANDROID", "IOS", "WEB"]:
        raise HTTPException(
            status_code=400,
            detail="Unsupported device type"
        )

    # Check whether this token already exists
    existing_token = db.query(FCMDeviceToken).filter(
        FCMDeviceToken.token == token
    ).first()

    if existing_token:
        # Associate the token with the authenticated user
        existing_token.user_id = current_user.user_id
        existing_token.device_type = device_type
        existing_token.is_active = True

        try:
            db.commit()
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail="Could not update FCM token"
            )

        return {
            "message": "FCM token updated successfully",
            "token_id": existing_token.token_id
        }

    # Register a new device token
    new_token = FCMDeviceToken(
        user_id=current_user.user_id,
        token=token,
        device_type=device_type,
        is_active=True
    )

    try:
        db.add(new_token)
        db.commit()
        db.refresh(new_token)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="FCM token registration conflict"
        )

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Could not register FCM token"
        )

    return {
        "message": "FCM token registered successfully",
        "token_id": new_token.token_id
    }


@app.get("/test-auth")
def test_auth(
    current_user: User = Depends(get_current_user)
):
    return {
        "message": "Authentication successful!",
        "user_id": current_user.user_id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role
    }


@app.get("/")
def home():
    return {"message": "NITC Bus Tracking API is running"}


@app.get("/db-check")
def db_check(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))

    return {
        "message": "FastAPI connected to MySQL successfully!"
    }

@app.get("/buses")
def get_buses(db: Session = Depends(get_db)):

    buses = db.query(Bus).all()

    return [
        {
            "bus_id": bus.bus_id,
            "bus_number": bus.bus_number,
            "registration_number": bus.registration_number,
            "capacity": bus.capacity,
            "status": bus.status
        }
        for bus in buses
    ]

@app.post("/buses")
def create_bus(bus_data: CreateBus, db: Session = Depends(get_db)):

    new_bus = Bus(
        bus_number=bus_data.bus_number,
        capacity=bus_data.capacity,
        registration_number=bus_data.registration_number,
        status=bus_data.status
    )

    try:
        db.add(new_bus)
        db.commit()
        db.refresh(new_bus)

        return {
            "message": "Bus added successfully!",
            "bus_id": new_bus.bus_id,
            "bus_number": new_bus.bus_number,
            "registration_number": new_bus.registration_number,
            "capacity": new_bus.capacity,
            "status": new_bus.status
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Bus number already exists."
        )

@app.patch("/buses/{bus_id}")
def update_bus(
    bus_id: int,
    bus_data: UpdateBus,
    db: Session = Depends(get_db)
):
    bus = db.query(Bus).filter(Bus.bus_id == bus_id).first()

    if not bus:
        raise HTTPException(
            status_code=404,
            detail="Bus not found"
        )

    update_data = bus_data.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    for key, value in update_data.items():
        if value is None:
            raise HTTPException(
                status_code=422,
                detail=f"{key} cannot be null"
            )
        setattr(bus, key, value)

    try:
        db.commit()
        db.refresh(bus)

        return {
            "message": "Bus updated successfully!",
            "bus_id": bus.bus_id,
            "bus_number": bus.bus_number,
            "registration_number": bus.registration_number,
            "capacity": bus.capacity,
            "status": bus.status
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Bus number already exists."
        )

@app.delete("/buses/{bus_id}")
def delete_bus(
    bus_id: int,
    db: Session = Depends(get_db)
):
    bus = db.query(Bus).filter(Bus.bus_id == bus_id).first()

    if not bus:
        raise HTTPException(
            status_code=404,
            detail="Bus not found"
        )

    # Check whether other records reference this bus
    if bus.assignments or bus.locations or bus.breakdown_reports:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete bus because related records exist."
        )

    db.delete(bus)
    db.commit()

    return {
        "message": "Bus deleted successfully!",
        "bus_id": bus_id
    }

@app.get("/routes")
def get_routes(db: Session = Depends(get_db)):

    routes = db.query(Route).all()

    return [
        {
            "route_id": route.route_id,
            "route_name": route.route_name,
            "start_location": route.start_location,
            "end_location": route.end_location,
            "is_active": route.is_active
        }
        for route in routes
    ]

@app.post("/routes")
def create_route(
    route_data: CreateRoute,
    db: Session = Depends(get_db)
):

    new_route = Route(
        route_name=route_data.route_name,
        start_location=route_data.start_location,
        end_location=route_data.end_location,
        is_active=route_data.is_active
    )

    db.add(new_route)
    db.commit()
    db.refresh(new_route)

    return {
        "message": "Route created successfully!",
        "route_id": new_route.route_id,
        "route_name": new_route.route_name,
        "start_location": new_route.start_location,
        "end_location": new_route.end_location,
        "is_active": new_route.is_active
    }

@app.patch("/routes/{route_id}")
def update_route(
    route_id: int,
    route_data: UpdateRoute,
    db: Session = Depends(get_db)
):
    route = db.query(Route).filter(
        Route.route_id == route_id
    ).first()

    if not route:
        raise HTTPException(
            status_code=404,
            detail="Route not found"
        )

    update_data = route_data.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    for key, value in update_data.items():
        if value is None:
            raise HTTPException(
                status_code=422,
                detail=f"{key} cannot be null"
            )

        setattr(route, key, value)

    db.commit()
    db.refresh(route)

    return {
        "message": "Route updated successfully!",
        "route_id": route.route_id,
        "route_name": route.route_name,
        "start_location": route.start_location,
        "end_location": route.end_location,
        "is_active": route.is_active
    }

@app.delete("/routes/{route_id}")
def delete_route(
    route_id: int,
    db: Session = Depends(get_db)
):
    route = db.query(Route).filter(
        Route.route_id == route_id
    ).first()

    if not route:
        raise HTTPException(
            status_code=404,
            detail="Route not found"
        )

    if route.route_stops or route.assignments:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete route because related records exist."
        )

    db.delete(route)
    db.commit()

    return {
        "message": "Route deleted successfully!",
        "route_id": route_id
    }


@app.get("/stops")
def get_stops(db: Session = Depends(get_db)):

    stops = db.query(Stop).all()

    return [
        {
            "stop_id": stop.stop_id,
            "stop_name": stop.stop_name,
            "latitude": float(stop.latitude) if stop.latitude is not None else None,
            "longitude": float(stop.longitude) if stop.longitude is not None else None
        }
        for stop in stops
    ]

@app.post("/stops")
def create_stop(
    stop_data: CreateStop,
    db: Session = Depends(get_db)
):

    new_stop = Stop(
        stop_name=stop_data.stop_name,
        latitude=stop_data.latitude,
        longitude=stop_data.longitude
    )

    db.add(new_stop)
    db.commit()
    db.refresh(new_stop)

    return {
        "message": "Stop added successfully!",
        "stop_id": new_stop.stop_id,
        "stop_name": new_stop.stop_name,
        "latitude": float(new_stop.latitude) if new_stop.latitude is not None else None,
        "longitude": float(new_stop.longitude) if new_stop.longitude is not None else None
    }

@app.patch("/stops/{stop_id}")
def update_stop(
    stop_id: int,
    stop_data: UpdateStop,
    db: Session = Depends(get_db)
):

    stop = db.query(Stop).filter(Stop.stop_id == stop_id).first()

    if not stop:
        raise HTTPException(
            status_code=404,
            detail="Stop not found"
        )

    update_data = stop_data.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    for key, value in update_data.items():
        if value is None and key == "stop_name":
            raise HTTPException(
                status_code=422,
                detail="Stop name cannot be null"
            )

        setattr(stop, key, value)

    db.commit()
    db.refresh(stop)

    return {
        "message": "Stop updated successfully!",
        "stop_id": stop.stop_id,
        "stop_name": stop.stop_name,
        "latitude": float(stop.latitude) if stop.latitude is not None else None,
        "longitude": float(stop.longitude) if stop.longitude is not None else None
    }

@app.delete("/stops/{stop_id}")
def delete_stop(
    stop_id: int,
    db: Session = Depends(get_db)
):

    stop = db.query(Stop).filter(Stop.stop_id == stop_id).first()

    if not stop:
        raise HTTPException(
            status_code=404,
            detail="Stop not found"
        )

    if stop.route_stops:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete stop because it is associated with existing routes."
        )

    db.delete(stop)
    db.commit()

    return {
        "message": "Stop deleted successfully!",
        "stop_id": stop_id
    }

# ==========================================
# ROUTE STOPS CRUD OPERATIONS
# ==========================================


# 1. GET ALL ROUTE STOPS
@app.get("/route-stops")
def get_all_route_stops(db: Session = Depends(get_db)):

    records = db.query(RouteStop).order_by(
        RouteStop.route_id,
        RouteStop.stop_order
    ).all()

    return [
        {
            "route_id": record.route_id,
            "stop_id": record.stop_id,
            "stop_order": record.stop_order,
            "departure_offset_minutes": record.departure_offset_minutes
        }
        for record in records
    ]


# 2. POST - ADD STOP TO A ROUTE
@app.post("/route-stops")
def create_route_stop(
    route_stop_data: CreateRouteStop,
    db: Session = Depends(get_db)
):

    route = db.query(Route).filter(
        Route.route_id == route_stop_data.route_id
    ).first()

    if not route:
        raise HTTPException(
            status_code=404,
            detail="Route not found"
        )

    stop = db.query(Stop).filter(
        Stop.stop_id == route_stop_data.stop_id
    ).first()

    if not stop:
        raise HTTPException(
            status_code=404,
            detail="Stop not found"
        )

    existing = db.query(RouteStop).filter(
        RouteStop.route_id == route_stop_data.route_id,
        RouteStop.stop_id == route_stop_data.stop_id
    ).first()

    if existing:
        raise HTTPException(
            status_code=409,
            detail="This stop is already assigned to this route"
        )

    duplicate_order = db.query(RouteStop).filter(
        RouteStop.route_id == route_stop_data.route_id,
        RouteStop.stop_order == route_stop_data.stop_order
    ).first()

    if duplicate_order:
        raise HTTPException(
            status_code=409,
            detail="This stop order is already used in this route"
        )

    new_record = RouteStop(
        route_id=route_stop_data.route_id,
        stop_id=route_stop_data.stop_id,
        stop_order=route_stop_data.stop_order,
        departure_offset_minutes=route_stop_data.departure_offset_minutes
    )

    db.add(new_record)
    db.commit()
    db.refresh(new_record)

    return {
        "message": "Stop successfully added to route",
        "route_id": new_record.route_id,
        "stop_id": new_record.stop_id,
        "stop_order": new_record.stop_order,
        "departure_offset_minutes": new_record.departure_offset_minutes
    }


# 3. GET STOPS OF A PARTICULAR ROUTE
@app.get("/routes/{route_id}/stops")
def get_route_stops(
    route_id: int,
    db: Session = Depends(get_db)
):

    route = db.query(Route).filter(
        Route.route_id == route_id
    ).first()

    if not route:
        raise HTTPException(
            status_code=404,
            detail="Route not found"
        )

    records = db.query(RouteStop, Stop).join(
        Stop,
        RouteStop.stop_id == Stop.stop_id
    ).filter(
        RouteStop.route_id == route_id
    ).order_by(
        RouteStop.stop_order
    ).all()

    return [
        {
            "route_id": record.route_id,
            "stop_id": stop.stop_id,
            "stop_name": stop.stop_name,
            "stop_order": record.stop_order,
            "departure_offset_minutes": record.departure_offset_minutes,
            "latitude": stop.latitude,
            "longitude": stop.longitude
        }
        for record, stop in records
    ]


# 4. PATCH - UPDATE STOP ORDER / DEPARTURE OFFSET
@app.patch("/route-stops/{route_id}/{stop_id}")
def update_route_stop(
    route_id: int,
    stop_id: int,
    update_data: UpdateRouteStop,
    db: Session = Depends(get_db)
):

    record = db.query(RouteStop).filter(
        RouteStop.route_id == route_id,
        RouteStop.stop_id == stop_id
    ).first()

    if not record:
        raise HTTPException(
            status_code=404,
            detail="Route-stop record not found"
        )

    update_values = update_data.model_dump(exclude_unset=True)

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    # Validate explicitly supplied values
    if "stop_order" in update_values:
        if update_values["stop_order"] is None:
            raise HTTPException(
                status_code=400,
                detail="stop_order cannot be null"
            )

        duplicate_order = db.query(RouteStop).filter(
            RouteStop.route_id == route_id,
            RouteStop.stop_order == update_values["stop_order"],
            RouteStop.stop_id != stop_id
        ).first()

        if duplicate_order:
            raise HTTPException(
                status_code=409,
                detail="This stop order is already used in this route"
            )

    if "departure_offset_minutes" in update_values:
        if update_values["departure_offset_minutes"] is None:
            raise HTTPException(
                status_code=400,
                detail="departure_offset_minutes cannot be null"
            )

    # Apply only the supplied fields
    if "stop_order" in update_values:
        record.stop_order = update_values["stop_order"]

    if "departure_offset_minutes" in update_values:
        record.departure_offset_minutes = update_values[
            "departure_offset_minutes"
        ]

    db.commit()
    db.refresh(record)

    return {
        "message": "Route stop updated successfully",
        "route_id": record.route_id,
        "stop_id": record.stop_id,
        "stop_order": record.stop_order,
        "departure_offset_minutes": record.departure_offset_minutes
    }


# 5. DELETE - REMOVE STOP FROM ROUTE
@app.delete("/route-stops/{route_id}/{stop_id}")
def delete_route_stop(
    route_id: int,
    stop_id: int,
    db: Session = Depends(get_db)
):

    record = db.query(RouteStop).filter(
        RouteStop.route_id == route_id,
        RouteStop.stop_id == stop_id
    ).first()

    if not record:
        raise HTTPException(
            status_code=404,
            detail="Route-stop record not found"
        )

    db.delete(record)
    db.commit()

    return {
        "message": "Stop successfully removed from route"
    }


# ==========================================
# DRIVERS CRUD OPERATIONS
# ==========================================


# 1. GET ALL DRIVERS
@app.get("/drivers")
def get_all_drivers(db: Session = Depends(get_db)):

    drivers = db.query(Driver).all()

    return [
        {
            "driver_id": driver.driver_id,
            "user_id": driver.user_id,
            "license_number": driver.license_number
        }
        for driver in drivers
    ]


# 2. GET DRIVER BY ID
@app.get("/drivers/{driver_id}")
def get_driver(
    driver_id: int,
    db: Session = Depends(get_db)
):

    driver = db.query(Driver).filter(
        Driver.driver_id == driver_id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    return {
        "driver_id": driver.driver_id,
        "user_id": driver.user_id,
        "license_number": driver.license_number
    }


# 3. POST - CREATE DRIVER
@app.post("/drivers", status_code=201)
def create_driver(
    driver_data: CreateDriver,
    db: Session = Depends(get_db)
):

    # Check whether user exists
    user = db.query(User).filter(
        User.user_id == driver_data.user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    # Check whether user already has a driver profile
    existing_user = db.query(Driver).filter(
        Driver.user_id == driver_data.user_id
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="This user already has a driver profile"
        )

    # Check duplicate license number
    existing_license = db.query(Driver).filter(
        Driver.license_number == driver_data.license_number
    ).first()

    if existing_license:
        raise HTTPException(
            status_code=409,
            detail="License number already exists"
        )

    new_driver = Driver(
        user_id=driver_data.user_id,
        license_number=driver_data.license_number
    )

    try:
        db.add(new_driver)
        db.commit()
        db.refresh(new_driver)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Duplicate or invalid driver information"
        )

    return {
        "message": "Driver created successfully",
        "driver_id": new_driver.driver_id,
        "user_id": new_driver.user_id,
        "license_number": new_driver.license_number
    }


# 4. PATCH - UPDATE DRIVER
@app.patch("/drivers/{driver_id}")
def update_driver(
    driver_id: int,
    update_data: UpdateDriver,
    db: Session = Depends(get_db)
):

    driver = db.query(Driver).filter(
        Driver.driver_id == driver_id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    update_values = update_data.model_dump(
        exclude_unset=True
    )

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    if update_values["license_number"] is None:
        raise HTTPException(
            status_code=400,
            detail="License number cannot be null"
        )

    # Check duplicate license number
    existing_license = db.query(Driver).filter(
        Driver.license_number == update_values["license_number"],
        Driver.driver_id != driver_id
    ).first()

    if existing_license:
        raise HTTPException(
            status_code=409,
            detail="License number already exists"
        )

    driver.license_number = update_values["license_number"]

    try:
        db.commit()
        db.refresh(driver)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="License number already exists"
        )

    return {
        "message": "Driver updated successfully",
        "driver_id": driver.driver_id,
        "user_id": driver.user_id,
        "license_number": driver.license_number
    }


# 5. DELETE DRIVER
@app.delete("/drivers/{driver_id}")
def delete_driver(
    driver_id: int,
    db: Session = Depends(get_db)
):

    driver = db.query(Driver).filter(
        Driver.driver_id == driver_id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    # Check existing assignments
    existing_assignment = db.query(Assignment).filter(
        Assignment.driver_id == driver_id
    ).first()

    if existing_assignment:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete driver because assignments exist"
        )

    # Check existing breakdown reports
    existing_report = db.query(BreakdownReport).filter(
        BreakdownReport.driver_id == driver_id
    ).first()

    if existing_report:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete driver because breakdown reports exist"
        )

    db.delete(driver)
    db.commit()

    return {
        "message": "Driver deleted successfully"
    }
#==================================================
#admin wil create driver account with this endpoint
#==================================================


@app.post("/admin/create-driver", status_code=201)
def create_driver_account(
    driver_data: CreateDriverAccount,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    email = driver_data.email.strip().lower()
    license_number = driver_data.license_number.strip()

    if not email.endswith("@nitc.ac.in"):
        raise HTTPException(
            status_code=400,
            detail="Only NITC email addresses are allowed"
        )

    existing_user = db.query(User).filter(
        User.email == email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="Email already registered"
        )

    existing_driver = db.query(Driver).filter(
        Driver.license_number == license_number
    ).first()

    if existing_driver:
        raise HTTPException(
            status_code=409,
            detail="License number already registered"
        )

    try:
        new_user = User(
            name=driver_data.name.strip(),
            email=email,
            password_hash=hash_password(driver_data.password),
            role="DRIVER"
        )

        db.add(new_user)
        db.flush()

        new_driver = Driver(
            user_id=new_user.user_id,
            license_number=license_number
        )

        db.add(new_driver)
        db.commit()

        db.refresh(new_user)
        db.refresh(new_driver)

        return {
            "message": "Driver account created successfully",
            "user_id": new_user.user_id,
            "driver_id": new_driver.driver_id,
            "name": new_user.name,
            "email": new_user.email,
            "role": new_user.role,
            "license_number": new_driver.license_number
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Email or license number already exists"
        )

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Could not create driver account"
        )


@app.post("/admin/create-admin", status_code=201)
def create_admin_account(
    admin_data: CreateAdminAccount,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    email = admin_data.email.strip().lower()

    if not email.endswith("@nitc.ac.in"):
        raise HTTPException(
            status_code=400,
            detail="Only NITC email addresses are allowed"
        )

    existing_user = db.query(User).filter(
        User.email == email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="Email already registered"
        )

    try:
        new_admin = User(
            name=admin_data.name.strip(),
            email=email,
            password_hash=hash_password(admin_data.password),
            role="ADMIN"
        )

        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)

        return {
            "message": "Administrator account created successfully",
            "user_id": new_admin.user_id,
            "name": new_admin.name,
            "email": new_admin.email,
            "role": new_admin.role
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Email already registered"
        )

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Could not create administrator account"
        )


import hashlib
import secrets
import base64


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)

    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        600000
    )

    salt_encoded = base64.urlsafe_b64encode(
        salt
    ).decode("utf-8")

    hash_encoded = base64.urlsafe_b64encode(
        password_hash
    ).decode("utf-8")

    return f"pbkdf2_sha256$600000${salt_encoded}${hash_encoded}"

def verify_password(plain_password: str, stored_hash: str) -> bool:

    try:
        algorithm, iterations, salt_encoded, hash_encoded = stored_hash.split("$")

        if algorithm != "pbkdf2_sha256":
            return False

        salt = base64.urlsafe_b64decode(salt_encoded.encode("utf-8"))

        expected_hash = base64.urlsafe_b64decode(hash_encoded.encode("utf-8"))

        actual_hash = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt,
            int(iterations)
        )

        return hmac.compare_digest(actual_hash, expected_hash)

    except (ValueError, TypeError):
        return False


# ==========================================
# USERS CRUD OPERATIONS
# ==========================================

# ==========================================
# USER LOGIN
# ==========================================

@app.post("/login")
def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):

    email = login_data.email.strip().lower()

    # Allow only NITC email addresses
    if not email.endswith("@nitc.ac.in"):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    # Find user by email
    user = db.query(User).filter(
        User.email == email
    ).first()

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    # Verify password
    if not verify_password(
        login_data.password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    # Generate JWT token
    access_token = create_access_token(user.user_id)

    return {
        "message": "Login successful",
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": {
            "user_id": user.user_id,
            "name": user.name,
            "email": user.email,
            "role": user.role
        }
    }


# ==================================================
# ADMIN - USER MANAGEMENT
# ==================================================

# 1. GET ALL USERS
@app.get("/users")
def get_all_users(
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    users = db.query(User).order_by(User.user_id.asc()).all()

    return [
        {
            "user_id": user.user_id,
            "name": user.name,
            "email": user.email,
            "role": user.role
        }
        for user in users
    ]


# 2. GET USER BY ID
@app.get("/users/{user_id}")
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(
        User.user_id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {
        "user_id": user.user_id,
        "name": user.name,
        "email": user.email,
        "role": user.role
    }


# 3. PUBLIC STUDENT REGISTRATION
# Keep this endpoint public. New public registrations
# are always assigned the STUDENT role.
@app.post("/users", status_code=201)
def create_user(
    user_data: CreateUser,
    db: Session = Depends(get_db)
):
    email = user_data.email.strip().lower()

    if not email.endswith("@nitc.ac.in"):
        raise HTTPException(
            status_code=400,
            detail="Only NITC email addresses (@nitc.ac.in) are allowed"
        )

    existing_user = db.query(User).filter(
        User.email == email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="Email already registered"
        )

    new_user = User(
        name=user_data.name.strip(),
        email=email,
        password_hash=hash_password(user_data.password),
        role="STUDENT"
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Duplicate or invalid user information"
        )

    return {
        "message": "User created successfully",
        "user_id": new_user.user_id,
        "name": new_user.name,
        "email": new_user.email,
        "role": new_user.role
    }


# 4. UPDATE USER
@app.patch("/users/{user_id}")
def update_user(
    user_id: int,
    update_data: UpdateUser,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(
        User.user_id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    update_values = update_data.model_dump(
        exclude_unset=True
    )

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    if any(value is None for value in update_values.values()):
        raise HTTPException(
            status_code=400,
            detail="Fields cannot be null"
        )

    # Normalize and validate email.
    if "email" in update_values:
        email = update_values["email"].strip().lower()

        if not email.endswith("@nitc.ac.in"):
            raise HTTPException(
                status_code=400,
                detail="Only NITC email addresses are allowed"
            )

        existing_email = db.query(User).filter(
            User.email == email,
            User.user_id != user_id
        ).first()

        if existing_email:
            raise HTTPException(
                status_code=409,
                detail="Email already registered"
            )

        update_values["email"] = email

    # Normalize name.
    if "name" in update_values:
        update_values["name"] = update_values["name"].strip()

        if not update_values["name"]:
            raise HTTPException(
                status_code=400,
                detail="Name cannot be empty"
            )

    # Validate role changes.
    if "role" in update_values:
        new_role = update_values["role"].strip().upper()

        allowed_roles = {
            "STUDENT",
            "STAFF",
            "DRIVER",
            "ADMIN"
        }

        if new_role not in allowed_roles:
            raise HTTPException(
                status_code=400,
                detail="Invalid user role"
            )

        # Do not allow an administrator to remove their own
        # administrator privileges through this endpoint.
        if user.user_id == current_admin.user_id:
            raise HTTPException(
                status_code=400,
                detail="You cannot change your own role"
            )

        # Driver accounts require a separate driver profile.
        if new_role == "DRIVER" and user.role != "DRIVER":
            raise HTTPException(
                status_code=400,
                detail="Create driver accounts through Driver Management"
            )

        # Do not change a driver's role while their driver
        # profile exists.
        if new_role != "DRIVER" and user.role == "DRIVER":
            existing_driver = db.query(Driver).filter(
                Driver.user_id == user_id
            ).first()

            if existing_driver:
                raise HTTPException(
                    status_code=409,
                    detail="Remove the driver profile through Driver Management before changing this role"
                )

        update_values["role"] = new_role

    # Hash a new password before saving.
    if "password" in update_values:
        update_values["password_hash"] = hash_password(
            update_values.pop("password")
        )

    for key, value in update_values.items():
        setattr(user, key, value)

    try:
        db.commit()
        db.refresh(user)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="User could not be updated due to a database constraint"
        )

    return {
        "message": "User updated successfully",
        "user_id": user.user_id,
        "name": user.name,
        "email": user.email,
        "role": user.role
    }


# 5. DELETE USER
@app.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(
        User.user_id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    # Prevent an administrator from deleting their own account.
    if user.user_id == current_admin.user_id:
        raise HTTPException(
            status_code=400,
            detail="You cannot delete your own account"
        )

    # Check whether the user has a driver profile.
    existing_driver = db.query(Driver).filter(
        Driver.user_id == user_id
    ).first()

    if existing_driver:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete user because a driver profile exists. Remove it through Driver Management first."
        )

    # Check whether the user created announcements.
    existing_announcement = db.query(Announcement).filter(
        Announcement.created_by == user_id
    ).first()

    if existing_announcement:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete user because announcements created by this user exist"
        )

    try:
        db.delete(user)
        db.commit()

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Cannot delete user because related records exist"
        )

    return {
        "message": "User deleted successfully",
        "user_id": user_id
    }

@app.get("/assignments")
def get_all_assignments(db: Session = Depends(get_db)):
    return db.query(Assignment).all()

@app.get("/assignments/{assignment_id}")
def get_assignment(assignment_id: int, db: Session = Depends(get_db)):
    assignment = db.query(Assignment).filter(
        Assignment.assignment_id == assignment_id
    ).first()

    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")

    return assignment

@app.post("/assignments", status_code=201)
def create_assignment(
    data: CreateAssignment,
    db: Session = Depends(get_db)
):
    bus = db.query(Bus).filter(Bus.bus_id == data.bus_id).first()
    driver = db.query(Driver).filter(
        Driver.driver_id == data.driver_id
    ).first()
    route = db.query(Route).filter(
        Route.route_id == data.route_id
    ).first()

    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found")

    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    new_assignment = Assignment(
        bus_id=data.bus_id,
        driver_id=data.driver_id,
        route_id=data.route_id,
        assignment_date=data.assignment_date
    )

    try:
        db.add(new_assignment)
        db.commit()
        db.refresh(new_assignment)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Assignment could not be created due to a database constraint"
        )

    return {
        "message": "Assignment created successfully",
        "assignment_id": new_assignment.assignment_id
    }


@app.patch("/assignments/{assignment_id}")
def update_assignment(
    assignment_id: int,
    data: UpdateAssignment,
    db: Session = Depends(get_db)
):
    assignment = db.query(Assignment).filter(
        Assignment.assignment_id == assignment_id
    ).first()

    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")

    update_values = data.model_dump(exclude_unset=True)

    if not update_values:
        raise HTTPException(status_code=400, detail="No fields provided")

    if any(value is None for value in update_values.values()):
        raise HTTPException(status_code=400, detail="Fields cannot be null")

    if "bus_id" in update_values:
        if not db.query(Bus).filter(
            Bus.bus_id == update_values["bus_id"]
        ).first():
            raise HTTPException(status_code=404, detail="Bus not found")

    if "driver_id" in update_values:
        if not db.query(Driver).filter(
            Driver.driver_id == update_values["driver_id"]
        ).first():
            raise HTTPException(status_code=404, detail="Driver not found")

    if "route_id" in update_values:
        if not db.query(Route).filter(
            Route.route_id == update_values["route_id"]
        ).first():
            raise HTTPException(status_code=404, detail="Route not found")

    for key, value in update_values.items():
        setattr(assignment, key, value)

    try:
        db.commit()
        db.refresh(assignment)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Assignment could not be updated due to a database constraint"
        )

    return {
        "message": "Assignment updated successfully",
        "assignment_id": assignment.assignment_id
    }

@app.delete("/assignments/{assignment_id}")
def delete_assignment(
    assignment_id: int,
    db: Session = Depends(get_db)
):
    assignment = db.query(Assignment).filter(
        Assignment.assignment_id == assignment_id
    ).first()

    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")

    existing_schedule = db.query(Schedule).filter(
        Schedule.assignment_id == assignment_id
    ).first()

    if existing_schedule:
        raise HTTPException(
            status_code=409,
            detail="Cannot delete assignment because schedules exist"
        )

    db.delete(assignment)
    db.commit()

    return {"message": "Assignment deleted successfully"}

@app.get("/schedules")
def get_all_schedules(db: Session = Depends(get_db)):
    return db.query(Schedule).all()

@app.get("/schedules/{schedule_id}")
def get_schedule(schedule_id: int, db: Session = Depends(get_db)):
    schedule = db.query(Schedule).filter(
        Schedule.schedule_id == schedule_id
    ).first()

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Schedule not found"
        )

    return schedule

@app.post("/schedules", status_code=201)
def create_schedule(
    data: CreateSchedule,
    db: Session = Depends(get_db)
):
    assignment = db.query(Assignment).filter(
        Assignment.assignment_id == data.assignment_id
    ).first()

    if not assignment:
        raise HTTPException(
            status_code=404,
            detail="Assignment not found"
        )

    new_schedule = Schedule(
        assignment_id=data.assignment_id,
        departure_time=data.departure_time,
        arrival_time=data.arrival_time,
        schedule_day=data.schedule_day.strip().upper()
    )

    try:
        db.add(new_schedule)
        db.commit()
        db.refresh(new_schedule)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Schedule could not be created due to a database constraint"
        )

    return {
        "message": "Schedule created successfully",
        "schedule_id": new_schedule.schedule_id
    }

@app.patch("/schedules/{schedule_id}")
def update_schedule(
    schedule_id: int,
    data: UpdateSchedule,
    db: Session = Depends(get_db)
):
    schedule = db.query(Schedule).filter(
        Schedule.schedule_id == schedule_id
    ).first()

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Schedule not found"
        )

    update_values = data.model_dump(exclude_unset=True)

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    if any(value is None for value in update_values.values()):
        raise HTTPException(
            status_code=400,
            detail="Fields cannot be null"
        )

    if "assignment_id" in update_values:
        assignment = db.query(Assignment).filter(
            Assignment.assignment_id == update_values["assignment_id"]
        ).first()

        if not assignment:
            raise HTTPException(
                status_code=404,
                detail="Assignment not found"
            )

    if "schedule_day" in update_values:
        update_values["schedule_day"] = (
            update_values["schedule_day"].strip().upper()
        )

    for key, value in update_values.items():
        setattr(schedule, key, value)

    try:
        db.commit()
        db.refresh(schedule)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Schedule could not be updated due to a database constraint"
        )

    return {
        "message": "Schedule updated successfully",
        "schedule_id": schedule.schedule_id
    }

@app.delete("/schedules/{schedule_id}")
def delete_schedule(
    schedule_id: int,
    db: Session = Depends(get_db)
):
    schedule = db.query(Schedule).filter(
        Schedule.schedule_id == schedule_id
    ).first()

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Schedule not found"
        )

    db.delete(schedule)
    db.commit()

    return {"message": "Schedule deleted successfully"}


@app.get("/bus-locations/latest")
def get_latest_bus_locations(db: Session = Depends(get_db)):

    latest_locations = (
        db.query(
            BusLocation,
            func.row_number().over(
                partition_by=BusLocation.bus_id,
                order_by=(
                    BusLocation.recorded_at.desc(),
                    BusLocation.location_id.desc()
                )
            ).label("row_num")
        )
        .subquery()
    )

    locations = (
        db.query(BusLocation)
        .join(
            latest_locations,
            BusLocation.location_id == latest_locations.c.location_id
        )
        .filter(latest_locations.c.row_num == 1)
        .all()
    )

    return locations


@app.get("/bus-locations/{location_id}")
def get_bus_location(location_id: int, db: Session = Depends(get_db)):
    location = db.query(BusLocation).filter(
        BusLocation.location_id == location_id
    ).first()

    if not location:
        raise HTTPException(
            status_code=404,
            detail="Bus location not found"
        )

    return location

@app.post("/bus-locations", status_code=201)
def create_bus_location(
    data: CreateBusLocation,
    db: Session = Depends(get_db)
):
    bus = db.query(Bus).filter(
        Bus.bus_id == data.bus_id
    ).first()

    if not bus:
        raise HTTPException(
            status_code=404,
            detail="Bus not found"
        )

    new_location = BusLocation(
        bus_id=data.bus_id,
        latitude=data.latitude,
        longitude=data.longitude,
        recorded_at=data.recorded_at
    )

    try:
        db.add(new_location)
        db.commit()
        db.refresh(new_location)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Bus location could not be created due to a database constraint"
        )

    return {
        "message": "Bus location created successfully",
        "location_id": new_location.location_id
    }

@app.patch("/bus-locations/{location_id}")
def update_bus_location(
    location_id: int,
    data: UpdateBusLocation,
    db: Session = Depends(get_db)
):
    location = db.query(BusLocation).filter(
        BusLocation.location_id == location_id
    ).first()

    if not location:
        raise HTTPException(
            status_code=404,
            detail="Bus location not found"
        )

    update_values = data.model_dump(exclude_unset=True)

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    if any(value is None for value in update_values.values()):
        raise HTTPException(
            status_code=400,
            detail="Fields cannot be null"
        )

    if "bus_id" in update_values:
        bus = db.query(Bus).filter(
            Bus.bus_id == update_values["bus_id"]
        ).first()

        if not bus:
            raise HTTPException(
                status_code=404,
                detail="Bus not found"
            )

    for key, value in update_values.items():
        setattr(location, key, value)

    try:
        db.commit()
        db.refresh(location)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Bus location could not be updated due to a database constraint"
        )

    return {
        "message": "Bus location updated successfully",
        "location_id": location.location_id
    }

@app.delete("/bus-locations/{location_id}")
def delete_bus_location(
    location_id: int,
    db: Session = Depends(get_db)
):
    location = db.query(BusLocation).filter(
        BusLocation.location_id == location_id
    ).first()

    if not location:
        raise HTTPException(
            status_code=404,
            detail="Bus location not found"
        )

    db.delete(location)
    db.commit()

    return {"message": "Bus location deleted successfully"}


@app.get("/breakdown-reports")
def get_all_breakdown_reports(db: Session = Depends(get_db)):
    return db.query(BreakdownReport).all()


@app.get("/breakdown-reports/{report_id}")
def get_breakdown_report(
    report_id: int,
    db: Session = Depends(get_db)
):
    report = db.query(BreakdownReport).filter(
        BreakdownReport.report_id == report_id
    ).first()

    if not report:
        raise HTTPException(
            status_code=404,
            detail="Breakdown report not found"
        )

    return report

@app.post("/breakdown-reports", status_code=201)
def create_breakdown_report(
    data: CreateBreakdownReport,
    db: Session = Depends(get_db)
):
    bus = db.query(Bus).filter(
        Bus.bus_id == data.bus_id
    ).first()

    driver = db.query(Driver).filter(
        Driver.driver_id == data.driver_id
    ).first()

    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found")

    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

    new_report = BreakdownReport(
        bus_id=data.bus_id,
        driver_id=data.driver_id,
        description=data.description.strip(),
        status=data.status
    )

    try:
        db.add(new_report)
        db.commit()
        db.refresh(new_report)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Database constraint error while creating report"
        )

    return {
        "message": "Breakdown report created successfully",
        "report_id": new_report.report_id,
        "status": new_report.status
    }

@app.patch("/breakdown-reports/{report_id}")
def update_breakdown_report(
    report_id: int,
    data: UpdateBreakdownReport,
    db: Session = Depends(get_db)
):
    report = db.query(BreakdownReport).filter(
        BreakdownReport.report_id == report_id
    ).first()

    if not report:
        raise HTTPException(
            status_code=404,
            detail="Breakdown report not found"
        )

    update_values = data.model_dump(exclude_unset=True)

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    if any(value is None for value in update_values.values()):
        raise HTTPException(
            status_code=400,
            detail="Fields cannot be null"
        )

    if "bus_id" in update_values:
        bus = db.query(Bus).filter(
            Bus.bus_id == update_values["bus_id"]
        ).first()

        if not bus:
            raise HTTPException(
                status_code=404,
                detail="Bus not found"
            )

    if "driver_id" in update_values:
        driver = db.query(Driver).filter(
            Driver.driver_id == update_values["driver_id"]
        ).first()

        if not driver:
            raise HTTPException(
                status_code=404,
                detail="Driver not found"
            )

    if "description" in update_values:
        update_values["description"] = (
            update_values["description"].strip()
        )

    if "status" in update_values:
        update_values["status"] = (
            update_values["status"].strip().upper()
        )

    for key, value in update_values.items():
        setattr(report, key, value)

    try:
        db.commit()
        db.refresh(report)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Breakdown report could not be updated due to a database constraint"
        )

    return {
        "message": "Breakdown report updated successfully",
        "report_id": report.report_id
    }

@app.delete("/breakdown-reports/{report_id}")
def delete_breakdown_report(
    report_id: int,
    db: Session = Depends(get_db)
):
    report = db.query(BreakdownReport).filter(
        BreakdownReport.report_id == report_id
    ).first()

    if not report:
        raise HTTPException(
            status_code=404,
            detail="Breakdown report not found"
        )

    db.delete(report)
    db.commit()

    return {"message": "Breakdown report deleted successfully"}


@app.get("/announcements")
def get_all_announcements(db: Session = Depends(get_db)):
    return db.query(Announcement).order_by(
        Announcement.created_at.desc()
    ).all()

@app.get("/announcements/{announcement_id}")
def get_announcement(
    announcement_id: int,
    db: Session = Depends(get_db)
):
    announcement = db.query(Announcement).filter(
        Announcement.announcement_id == announcement_id
    ).first()

    if not announcement:
        raise HTTPException(
            status_code=404,
            detail="Announcement not found"
        )

    return announcement


@app.post("/announcements", status_code=201)
def create_announcement(
    data: CreateAnnouncement,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.user_id == data.created_by
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    new_announcement = Announcement(
        title=data.title.strip(),
        message=data.message.strip(),
        created_by=data.created_by
    )

    try:
        db.add(new_announcement)
        db.commit()
        db.refresh(new_announcement)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Announcement could not be created due to a database constraint"
        )

    # Send push notifications to STUDENT and STAFF devices
    notification_result = None

    try:
        notification_result = send_announcement_notification(
            db=db,
            announcement_id=new_announcement.announcement_id,
            title=new_announcement.title,
            message=new_announcement.message
        )

    except Exception:
        logging.exception(
            "Announcement was created, but push notification processing failed."
        )

    return {
        "message": "Announcement created successfully",
        "announcement_id": new_announcement.announcement_id,
        "notification": notification_result
    }

@app.patch("/announcements/{announcement_id}")
def update_announcement(
    announcement_id: int,
    data: UpdateAnnouncement,
    db: Session = Depends(get_db)
):
    announcement = db.query(Announcement).filter(
        Announcement.announcement_id == announcement_id
    ).first()

    if not announcement:
        raise HTTPException(
            status_code=404,
            detail="Announcement not found"
        )

    update_values = data.model_dump(exclude_unset=True)

    if not update_values:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update"
        )

    if any(value is None for value in update_values.values()):
        raise HTTPException(
            status_code=400,
            detail="Fields cannot be null"
        )

    for key, value in update_values.items():
        setattr(announcement, key, value.strip())

    try:
        db.commit()
        db.refresh(announcement)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Announcement could not be updated"
        )

    return {
        "message": "Announcement updated successfully",
        "announcement_id": announcement.announcement_id
    }

@app.delete("/announcements/{announcement_id}")
def delete_announcement(
    announcement_id: int,
    db: Session = Depends(get_db)
):
    announcement = db.query(Announcement).filter(
        Announcement.announcement_id == announcement_id
    ).first()

    if not announcement:
        raise HTTPException(
            status_code=404,
            detail="Announcement not found"
        )

    db.delete(announcement)
    db.commit()

    return {"message": "Announcement deleted successfully"}
