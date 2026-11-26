import re
from pydantic import BaseModel, Field, field_validator


def validate_password(value: str) -> str:
    if " " in value or any(ch.isspace() for ch in value):
        raise ValueError("Password must not contain spaces")

    if not re.search(r"[A-Z]", value):
        raise ValueError("Password must contain at least one uppercase letter")

    if not re.search(r"[a-z]", value):
        raise ValueError("Password must contain at least one lowercase letter")

    if not re.search(r"[0-9]", value):
        raise ValueError("Password must contain at least one number")

    if not re.search(r"[^A-Za-z0-9\s]", value):
        raise ValueError("Password must contain at least one special character")

    return value


class CreateUser(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8)
    #role: str = Field(min_length=1)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value):
        value = value.strip()

        if not re.fullmatch(
            r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
            value
        ):
            raise ValueError("Enter a valid email address")

        return value.lower()

    @field_validator("password")
    @classmethod
    def check_password(cls, value):
        return validate_password(value)

class LoginRequest(BaseModel):
    email: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1)

class UpdateUser(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    email: str | None = Field(default=None, min_length=5, max_length=150)
    password: str | None = Field(default=None, min_length=8)
    role: str | None = Field(default=None, min_length=1)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value):
        if value is None:
            return value

        value = value.strip()

        if not re.fullmatch(
            r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
            value
        ):
            raise ValueError("Enter a valid email address")

        return value.lower()

    @field_validator("password")
    @classmethod
    def check_password(cls, value):
        if value is None:
            return value
        return validate_password(value)


class CreateDriverAccount(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8)
    license_number: str = Field(min_length=1, max_length=50)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value):
        value = value.strip()

        if not re.fullmatch(
            r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
            value
        ):
            raise ValueError("Enter a valid email address")

        return value.lower()

    @field_validator("password")
    @classmethod
    def check_password(cls, value):
        return validate_password(value)


class CreateAdminAccount(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value):
        value = value.strip()

        if not re.fullmatch(
            r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
            value
        ):
            raise ValueError("Enter a valid email address")

        return value.lower()

    @field_validator("password")
    @classmethod
    def check_password(cls, value):
        return validate_password(value)
