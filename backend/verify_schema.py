
from sqlalchemy import inspect
from app.database.connection import engine
from app.models import *

inspector = inspect(engine)

models = [
    User, Driver, Bus, Route, Stop, RouteStop,
    Assignment, Schedule, BusLocation,
    BreakdownReport, Announcement
]

print("VERIFYING ORM MODELS AGAINST MYSQL\n")

for model in models:
    table = model.__tablename__

    db_columns = {
        col["name"] for col in inspector.get_columns(table)
    }

    orm_columns = set(model.__table__.columns.keys())

    db_pk = set(
        inspector.get_pk_constraint(table)["constrained_columns"]
    )

    orm_pk = {
        col.name for col in model.__table__.primary_key.columns
    }

    print(f"\nTABLE: {table}")

    if db_columns == orm_columns:
        print("Columns: MATCH")
    else:
        print("Columns: MISMATCH")
        print("Missing in ORM:", db_columns - orm_columns)
        print("Extra in ORM:", orm_columns - db_columns)

    if db_pk == orm_pk:
        print("Primary keys: MATCH")
    else:
        print("Primary keys: MISMATCH")

print("\nSCHEMA VERIFICATION COMPLETED")
