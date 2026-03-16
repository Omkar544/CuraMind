from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime, timedelta
from typing import Optional
import jwt
import os
import uuid
from passlib.context import CryptContext
from ..database import get_db_connection

# --- Security Configuration ---
# Ensure these match your .env file
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your_fallback_secret_for_dev_only")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 # 24 hours for easier testing

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

router = APIRouter()

# --- Pydantic Models (Matching the 10 fields in Flutter/Postgres) ---

class UserCreate(BaseModel):
    first_name: str
    last_name: str
    age: int
    gender: str
    weight_kg: float
    phone_number: str
    email: EmailStr
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6)

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: str
    user_name: str

class ProfileUpdate(BaseModel):
    age: Optional[int] = None
    weight_kg: Optional[float] = None

# --- Helper Functions ---

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# --- Endpoints ---

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register_user(user_data: UserCreate):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="PostgreSQL Connection Failed")
    
    cur = conn.cursor()
    try:
        # 1. Check if user already exists
        cur.execute("SELECT username FROM users WHERE username = %s OR email = %s", 
                   (user_data.username, user_data.email))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Username or Email already registered")

        # 2. Generate UUID and Hash Password
        user_uuid = str(uuid.uuid4())
        hashed_pwd = get_password_hash(user_data.password)

        # 3. Insert into PostgreSQL (The 10 fields)
        cur.execute(
            """INSERT INTO users (user_id, first_name, last_name, age, gender, weight_kg, phone_number, email, username, password) 
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (user_uuid, user_data.first_name, user_data.last_name, user_data.age, user_data.gender,
             user_data.weight_kg, user_data.phone_number, user_data.email, user_data.username, hashed_pwd)
        )
        
        # 4. Generate Token
        access_token = create_access_token(data={"sub": user_uuid})
        
        print(f"✅ User Registered: {user_data.username} [ID: {user_uuid}]")
        
        return {
            "access_token": access_token, 
            "token_type": "bearer",
            "user_id": user_uuid,
            "user_name": user_data.first_name
        }

    except Exception as e:
        print(f"❌ DB Error: {e}")
        raise HTTPException(status_code=500, detail="Database insertion failed")
    finally:
        cur.close()
        conn.close()

@router.post("/login", response_model=Token)
async def login(user_data: UserLogin):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="PostgreSQL Connection Failed")
    
    cur = conn.cursor()
    try:
        # 1. Fetch user by username
        cur.execute("SELECT user_id, password, first_name FROM users WHERE username = %s", (user_data.username,))
        row = cur.fetchone()
        
        if not row or not verify_password(user_data.password, row[1]):
            raise HTTPException(status_code=401, detail="Incorrect username or password")

        user_uuid = str(row[0])
        first_name = row[2]

        # 2. Generate Token
        access_token = create_access_token(data={"sub": user_uuid})
        
        return {
            "access_token": access_token, 
            "token_type": "bearer",
            "user_id": user_uuid,
            "user_name": first_name
        }
    finally:
        cur.close()
        conn.close()

@router.get("/profile/{user_id}")
async def get_profile(user_id: str):
    """Used by DailyMoves to fetch age/weight for ML prediction"""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT first_name, age, weight_kg, gender FROM users WHERE user_id = %s", (user_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "first_name": row[0],
            "age": row[1],
            "weight": float(row[2]),
            "gender": row[3]
        }
    finally:
        cur.close()
        conn.close()

@router.put("/update-profile/{user_id}")
async def update_profile(user_id: str, data: ProfileUpdate):
    """Allows updating Age and Weight to keep the XGBoost baseline accurate."""
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="PostgreSQL Connection Failed")
    cur = conn.cursor()
    try:
        if data.age is not None:
            cur.execute("UPDATE users SET age = %s WHERE user_id = %s", (data.age, user_id))
        if data.weight_kg is not None:
            cur.execute("UPDATE users SET weight_kg = %s WHERE user_id = %s", (data.weight_kg, user_id))
        
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")
            
        print(f"🔄 Profile Updated for user: {user_id}")
        return {"status": "success", "message": "Identity fields updated successfully"}
    finally:
        cur.close()
        conn.close()

@router.delete("/delete/{user_id}")
async def delete_user_account(user_id: str):
    """Wipes the user from PostgreSQL. Used by UserManagementService for 'Clean Slate'."""
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="PostgreSQL Connection Failed")
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")
            
        print(f"🗑️ Account Deleted: {user_id}")
        return {"status": "success", "message": "Account successfully removed from system"}
    finally:
        cur.close()
        conn.close()