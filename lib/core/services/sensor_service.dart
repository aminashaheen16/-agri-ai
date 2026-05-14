import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorData {
  final double moisture;
  final bool isPumpOn;
  final DateTime timestamp;

  SensorData({
    required this.moisture,
    required this.isPumpOn,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      moisture: (json['moisture'] as num).toDouble(),
      isPumpOn: (json['pump_on'] ?? false) as bool,
      timestamp: DateTime.parse(json['created_at']),
    );
  }
}

class SensorService {
  final _supabase = Supabase.instance.client;

  Stream<SensorData> getSensorStream() {
    return _supabase
        .from('soil_readings')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(1)
        .map((data) => SensorData.fromJson(data.first));
  }

  Future<void> togglePump(bool status) async {
    // This could send a command back to ESP32 via another table or RPC
    await _supabase.from('commands').insert({'command': 'toggle_pump', 'value': status});
  }
}

final sensorServiceProvider = Provider((ref) => SensorService());

final sensorDataProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(sensorServiceProvider).getSensorStream();
});
