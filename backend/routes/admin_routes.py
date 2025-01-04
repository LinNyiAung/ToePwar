from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from admin_schemas import AdminLogin, AdminResponse, AdminSignUp, UserListResponse, UserStatusUpdate
from database import admins_collection, users_collection
from utils import get_current_admin
from auth import hash_password, verify_password, create_access_token
from bson import ObjectId
from datetime import datetime
from typing import List

router = APIRouter()

# Admin authentication routes
@router.post("/signup", response_model=AdminResponse)
async def admin_signup(admin: AdminSignUp):
    # Verify super admin key
    if admin.super_admin_key != "YOUR_SECURE_SUPER_ADMIN_KEY":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid super admin key"
        )
    
    # Check if admin already exists
    if admins_collection.find_one({"email": admin.email, "role": "admin"}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admin already exists"
        )
    
    # Create admin document
    admin_doc = {
        "username": admin.username,
        "email": admin.email,
        "password": hash_password(admin.password),
        "role": "admin",
        "created_at": datetime.utcnow()
    }
    
    result = admins_collection.insert_one(admin_doc)
    admin_doc["id"] = str(result.inserted_id)
    return admin_doc

@router.post("/login")
async def admin_login(admin: AdminLogin):
    admin_doc = admins_collection.find_one({
        "email": admin.email,
        "role": "admin"
    })
    
    if not admin_doc or not verify_password(admin.password, admin_doc["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    access_token = create_access_token({"sub": str(admin_doc["_id"]), "role": "admin"})
    return {"access_token": access_token, "token_type": "bearer"}

# User management routes
@router.get("/users", response_model=List[UserListResponse])
async def get_all_users(admin: str = Depends(get_current_admin)):
    users = users_collection.find({"role": {"$ne": "admin"}})
    return [
        {
            "id": str(user["_id"]),
            "username": user["username"],
            "email": user["email"],
            "status": user.get("status", "active"),
            "created_at": user["created_at"].strftime("%Y-%m-%d %H:%M:%S")
        }
        for user in users
    ]

@router.get("/users/{user_id}")
async def get_user_details(user_id: str, admin: str = Depends(get_current_admin)):
    user = users_collection.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return {
        "id": str(user["_id"]),
        "username": user["username"],
        "email": user["email"],
        "status": user.get("status", "active"),
        "created_at": user["created_at"].strftime("%Y-%m-%d %H:%M:%S")
    }



@router.put("/users/{user_id}/status")
async def update_user_status(
    user_id: str,
    status_update: UserStatusUpdate,
    admin: str = Depends(get_current_admin)
):
    if status_update.status not in ["active", "suspended", "banned"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid status. Must be one of: active, suspended, banned"
        )
    
    result = users_collection.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"status": status_update.status}}
    )
    
    if result.modified_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {"message": f"User status updated to {status_update.status}"}

@router.delete("/users/{user_id}")
async def delete_user(user_id: str, admin: str = Depends(get_current_admin)):
    result = users_collection.delete_one({"_id": ObjectId(user_id)})
    
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {"message": "User deleted successfully"}
