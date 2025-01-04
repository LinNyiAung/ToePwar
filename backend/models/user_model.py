import datetime
from typing import Literal
from bson import ObjectId
from pydantic import BaseModel, EmailStr

class User(BaseModel):
    username: str  
    email: EmailStr
    password: str
    status: Literal["active", "suspended", "banned"] = "active"
    created_at: datetime = datetime.utcnow()

    class Config:
        json_encoders = {
            ObjectId: str,  # Convert ObjectId to string
            datetime: lambda dt: dt.isoformat()  # Convert datetime to ISO format string
        }
