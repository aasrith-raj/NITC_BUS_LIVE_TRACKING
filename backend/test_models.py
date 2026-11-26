
from app.models import (
    User, Driver, Bus, Route, Stop, RouteStop,
    Assignment, Schedule, BusLocation,
    BreakdownReport, Announcement
)

models = [
    User, Driver, Bus, Route, Stop, RouteStop,
    Assignment, Schedule, BusLocation,
    BreakdownReport, Announcement
]

print("CHECKING ALL ORM MODELS\n")

for model in models:
    print(
        model.__name__,
        "->",
        model.__tablename__
    )

print("\nTOTAL MODELS:", len(models))

print("\nCOMPOSITE PRIMARY KEY:")
print(list(RouteStop.__table__.primary_key.columns.keys()))

print("\nALL MODELS LOADED SUCCESSFULLY!")
