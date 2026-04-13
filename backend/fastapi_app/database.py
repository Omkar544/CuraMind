import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

# Load environment variables from the root .env file
dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=dotenv_path)

# --- POSTGRESQL CONFIGURATION ---
# These variables are used by get_db_connection to link the auth router to pgAdmin
DB_NAME = os.getenv("DB_NAME", "curamind_db")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "") # Use your actual pgAdmin password here
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

def get_db_connection():
    """
    Creates and returns a connection to the PostgreSQL database.
    This function is imported by routers/auth.py to handle registration and login.
    """
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT
        )
        # We enable autocommit so that SQL INSERTs from the Auth router persist immediately
        conn.autocommit = True 
        return conn
    except Exception as e:
        print(f"❌ PostgreSQL Connection Error: {e}")
        return None