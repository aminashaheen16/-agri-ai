import os
import uvicorn
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import numpy as np
from PIL import Image
import io
import tflite_runtime.interpreter as tflite
from groq import Groq
from dotenv import load_dotenv

# Load environment variables from .env file (one level up)
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

app = FastAPI()

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Groq Client
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# Load TFLite Model
MODEL_PATH = "models/plant_model.tflite"
LABELS_PATH = "models/labels.txt"

interpreter = tflite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

with open(LABELS_PATH, 'r') as f:
    labels = [line.strip() for line in f.readlines()]

def get_ai_advice(disease_name):
    prompt = f"""
    أنت خبير زراعي عالمي. تم اكتشاف مرض في النبات يسمى: {disease_name}.
    يرجى تقديم تقرير مفصل باللغة العربية يشمل:
    1. وصف بسيط للمرض.
    2. الأسباب المحتملة.
    3. خطوات العلاج الفورية.
    4. نصائح للوقاية في المستقبل.
    اجعل الأسلوب مهنياً ومبسطاً للمزارع.
    """
    
    completion = groq_client.chat.completions.create(
        model="llama3-70b-8192",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )
    return completion.choices[0].message.content

from pydantic import BaseModel

from supabase import create_client, Client
import os

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class SensorData(BaseModel):
    moisture: int
    pump_on: bool
    user_id: str = "73" # Default for testing, ESP32 can send this later

@app.post("/sensor-data")
async def receive_sensor_data(data: SensorData):
    print(f"Received from ESP32: Moisture={data.moisture}, Pump={'ON' if data.pump_on else 'OFF'}")
    
    # Save to Supabase soil_readings table
    try:
        response = supabase.table('soil_readings').insert({
            'moisture': data.moisture,
            'pump_on': data.pump_on,
            'user_id': "428aabb9-0414-46fa-b789-07e5b6a179c9" # Your current session user ID
        }).execute()
        print("Successfully saved to Supabase")
    except Exception as e:
        print(f"Error saving to Supabase: {e}")
    
    return {"status": "success", "received": data}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Read and preprocess image
    image_data = await file.read()
    image = Image.open(io.BytesIO(image_data)).convert('RGB')
    image = image.resize((input_details[0]['shape'][1], input_details[0]['shape'][2]))
    
    input_data = np.expand_dims(image, axis=0).astype(np.float32)
    # Normalization if needed (usually 1/255.0)
    input_data = input_data / 255.0

    # Run inference
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    
    output_data = interpreter.get_tensor(output_details[0]['index'])
    results = np.squeeze(output_data)
    
    top_index = results.argmax()
    disease_name = labels[top_index]
    confidence = float(results[top_index])

    # Get AI advice for the detected disease
    advice = get_ai_advice(disease_name)

    return {
        "disease": disease_name,
        "confidence": confidence,
        "treatment_report": advice
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
