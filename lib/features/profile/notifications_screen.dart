import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final service = ref.read(notificationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('التنبيهات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('لا توجد تنبيهات حالياً', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationCard(context, item, service);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel item, NotificationService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        border: item.isRead ? null : Border.all(color: Colors.green.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: () => service.markAsRead(item.id),
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _getIconColor(item.type).withOpacity(0.1),
          child: Icon(_getIcon(item.type), color: _getIconColor(item.type), size: 20),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.body, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: item.isRead ? null : Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'زراعية': return Icons.eco;
      case 'تنبيه': return Icons.warning_amber_rounded;
      case 'متجر': return Icons.shopping_bag_outlined;
      case 'مساعد': return Icons.robot_2_outlined;
      case 'تقرير': return Icons.bar_chart;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'زراعية': return Colors.green;
      case 'تنبيه': return Colors.orange;
      case 'متجر': return Colors.blue;
      case 'مساعد': return Colors.purple;
      case 'تقرير': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
