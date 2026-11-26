from datetime import date
from pydantic import BaseModel


class CreateAssignment(BaseModel):
    bus_id: int
    driver_id: int
    route_id: int
    assignment_date: date


class UpdateAssignment(BaseModel):
    bus_id: int | None = None
    driver_id: int | None = None
    route_id: int | None = None
    assignment_date: date | None = None