import os
from dotenv import load_dotenv
from typing import Optional
from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware

# --- ENVIRONMENT LOADING ---
# Ensures that sensitive keys (like Gemini or MongoDB URIs) are loaded from .env
dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=dotenv_path)

# --- EXPLICIT ROUTER IMPORTS ---
# These imports resolve the 'AttributeError' by explicitly referencing the router objects
from .routers.auth import router as auth_router
from .routers.dailymoves import router as dailymoves_router
from .routers.mindease import router as mindease_router
from .routers.lifelog import router as lifelog_router
from .routers.careclock import router as careclock_router
from .routers.talkbuddy import router as talkbuddy_router

app = FastAPI(
    title="CuraMind AI API",
    description="Holistic health backend connecting PostgreSQL and MongoDB for AI assessments.",
    version="1.0.0"
)

# --- CORS FOR EMULATOR & PHYSICAL DEVICES ---
# This middleware allows your Flutter app to reach the FastAPI server 
# even when running on different IP addresses (common in mobile development).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    """Silence favicon requests from browsers during testing."""
    return Response(status_code=204)

# --- REGISTER ROUTES ---
# These prefixes match the URLs used in your Flutter ApiService.
app.include_router(auth_router, prefix="/api/auth", tags=["Identity & Auth"])
app.include_router(dailymoves_router, prefix="/api/dailymoves", tags=["Fitness (XGBoost)"])
app.include_router(mindease_router, prefix="/api/mindease", tags=["Mental Health (NLP)"])
app.include_router(careclock_router, prefix="/api/careclock", tags=["CareClock Planner"])
app.include_router(lifelog_router, prefix="/api/lifelog", tags=["LifeLog Hub Timeline"])
app.include_router(talkbuddy_router, prefix="/api/talkbuddy", tags=["TalkBuddy AI Chat"])

@app.get("/")
async def root():
    return {
        "message": "CuraMind API Online",
        "environment": "Development",
        "sync_status": "Ready for Mobile"
    }

if __name__ == "__main__":
    import uvicorn
    # IMPORTANT: host="0.0.0.0" is mandatory for physical mobile devices to 
    # see the server. Use 10.0.2.2 in the Flutter app to point back to this.
    uvicorn.run(app, host="0.0.0.0", port=8000)