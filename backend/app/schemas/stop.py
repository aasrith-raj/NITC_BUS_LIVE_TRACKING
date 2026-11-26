from pydantic import BaseModel, Field


class CreateStop(BaseModel):
    stop_name: str = Field(min_length=1, max_length=100)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class UpdateStop(BaseModel):
    stop_name: str | None = Field(
        default=None, min_length=1, max_length=100
    )
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)