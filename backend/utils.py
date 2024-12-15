from fastapi import HTTPException, Depends
from jose import jwt, JWTError
from auth import SECRET_KEY, ALGORITHM
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Helper function to get the current user
def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    

# Helper function to serialize MongoDB documents
def serialize_transaction(transaction):
    transaction["_id"] = str(transaction["_id"])  # Convert ObjectId to string
    transaction["user_id"] = str(transaction["user_id"])  # Convert user_id ObjectId to string if needed
    return transaction
