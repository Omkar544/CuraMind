import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def initialize_postgresql():
    """
    Connects to PostgreSQL and verifies the 'users' table readiness.
    Removed password requirement as per user configuration.
    """
    conn = None
    try:
        # Connect to PostgreSQL (Password removed)
        conn = psycopg2.connect(
            host="localhost",
            database="curamind_db",
            user="postgres"
        )
        cur = conn.cursor()

        # 1. Enable UUID extension if not already present
        cur.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')

        # 2. Verify or ensure Users Table with your 10 fields
        # Using IF NOT EXISTS so it doesn't error out since the table is already created
        create_table_query = """
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            user_id UUID UNIQUE NOT NULL,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            age INT NOT NULL,
            gender VARCHAR(10) NOT NULL,
            weight_kg DECIMAL(5,2) NOT NULL,
            phone_number VARCHAR(20) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            username VARCHAR(50) UNIQUE NOT NULL,
            password TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        cur.execute(create_table_query)
        conn.commit()
        print("✅ PostgreSQL: Connection successful and 'users' table is verified.")
        
        cur.close()
    except Exception as e:
        print(f"❌ PostgreSQL Error: {e}")
    finally:
        if conn:
            conn.close()

def check_mongodb():
    """
    MongoDB creates databases/collections automatically on first insert.
    We just check if the service is reachable.
    """
    from pymongo import MongoClient
    try:
        client = MongoClient("mongodb://localhost:27017/", serverSelectionTimeoutMS=2000)
        client.admin.command('ping')
        print("✅ MongoDB: Service is running and reachable.")
    except Exception as e:
        print(f"⚠️ MongoDB Warning: Service not found. Make sure MongoDB is running. Error: {e}")

if __name__ == "__main__":
    print("--- CuraMind Database Initialization ---")
    initialize_postgresql()
    check_mongodb()
    print("---------------------------------------")