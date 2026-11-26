
from pydantic import BaseModel, Field


class RegisterFCMToken(BaseModel):
    token: str = Field(min_length=1, max_length=512)
    device_type: str = Field(default="ANDROID", max_length=20)
