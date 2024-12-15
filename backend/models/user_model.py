from bson import ObjectId
from pydantic import BaseModel, EmailStr

class User(BaseModel):
    username: str  
    email: EmailStr
    password: str

    class Config:
        json_encoders = {
            ObjectId: str  # Convert ObjectId to string
        }
