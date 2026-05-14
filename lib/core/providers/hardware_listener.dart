import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sensor_service.dart';
import '../services/notification_service.dart';

final hardwareListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<SensorData>>(sensorDataProvider, (previous, next) {
    next.whenData((data) {
      // Check for low moisture
      if (data.moisture < 30.0) {
        // Prevent spamming: only notify if it was previously OK or if it's the first reading
        final prevMoisture = previous?.value?.moisture ?? 100.0;
        if (prevMoisture >= 30.0) {
          ref.read(notificationServiceProvider).sendNotification(
            title: 'تنبيه: رطوبة منخفضة! ⚠️',
            body: 'رطوبة التربة وصلت إلى ${data.moisture.toStringAsFixed(1)}%. يرجى التحقق من حالة الري.',
            type: 'sensor',
          );
        }
      }

      // Check for pump activation
      if (data.isPumpOn) {
        final prevPump = previous?.value?.isPumpOn ?? false;
        if (!prevPump) {
          ref.read(notificationServiceProvider).sendNotification(
            title: 'تنبيه: تم بدء الري 💧',
            body: 'تم تفعيل مضخة الري تلقائياً لتعويض نقص الرطوبة.',
            type: 'sensor',
          );
        }
      }
    });
  });
});
