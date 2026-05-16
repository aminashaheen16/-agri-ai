import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sensor_service.dart';
import '../services/notification_service.dart';

final hardwareListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<SensorData>>(sensorDataProvider, (previous, next) {
    next.whenData((data) {
      final service = ref.read(notificationServiceProvider);

      // Check for low moisture
      if (data.moisture < 30.0) {
        final prevMoisture = previous?.value?.moisture ?? 100.0;
        if (prevMoisture >= 30.0) {
          service.addNotification(
            title: 'تنبيه: رطوبة منخفضة! ⚠️',
            body: 'رطوبة التربة وصلت إلى ${data.moisture.toStringAsFixed(1)}%. يرجى التحقق من حالة الري.',
            type: 'تنبيه',
          );
        }
      }

      // Check for pump activation
      if (data.isPumpOn) {
        final prevPump = previous?.value?.isPumpOn ?? false;
        if (!prevPump) {
          service.addNotification(
            title: 'تنبيه: تم بدء الري 💧',
            body: 'تم تفعيل مضخة الري تلقائياً لتعويض نقص الرطوبة.',
            type: 'زراعية',
          );
        }
      }

      // Check for low potassium (25% warning mentioned in request)
      if (data.potassium < 25.0) {
        final prevK = previous?.value?.potassium ?? 100.0;
        if (prevK >= 25.0) {
          service.addNotification(
            title: 'تنبيه: نقص بوتاسيوم! 📊',
            body: 'مستوى البوتاسيوم منخفض جداً (${data.potassium.toStringAsFixed(1)}%). نوصي بإضافة سماد مناسب.',
            type: 'تنبيه',
          );
        }
      }
    });
  });
});
