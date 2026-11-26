from pydantic import BaseModel, Field


class CreateRoute(BaseModel):
    route_name: str = Field(min_length=1, max_length=100)
    start_location: str = Field(min_length=1, max_length=150)
    end_location: str = Field(min_length=1, max_length=150)
    is_active: bool = True


class UpdateRoute(BaseModel):
    route_name: str | None = Field(
        default=None, min_length=1, max_length=100
    )
    start_location: str | None = Field(
        default=None, min_length=1, max_length=150
    )
    end_location: str | None = Field(
        default=None, min_length=1, max_length=150
    )
    is_active: bool | None = None