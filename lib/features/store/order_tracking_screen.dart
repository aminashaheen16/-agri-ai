import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/order_provider.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('متابعة الطلبات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('لا يوجد طلبات سابقة', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status, order.statusAr),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 10),
                Text('عدد المنتجات: ${order.items.length}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                const Spacer(),
                Text('${order.totalPrice.toStringAsFixed(1)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3022))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextButton(
              onPressed: () => _showOrderDetails(context, order),
              child: const Text('عرض التفاصيل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String statusAr) {
    Color color;
    switch (status) {
      case 'received': color = Colors.orange; break;
      case 'preparing': color = Colors.blue; break;
      case 'out_for_delivery': color = Colors.purple; break;
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(statusAr, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تفاصيل الطلب ${order.orderNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            _buildTimeline(order.status),
            const SizedBox(height: 30),
            const Text('المنتجات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: item['image_url'] != null ? Image.network(item['image_url']) : const Icon(Icons.image),
                    ),
                    title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text('الكمية: ${item['quantity']}'),
                    trailing: Text('${item['price']} EGP'),
                  );
                },
              ),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي النهائى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                Text('${order.totalPrice.toStringAsFixed(1)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3022))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final statuses = ['received', 'preparing', 'out_for_delivery', 'delivered'];
    final labels = ['تم الاستلام', 'التجهيز', 'في الطريق', 'تم التسليم'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(statuses.length, (index) {
        final isActive = index <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : (isActive ? Colors.green : Colors.grey[300]))),
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.white,
                      border: Border.all(color: isActive ? Colors.green : Colors.grey[300]!, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: isActive ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                  ),
                  Expanded(child: Container(height: 2, color: index == statuses.length - 1 ? Colors.transparent : (index < currentIndex ? Colors.green : Colors.grey[300]))),
                ],
              ),
              const SizedBox(height: 8),
              Text(labels[index], style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.grey, fontFamily: 'Cairo')),
            ],
          ),
        );
      }),
    );
  }
}
