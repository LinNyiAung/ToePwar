from bson import ObjectId
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class User(BaseModel):
    username: str  
    email: EmailStr
    password: str

class Transaction(BaseModel):
    type: str  # income or expense
    amount: float
    category: str  # e.g., food, transport
    date: datetime
    user_id: Optional[str] = None

    class Config:
        json_encoders = {
            ObjectId: str  # Convert ObjectId to string
        }

class Goal(BaseModel):
    name: str
    target_amount: float
    current_amount: float = 0
    deadline: datetime
    completed: bool = False
    completion_date: Optional[datetime] = None
    user_id: Optional[str] = None

    class Config:
        json_encoders = {
            ObjectId: str
        }
