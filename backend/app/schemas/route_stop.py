
from pydantic import BaseModel, Field


class CreateRouteStop(BaseModel):
    route_id: int
    stop_id: int
    stop_order: int = Field(gt=0)
    departure_offset_minutes: int = Field(default=0, ge=0)


class UpdateRouteStop(BaseModel):
    stop_order: int | None = Field(default=None, gt=0)
    departure_offset_minutes: int | None = Field(default=None, ge=0)
