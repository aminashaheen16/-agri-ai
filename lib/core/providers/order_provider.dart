import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final List<dynamic> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String addressId;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.addressId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      items: json['items'] ?? [],
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'received',
      createdAt: DateTime.parse(json['created_at']),
      addressId: json['address_id'].toString(),
    );
  }

  String get statusAr {
    switch (status) {
      case 'received': return 'تم الاستلام';
      case 'preparing': return 'قيد التجهيز';
      case 'out_for_delivery': return 'في الطريق';
      case 'delivered': return 'تم التسليم';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final _supabase = Supabase.instance.client;
  final Ref ref;

  OrderNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      state = AsyncValue.data((data as List).map((e) => OrderModel.fromJson(e)).toList());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> placeOrder({
    required List<Map<String, dynamic>> items,
    required double total,
    required String addressId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final orderNumber = 'AGR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    await _supabase.from('orders').insert({
      'user_id': user.id,
      'items': items,
      'total_price': total,
      'address_id': addressId,
      'status': 'received',
      'order_number': orderNumber,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Notify user
    await ref.read(notificationServiceProvider).addNotification(
      title: 'تم استلام طلبك رقم $orderNumber 🎉',
      body: 'طلبك الآن قيد المراجعة، وسنقوم بإبلاغك فور البدء في تجهيزه.',
      type: 'متجر',
    );

    await loadOrders();
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrderNotifier(ref);
});
