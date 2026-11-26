
from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    Enum,
    DECIMAL,
    Date,
    Time,
    DateTime,
    Text,
    Boolean,
    func,
    text
)
from sqlalchemy.orm import relationship

from app.database.connection import Base


# ==========================================
# 1. USERS
# ==========================================
class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)

    role = Column(
        Enum("STUDENT", "STAFF", "DRIVER", "ADMIN"),
        nullable=False
    )

    driver = relationship("Driver", back_populates="user", uselist=False)
    announcements = relationship("Announcement", back_populates="creator")
    device_tokens = relationship(
        "FCMDeviceToken",
        back_populates="user",
        cascade="all, delete-orphan"
    )


# ==========================================
# 2. DRIVERS
# ==========================================
class Driver(Base):
    __tablename__ = "drivers"

    driver_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(
        Integer,
        ForeignKey("users.user_id"),
        nullable=False,
        unique=True
    )
    license_number = Column(String(50), nullable=False, unique=True)

    user = relationship("User", back_populates="driver")
    assignments = relationship("Assignment", back_populates="driver")
    breakdown_reports = relationship(
        "BreakdownReport", back_populates="driver"
    )


# ==========================================
# 3. BUSES
# ==========================================
class Bus(Base):
    __tablename__ = "buses"

    bus_id = Column(Integer, primary_key=True, autoincrement=True)
    bus_number = Column(String(30), nullable=False, unique=True)
    registration_number = Column(String(30), nullable=True)

    capacity = Column(Integer, nullable=False)
    status = Column(
        Enum("ACTIVE", "INACTIVE", "MAINTENANCE"),
        nullable=False,
        default="ACTIVE",
        server_default=text("'ACTIVE'")
    )

    assignments = relationship("Assignment", back_populates="bus")
    locations = relationship("BusLocation", back_populates="bus")
    breakdown_reports = relationship(
        "BreakdownReport", back_populates="bus"
    )


# ==========================================
# 4. ROUTES
# ==========================================
class Route(Base):
    __tablename__ = "routes"

    route_id = Column(Integer, primary_key=True, autoincrement=True)
    route_name = Column(String(100), nullable=False)
    start_location = Column(String(150), nullable=False)
    end_location = Column(String(150), nullable=False)
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("1")
    )

    assignments = relationship("Assignment", back_populates="route")
    route_stops = relationship("RouteStop", back_populates="route")


# ==========================================
# 5. STOPS
# ==========================================
class Stop(Base):
    __tablename__ = "stops"

    stop_id = Column(Integer, primary_key=True, autoincrement=True)
    stop_name = Column(String(100), nullable=False)
    latitude = Column(DECIMAL(10, 7), nullable=True)
    longitude = Column(DECIMAL(10, 7), nullable=True)

    route_stops = relationship("RouteStop", back_populates="stop")


# ==========================================
# 6. ROUTE STOPS
# ==========================================

# ==========================================
# 6. ROUTE STOPS
# ==========================================
class RouteStop(Base):
    __tablename__ = "route_stops"

    route_id = Column(
        Integer,
        ForeignKey("routes.route_id"),
        primary_key=True
    )

    stop_id = Column(
        Integer,
        ForeignKey("stops.stop_id"),
        primary_key=True
    )

    stop_order = Column(Integer, nullable=False)

    departure_offset_minutes = Column(
        Integer,
        nullable=False,
        default=0,
        server_default=text("0")
    )

    route = relationship("Route", back_populates="route_stops")
    stop = relationship("Stop", back_populates="route_stops")


# ==========================================
# 7. ASSIGNMENTS
# ==========================================
class Assignment(Base):
    __tablename__ = "assignments"

    assignment_id = Column(Integer, primary_key=True, autoincrement=True)
    bus_id = Column(Integer, ForeignKey("buses.bus_id"), nullable=False)
    driver_id = Column(Integer, ForeignKey("drivers.driver_id"), nullable=False)
    route_id = Column(Integer, ForeignKey("routes.route_id"), nullable=False)
    assignment_date = Column(Date, nullable=False)

    bus = relationship("Bus", back_populates="assignments")
    driver = relationship("Driver", back_populates="assignments")
    route = relationship("Route", back_populates="assignments")
    schedules = relationship("Schedule", back_populates="assignment")


# ==========================================
# 8. SCHEDULES
# ==========================================
class Schedule(Base):
    __tablename__ = "schedules"

    schedule_id = Column(Integer, primary_key=True, autoincrement=True)
    assignment_id = Column(
        Integer,
        ForeignKey("assignments.assignment_id"),
        nullable=False
    )
    departure_time = Column(Time, nullable=False)
    arrival_time = Column(Time, nullable=False)
    schedule_day = Column(String(20), nullable=False)

    assignment = relationship("Assignment", back_populates="schedules")


# ==========================================
# 9. BUS LOCATIONS
# ==========================================
class BusLocation(Base):
    __tablename__ = "bus_locations"

    location_id = Column(Integer, primary_key=True, autoincrement=True)
    bus_id = Column(Integer, ForeignKey("buses.bus_id"), nullable=False)
    latitude = Column(DECIMAL(10, 7), nullable=False)
    longitude = Column(DECIMAL(10, 7), nullable=False)
    recorded_at = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp()
    )

    bus = relationship("Bus", back_populates="locations")


# ==========================================
# 10. BREAKDOWN REPORTS
# ==========================================
class BreakdownReport(Base):
    __tablename__ = "breakdown_reports"

    report_id = Column(Integer, primary_key=True, autoincrement=True)
    bus_id = Column(Integer, ForeignKey("buses.bus_id"), nullable=False)
    driver_id = Column(Integer, ForeignKey("drivers.driver_id"), nullable=False)
    description = Column(Text, nullable=False)
    reported_at = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp()
    )

    status = Column(
        Enum("REPORTED", "IN_PROGRESS", "RESOLVED"),
        nullable=False,
        default="REPORTED",
        server_default=text("'REPORTED'")
    )

    bus = relationship("Bus", back_populates="breakdown_reports")
    driver = relationship("Driver", back_populates="breakdown_reports")


# ==========================================
# 11. ANNOUNCEMENTS
# ==========================================
class Announcement(Base):
    __tablename__ = "announcements"

    announcement_id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(150), nullable=False)
    message = Column(Text, nullable=False)
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    created_at = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp()
    )

    creator = relationship("User", back_populates="announcements")


# ==========================================
# 12. FCM DEVICE TOKENS
# ==========================================
class FCMDeviceToken(Base):
    __tablename__ = "fcm_device_tokens"

    token_id = Column(Integer, primary_key=True, autoincrement=True)

    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False
    )

    token = Column(String(512), nullable=False, unique=True)

    device_type = Column(
        String(20),
        nullable=False,
        default="ANDROID",
        server_default=text("'ANDROID'")
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("1")
    )

    created_at = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp()
    )

    updated_at = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )

    user = relationship("User", back_populates="device_tokens")
