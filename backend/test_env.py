import os
from dotenv import load_dotenv

# This path should be exactly where your .env file is located
env_file_path = os.path.join(os.path.dirname(__file__), '.env')
print(f"Attempting to load .env from: {env_file_path}")

# Load the environment variables
loaded_successfully = load_dotenv(dotenv_path=env_file_path)
print(f".env file loaded successfully by dotenv: {loaded_successfully}")

# Check the JWT_SECRET_KEY
jwt_secret_key = os.getenv("JWT_SECRET_KEY")
print(f"Value of JWT_SECRET_KEY: '{jwt_secret_key}'")
print(f"JWT_SECRET_KEY is loaded: {bool(jwt_secret_key)}")

# Check the OPENROUTER_API_KEY
openrouter_key = os.getenv("OPENROUTER_API_KEY")
print(f"Value of OPENROUTER_API_KEY: '{openrouter_key}'")
print(f"OPENROUTER_API_KEY is loaded: {bool(openrouter_key)}")