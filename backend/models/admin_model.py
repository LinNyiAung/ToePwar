from bson import ObjectId
from pydantic import BaseModel, EmailStr

class Admin(BaseModel):
    username: str
    email: EmailStr
    password: str
    role: str = "admin"
    
    class Config:
        json_encoders = {
            ObjectId: str
        }