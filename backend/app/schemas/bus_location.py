from datetime import datetime
from pydantic import BaseModel, Field


class CreateBusLocation(BaseModel):
    bus_id: int = Field(gt=0)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    recorded_at: datetime


class UpdateBusLocation(BaseModel):
    bus_id: int | None = Field(default=None, gt=0)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    recorded_at: datetime | None = None

    