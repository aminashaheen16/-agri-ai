import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  
  // Groq API Configuration
  static String get groqApiKey => dotenv.get('GROQ_API_KEY', fallback: '');
  static String get groqModel => dotenv.get('GROQ_MODEL', fallback: 'llama-3.3-70b-versatile');
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  
  // App Configuration
  static const String appName = 'Agri.AI';
  static const String appVersion = '1.0.0';
  
  // Theme Colors
  static const int primaryGreen = 0xFF2E7D32;
  static const int darkGreen = 0xFF1B5E20;
  static const int lightGreen = 0xFF4CAF50;
  static const int accentGreen = 0xFF66BB6A;
  
  // ESP32 Configuration
  static const String esp32ServiceUuid = '00001101-0000-1000-8000-00805F9B34FB';
  static const String esp32CharacteristicUuid = '00001101-0000-1000-8000-00805F9B34FB';
  
  // Paymob Configuration
  static const String paymobApiKey = 'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRFMU1ETXdPU3dpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS5rVFMwNmd3ZDF4VlBQZXdjTDluM1dQZnNVb1NhcFR3c2hma3VxVUdWcEEzRjhuY2F3MFNhcE1JVmZVWks0YnJKT1JkeVUyV3JVaHBEcFlrR29QX2JoZw==';
  static const String paymobIntegrationId = '5604537';
  static const String paymobIframeId = '1029248';
  
  // Firebase Configuration
  static const String firebaseServerKey = 'your-firebase-server-key-here';
  
  // Storage Keys
  static const String userSessionKey = 'user_session';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  
  // API Endpoints
  static const String weatherApiUrl = 'https://api.openweathermap.org/data/2.5';
  static String get weatherApiKey => dotenv.get('WEATHER_API_KEY', fallback: '');
  
  // Plant Disease Detection Model
  static const String plantModelPath = 'assets/models/plant_model.tflite';
  static const String plantLabelsPath = 'assets/models/labels.txt';
  
  // App Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxChatHistory = 100;
  static const int maxProductsInCart = 50;
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration bluetoothTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 15);
}