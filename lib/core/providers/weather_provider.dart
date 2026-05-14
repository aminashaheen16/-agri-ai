import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) => WeatherService());

final weatherDataProvider = FutureProvider.family<WeatherData, ({double lat, double lon})>((ref, coords) async {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.fetchWeather(coords.lat, coords.lon);
});
