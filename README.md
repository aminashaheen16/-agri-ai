# Agri.AI: Smart Agricultural Ecosystem 🌱

**Agri.AI** is a premium, AI-powered agricultural platform designed to bridge the gap between traditional farming and modern technology. It empowers farmers and plant enthusiasts with real-time data, expert AI advice, and a comprehensive marketplace.

---

## 🚀 Key Features

### 🧠 AI Agricultural Doctor
- **Expert Diagnosis:** Powered by **Llama-3 (70B)** via Groq Cloud, providing real-time diagnosis for plant diseases.
- **Localized Advice:** Delivers expert consultations in natural language (including Arabic/Egyptian dialect).
- **Product Integration:** Recommends specific fertilizers and treatments directly from the internal store.

### 🏪 Smart Marketplace (Store)
- **Extensive Inventory:** 500+ agricultural products including seeds, fertilizers, and tools.
- **Smart Categorization:** Easily filter products by type and crop needs.
- **Real-time Sync:** Persistent cart and orders synced with **Supabase**.
- **Secure Payments:** Integrated with **PayPal** for safe transactions.

### 🌡️ Real-time IoT Dashboard
- **Sensor Monitoring:** Live tracking of soil moisture, ambient temperature, and humidity.
- **Smart Irrigation:** Automated pump control based on soil moisture thresholds.
- **Hardware Simulation:** Built-in Python scripts to simulate ESP32 sensor data for testing without hardware.

### ♿ Accessibility & UX
- **Inclusive Design:** Dedicated Accessibility Center with dynamic font sizing and high-contrast modes.
- **Multilingual:** Full support for Arabic (SA) and English (US).
- **Premium Aesthetics:** Sleek "Agri-Premium" UI with Cairo typography and smooth animations.

---

## 🛠 Tech Stack

- **Frontend:** Flutter (Riverpod for state management)
- **Backend:** Supabase (Auth, PostgreSQL, Real-time Database)
- **AI Engine:** Groq Cloud API (Llama-3 models)
- **Disease Detection Model:** Trained on custom datasets (Kaggle Notebook: [Plant Disease Detection](https://www.kaggle.com/code/ayana16/graduation-project))
- **IoT/Hardware:** ESP32 (Arduino C++) & Python Simulation
- **Payments:** PayPal API

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable)
- Python 3.x (for simulation)
- Supabase account

### 2. Environment Configuration
Create a `.env` file in the root directory based on `.env.example`:
```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
GROQ_API_KEY=your_groq_key
WEATHER_API_KEY=your_openweather_key
```

### 3. Install Dependencies
```bash
flutter pub get
cd backend && pip install -r requirements.txt
```

### 4. Run the App
```bash
flutter run
```

### 5. Start Hardware Simulation (Optional)
```bash
cd backend
python main_sim.py        # Starts the FastAPI server
python simulate_esp32.py  # Starts the sensor simulator
```

---

## 📸 Screenshots Section
*(Coming Soon: Add your project screenshots here to showcase the premium UI!)*

---

## 🤝 Contribution & Support
Developed with ❤️ for the agricultural community. For support, contact [aminashaheen16](https://github.com/aminashaheen16).

---
*Agri.AI v1.0.0 | Soil For Soul Project*
