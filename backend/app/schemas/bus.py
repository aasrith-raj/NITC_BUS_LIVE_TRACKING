from pydantic import BaseModel, Field
from typing import Literal


class CreateBus(BaseModel):
    bus_number: str = Field(min_length=1, max_length=30)
    registration_number: str | None = Field(
        default=None, max_length=30
    )
    capacity: int = Field(gt=0)
    status: Literal["ACTIVE", "INACTIVE", "MAINTENANCE"] = "ACTIVE"


class UpdateBus(BaseModel):
    bus_number: str | None = Field(
        default=None, min_length=1, max_length=30
    )
    registration_number: str | None = Field(
        default=None, max_length=30
    )
    capacity: int | None = Field(default=None, gt=0)
    status: Literal[
        "ACTIVE", "INACTIVE", "MAINTENANCE"
    ] | None = None