"""
simulate_esp32.py
=================
محاكاة ESP32 - يبعت بيانات رطوبة وهمية للـ FastAPI server
شغّله وانت بتتست الـ app من غير ما تحتاج الـ hardware

Usage:
    python simulate_esp32.py
"""

import requests
import time
import random
import math

SERVER_URL = "http://127.0.0.1:8000/sensor-data"

print("=" * 50)
print("  🌱 ESP32 Simulator - Agri-AI")
print("=" * 50)
print(f"  Sending data to: {SERVER_URL}")
print("  Press Ctrl+C to stop\n")

cycle = 0

while True:
    # Simulate realistic moisture oscillation (drops over time, pump kicks in)
    base_moisture = 55 + 30 * math.sin(cycle * 0.3)
    noise = random.uniform(-5, 5)
    moisture = round(max(10, min(95, base_moisture + noise)))

    # Auto pump logic: turn on if moisture < 35%, off if > 60%
    pump_on = moisture < 35

    payload = {
        "moisture": moisture,
        "pump_on": pump_on,
    }

    try:
        response = requests.post(SERVER_URL, json=payload, timeout=5)
        status = "✅" if response.status_code == 200 else "❌"
        pump_status = "💧 ON" if pump_on else "⏸  OFF"
        print(f"  {status} Cycle {cycle + 1:03d} | Moisture: {moisture:3d}% | Pump: {pump_status} | HTTP {response.status_code}")
    except requests.exceptions.ConnectionError:
        print(f"  ❌ Cannot connect to server at {SERVER_URL}")
        print("     Make sure FastAPI server is running: python main.py")
    except Exception as e:
        print(f"  ❌ Error: {e}")

    cycle += 1
    time.sleep(5)  # Send every 5 seconds (same as real ESP32)
