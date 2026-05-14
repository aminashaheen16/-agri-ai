import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class NotificationService {
  final _supabase = Supabase.instance.client;

  Stream<List<NotificationModel>> getNotificationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('notification_log')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => NotificationModel(
              id: item['id'],
              title: item['title'] ?? '',
              body: item['body'] ?? '',
              type: item['type'] ?? 'info',
              isRead: item['is_read'] ?? false,
              createdAt: DateTime.parse(item['created_at']),
            )).toList());
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('notification_log').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
    });
  }

  Future<void> markAsRead(String id) async {
    await _supabase.from('notification_log').update({'is_read': true}).eq('id', id);
  }

  // Added initialize method to satisfy main.dart
  static Future<void> initialize(dynamic plugin) async {
    print("NotificationService initialized");
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).getNotificationsStream();
});