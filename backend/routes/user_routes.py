from fastapi import APIRouter, Depends, HTTPException
from database import users_collection
from utils import get_current_user
from bson import ObjectId

router = APIRouter()

@router.get("/profile")
def get_profile(user_id: str = Depends(get_current_user)):
    user_data = users_collection.find_one({"_id": ObjectId(user_id)})
    if not user_data:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": str(user_data["_id"]),
        "username": user_data["username"],
        "email": user_data["email"]
    }
