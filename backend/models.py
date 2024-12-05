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
    user_id: Optional[str] = Field(None, exclude=True)

class Goal(BaseModel):
    user_id: str
    target_amount: float
    current_amount: float = 0
    deadline: datetime
