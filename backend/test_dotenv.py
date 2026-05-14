import os
from dotenv import load_dotenv
dotenv_path = os.path.join(os.path.dirname(__file__), '..', '.env')
print(f"Loading from: {dotenv_path}")
print(f"File exists: {os.path.exists(dotenv_path)}")
load_dotenv(dotenv_path)
print(f"SUPABASE_URL: {os.getenv('SUPABASE_URL')}")
