import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temp;
  final int humidity;
  final String description;
  final String icon;
  final double windSpeed;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final code = current['weather_code'] as int;
    
    return WeatherData(
      temp: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      description: _getWeatherDescription(code),
      icon: _getWeatherIcon(code),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
    );
  }

  static String _getWeatherDescription(int code) {
    if (code == 0) return 'سماء صافية';
    if (code <= 3) return 'غائم جزئياً';
    if (code <= 48) return 'ضباب';
    if (code <= 55) return 'رذاذ خفيف';
    if (code <= 65) return 'أمطار';
    if (code <= 75) return 'ثلوج';
    if (code <= 82) return 'زخات مطر';
    if (code <= 99) return 'عواصف رعدية';
    return 'غير معروف';
  }

  static String _getWeatherIcon(int code) {
    if (code == 0) return '01d';
    if (code <= 3) return '02d';
    if (code <= 65) return '10d';
    return '03d';
  }
}

class WeatherService {
  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
