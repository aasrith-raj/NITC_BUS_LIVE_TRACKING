from datetime import datetime
from typing import Literal
from pydantic import BaseModel, Field


ReportStatus = Literal["REPORTED", "IN_PROGRESS", "RESOLVED"]


class CreateBreakdownReport(BaseModel):
    bus_id: int = Field(gt=0)
    driver_id: int = Field(gt=0)
    description: str = Field(min_length=1)
    status: ReportStatus = "REPORTED"


class UpdateBreakdownReport(BaseModel):
    bus_id: int | None = Field(default=None, gt=0)
    driver_id: int | None = Field(default=None, gt=0)
    description: str | None = Field(default=None, min_length=1)
    reported_at: datetime | None = None
    status: ReportStatus | None = None