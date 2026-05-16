import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'mساعد',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationService {
  final _supabase = Supabase.instance.client;
  static final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localPlugin.initialize(const InitializationSettings(android: android, iOS: ios));
    
    // Request Firebase Permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    
    // Get and Save Token
    _saveDeviceToken();
    
    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      );
    });

    // Schedule Daily Summary
    _scheduleDailySummary();
  }

  static Future<void> _saveDeviceToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      String? token;
      if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        await Supabase.instance.client.from('user_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Token Save Error: $e');
    }
  }

  static Future<void> _showLocalNotification({required String title, required String body}) async {
    const android = AndroidNotificationDetails('agri_ai_channel', 'Agri.AI Notifications', importance: Importance.max, priority: Priority.high);
    const ios = DarwinNotificationDetails();
    await _localPlugin.show(DateTime.now().millisecond, title, body, const NotificationDetails(android: android, iOS: ios));
  }

  static Future<void> _scheduleDailySummary() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localPlugin.zonedSchedule(
      999,
      'ملخص مزرعتك اليوم 🌱',
      'تحقق من مهام الأجندة وحالة الحساسات لبدء يومك بنشاط!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_summary', 'Daily Summary'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => NotificationModel.fromJson(item)).toList());
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
    });
    
    await _showLocalNotification(title: title, body: body);
  }

  Future<void> markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).getNotificationsStream();
});