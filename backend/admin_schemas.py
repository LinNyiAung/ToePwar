from pydantic import BaseModel, EmailStr
from typing import Optional, List

class AdminSignUp(BaseModel):
    username: str
    email: EmailStr
    password: str
    super_admin_key: str  # Required key for creating admin accounts

class AdminLogin(BaseModel):
    email: EmailStr
    password: str

class AdminResponse(BaseModel):
    id: str
    username: str
    email: EmailStr
    role: str

class UserListResponse(BaseModel):
    id: str
    username: str
    email: EmailStr
    status: str
    created_at: str


class UserStatusUpdate(BaseModel):
    status: str