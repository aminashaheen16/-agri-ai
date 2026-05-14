import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

// ===== حالة الاتصال بالـ ESP32 =====
enum BluetoothConnectionState { disconnected, connecting, connected, error }

class ESP32Data {
  final double moisture;
  final double temperature;
  final double humidity;
  final double waterLevel;
  final bool isPumpOn;
  final bool isAutoMode;
  final DateTime timestamp;

  ESP32Data({
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
    required this.isPumpOn,
    required this.isAutoMode,
    required this.timestamp,
  });

  // تحليل البيانات القادمة من الـ ESP32 بصيغة JSON
  factory ESP32Data.fromESP32Json(Map<String, dynamic> json) {
    return ESP32Data(
      moisture: double.tryParse(json['moisture']?.toString() ?? '0') ?? 0.0,
      temperature: double.tryParse(json['temp']?.toString() ?? '0') ?? 0.0,
      humidity: double.tryParse(json['humidity']?.toString() ?? '0') ?? 0.0,
      waterLevel: double.tryParse(json['water_level']?.toString() ?? '0') ?? 0.0,
      isPumpOn: json['pump'] == true || json['pump'] == 1 || json['pump'] == 'ON',
      isAutoMode: json['auto'] == true || json['auto'] == 1,
      timestamp: DateTime.now(),
    );
  }

  // قيم افتراضية عند عدم الاتصال
  factory ESP32Data.empty() {
    return ESP32Data(
      moisture: 0.0,
      temperature: 0.0,
      humidity: 0.0,
      waterLevel: 0.0,
      isPumpOn: false,
      isAutoMode: false,
      timestamp: DateTime.now(),
    );
  }
}

// ===== الحالة الكاملة للـ Hardware =====
class HardwareState {
  final BluetoothConnectionState connectionState;
  final ESP32Data data;
  final String? errorMessage;
  final String? connectedDeviceName;

  HardwareState({
    required this.connectionState,
    required this.data,
    this.errorMessage,
    this.connectedDeviceName,
  });

  HardwareState copyWith({
    BluetoothConnectionState? connectionState,
    ESP32Data? data,
    String? errorMessage,
    String? connectedDeviceName,
  }) {
    return HardwareState(
      connectionState: connectionState ?? this.connectionState,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
    );
  }

  bool get isConnected => connectionState == BluetoothConnectionState.connected;
}

// ===== خدمة الاتصال بالـ ESP32 عبر Supabase Real-time =====
// نستخدم Supabase كـ Bridge بين ESP32 والتطبيق
// ESP32 يكتب البيانات → Supabase → التطبيق يقرأها في الوقت الفعلي
class HardwareService {
  final _supabase = Supabase.instance.client;
  StreamSubscription? _sensorSubscription;

  // الاستماع لبيانات السنسورات من Supabase Real-time
  Stream<ESP32Data> getSensorStream() {
    return _supabase
        .from('soil_readings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return ESP32Data.empty();
          final json = data.first;
          return ESP32Data(
            moisture: double.tryParse(json['moisture_level']?.toString() ??
                json['moisture']?.toString() ?? '0') ?? 0.0,
            temperature: double.tryParse(json['temperature']?.toString() ?? '0') ?? 0.0,
            humidity: double.tryParse(json['humidity']?.toString() ?? '0') ?? 0.0,
            waterLevel: double.tryParse(json['water_level']?.toString() ?? '0') ?? 0.0,
            isPumpOn: json['is_pump_on'] == true || json['pump_status'] == 'ON',
            isAutoMode: json['auto_mode'] == true,
            timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
        });
  }

  // إرسال أمر تشغيل/إيقاف المضخة للـ ESP32 عبر جدول commands في Supabase
  Future<bool> togglePump(bool status) async {
    try {
      await _supabase.from('commands').insert({
        'command': status ? 'PUMP_ON' : 'PUMP_OFF',
        'value': status,
        'source': 'app',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Toggle Pump Error: $e');
      return false;
    }
  }

  // تفعيل/إيقاف الوضع التلقائي للري
  Future<bool> setAutoMode(bool enabled) async {
    try {
      await _supabase.from('commands').insert({
        'command': enabled ? 'AUTO_MODE_ON' : 'AUTO_MODE_OFF',
        'value': enabled,
        'source': 'app',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Auto Mode Error: $e');
      return false;
    }
  }

  // حفظ قراءة سنسور يدوياً (للاختبار)
  Future<void> saveManualReading({
    required double moisture,
    required double temperature,
    required double humidity,
  }) async {
    try {
      await _supabase.from('soil_readings').insert({
        'moisture_level': moisture,
        'temperature': temperature,
        'humidity': humidity,
        'is_pump_on': false,
        'source': 'manual',
      });
    } catch (e) {
      print('Save Reading Error: $e');
    }
  }
}

// ===== Providers =====
final hardwareServiceProvider = Provider((ref) => HardwareService());

final hardwareSensorProvider = StreamProvider<ESP32Data>((ref) {
  return ref.watch(hardwareServiceProvider).getSensorStream();
});

// Provider لحالة المضخة مع إمكانية التحكم
final pumpStateProvider = StateProvider<bool>((ref) => false);

// Provider لوضع الري التلقائي
final autoModeProvider = StateProvider<bool>((ref) => false);
