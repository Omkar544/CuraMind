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
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your_fallback_secret_for_dev_only")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

router = APIRouter()
 
# --- Pydantic Models ---

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
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    weight_kg: Optional[float] = None
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None
    username: Optional[str] = None


# --- Helper Functions ---

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
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
        cur.execute(
            "SELECT username FROM users WHERE username = %s OR email = %s", 
            (user_data.username, user_data.email)
        )
        if cur.fetchone():
            raise HTTPException(
                status_code=400,
                detail="Username or Email already registered"
            )

        # ✅ FIXED: Use UUID object (not string)
        user_uuid = uuid.uuid4()
        hashed_pwd = get_password_hash(user_data.password)

        cur.execute(
            """INSERT INTO users 
            (user_id, first_name, last_name, age, gender, weight_kg, phone_number, email, username, password) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (
                user_uuid,
                user_data.first_name,
                user_data.last_name,
                user_data.age,
                user_data.gender,
                user_data.weight_kg,
                user_data.phone_number,
                user_data.email,
                user_data.username,
                hashed_pwd
            )
        )

        conn.commit()

        access_token = create_access_token(data={"sub": str(user_uuid)})

        print(f"✅ User Registered: {user_data.username} [ID: {user_uuid}]")

        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": str(user_uuid),
            "user_name": user_data.first_name
        }

    except Exception as e:
        print(f"❌ FULL DB ERROR: {e}")  # Now shows real error
        raise HTTPException(status_code=500, detail=str(e))
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
        cur.execute(
            "SELECT user_id, password, first_name FROM users WHERE username = %s",
            (user_data.username,)
        )
        row = cur.fetchone()

        if not row or not verify_password(user_data.password, row[1]):
            raise HTTPException(status_code=401, detail="Incorrect username or password")

        user_uuid = str(row[0])
        first_name = row[2]

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
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT first_name, last_name, age, gender, weight_kg, 
                   phone_number, email, username
            FROM users WHERE user_id = %s
        """, (user_id,))
        
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")

        return {
            "first_name": row[0],
            "last_name": row[1],
            "age": row[2],
            "gender": row[3],
            "weight_kg": float(row[4]),
            "phone_number": row[5],
            "email": row[6],
            "username": row[7]
        }
    finally:
        cur.close()
        conn.close()


@router.put("/update-profile/{user_id}")
async def update_profile(user_id: str, data: ProfileUpdate):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="PostgreSQL Connection Failed")

    cur = conn.cursor()
    try:
        update_fields = []
        values = []

        for field, value in data.dict(exclude_none=True).items():
            update_fields.append(f"{field} = %s")
            values.append(value)

        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields provided for update")

        values.append(user_id)

        query = f"""
            UPDATE users
            SET {', '.join(update_fields)}
            WHERE user_id = %s
        """

        cur.execute(query, tuple(values))

        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")

        conn.commit()

        print(f"🔄 Full Profile Updated for user: {user_id}")

        return {
            "status": "success",
            "message": "Profile updated successfully"
        }

    finally:
        cur.close()
        conn.close()


@router.delete("/delete/{user_id}")
async def delete_user_account(user_id: str):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="PostgreSQL Connection Failed")

    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")

        conn.commit()

        print(f"🗑️ Account Deleted: {user_id}")

        return {
            "status": "success",
            "message": "Account successfully removed from system"
        }
    finally:
        cur.close()
        conn.close()