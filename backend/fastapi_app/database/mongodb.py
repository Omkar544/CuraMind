# backend/fastapi_app/database/mongodb.py

from pymongo import MongoClient
import os
from dotenv import load_dotenv
from fastapi import HTTPException

# Load variables from .env file (if it exists)
load_dotenv()

MONGO_URI = os.getenv("MONGODB_URI")
client = None
db = None

if MONGO_URI:
    try:
        client = MongoClient(MONGO_URI)
        db = client.curamind_db
        print("✅ MongoDB connection configured (attempted).")
    except Exception as e:
        print(f"⚠️ Warning: Could not connect to MongoDB despite URI being set: {e}")
        # Keep client and db as None if connection fails
else:
    print("⚠️ Warning: MONGODB_URI environment variable not set. Database operations will be skipped/fail.")

def get_database():
    """
    Returns the database instance.
    Raises HTTPException if database is not available.
    """
    if db is None:
        raise HTTPException(status_code=503, detail="MongoDB service is not configured or available.")
    return db

# Optional: Add a function to check if DB is ready
def is_db_ready():
    return db is not None and client is not None