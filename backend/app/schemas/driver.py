from pydantic import BaseModel, Field


class CreateDriver(BaseModel):
    user_id: int = Field(gt=0)
    license_number: str = Field(min_length=1)


class UpdateDriver(BaseModel):
    license_number: str | None = Field(
        default=None,
        min_length=1
    )