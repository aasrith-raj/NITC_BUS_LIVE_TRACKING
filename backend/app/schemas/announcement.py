from pydantic import BaseModel, Field


class CreateAnnouncement(BaseModel):
    title: str = Field(min_length=1)
    message: str = Field(min_length=1)
    created_by: int = Field(gt=0)


class UpdateAnnouncement(BaseModel):
    title: str | None = Field(default=None, min_length=1)
    message: str | None = Field(default=None, min_length=1)