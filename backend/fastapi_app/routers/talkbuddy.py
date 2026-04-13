# backend/fastapi_app/routers/talkbuddy.py

from fastapi import APIRouter # Keep APIRouter for defining endpoints later
# Removed: from openai import OpenAI
# Removed: from pydantic import BaseModel
# Removed: import os

# Initialize the router
router = APIRouter()

# --- All previous OpenRouter specific code has been removed ---
# --- This file is now an empty placeholder for future custom chatbot integration ---

# If you decide to add a custom backend chatbot later,
# you would define your Pydantic models (e.g., ChatRequest)
# and your API endpoints (e.g., @router.post("/chat")) here.
# For now, it's an empty router.