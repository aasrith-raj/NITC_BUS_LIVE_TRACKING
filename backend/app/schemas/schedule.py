from datetime import time
from pydantic import BaseModel, Field


class CreateSchedule(BaseModel):
    assignment_id: int = Field(gt=0)
    departure_time: time
    arrival_time: time
    schedule_day: str = Field(min_length=1)


class UpdateSchedule(BaseModel):
    assignment_id: int | None = Field(default=None, gt=0)
    departure_time: time | None = None
    arrival_time: time | None = None
    schedule_day: str | None = Field(default=None, min_length=1)