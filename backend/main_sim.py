"""
main_sim.py — Simulation Backend (بدون TFLite)
================================================
نفس الـ endpoints بس من غير Plant Disease Model
استخدمه للتست من غير ما تحتاج الـ hardware

Run: python3 main_sim.py
"""

import uvicorn
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

app = FastAPI(title="Agri-AI Simulation Server")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class SensorData(BaseModel):
    moisture: int
    pump_on: bool
    user_id: str = "sim-user"

@app.get("/")
def root():
    return {"status": "🌱 Agri-AI Simulation Server is running!"}

@app.post("/sensor-data")
async def receive_sensor_data(data: SensorData):
    print(f"📡 ESP32 Sim → Moisture: {data.moisture}% | Pump: {'ON 💧' if data.pump_on else 'OFF ⏸'}")

    try:
        response = supabase.table('soil_readings').insert({
            'moisture': data.moisture,
            'pump_on': data.pump_on,
            'user_id': "428aabb9-0414-46fa-b789-07e5b6a179c9"
        }).execute()
        print(f"   ✅ Saved to Supabase → ID: {response.data[0].get('id', '?') if response.data else '?'}")
    except Exception as e:
        print(f"   ❌ Supabase error: {e}")

    return {"status": "success", "received": data}

@app.post("/toggle-pump")
async def toggle_pump(pump_on: bool):
    """Manual pump toggle from Flutter app"""
    try:
        supabase.table('commands').insert({
            'command': 'toggle_pump',
            'value': pump_on
        }).execute()
        print(f"🔧 Manual pump toggle → {'ON' if pump_on else 'OFF'}")
    except Exception as e:
        print(f"❌ Command error: {e}")
    return {"status": "success", "pump_on": pump_on}

@app.get("/latest-reading")
async def get_latest():
    """Get the latest sensor reading from Supabase"""
    try:
        res = supabase.table('soil_readings')\
            .select("*")\
            .order('created_at', desc=True)\
            .limit(1)\
            .execute()
        return res.data[0] if res.data else {"error": "No data yet"}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    print("\n" + "="*50)
    print("  🌱 Agri-AI Simulation Backend")
    print("="*50)
    print("  📡 Sensor endpoint : POST /sensor-data")
    print("  📊 Latest reading  : GET  /latest-reading")
    print("  🔧 Toggle pump     : POST /toggle-pump")
    print("  📖 API Docs        : http://127.0.0.1:8000/docs")
    print("="*50 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8000)
