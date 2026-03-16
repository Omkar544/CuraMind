from sqlalchemy import Column, String, Integer, Numeric, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
import uuid
import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    # The Global Unique ID that links PostgreSQL to MongoDB
    user_id = Column(UUID(as_uuid=True), unique=True, default=uuid.uuid4, nullable=False)
    
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    age = Column(Integer, nullable=False)
    gender = Column(String(10), nullable=False)
    weight_kg = Column(Numeric(5, 2), nullable=False)
    phone_number = Column(String(20), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    username = Column(String(50), unique=True, nullable=False)
    password = Column(Text, nullable=False) # Hashed password
    created_at = Column(DateTime, default=datetime.datetime.utcnow)