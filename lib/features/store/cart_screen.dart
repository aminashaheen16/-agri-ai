import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemsAsync = ref.watch(cartItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('سلة المشتريات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: cartItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('سلة المشتريات فارغة', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          double total = items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildCartItem(item, ref),
                    );
                  },
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي', style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Cairo')),
                        Text('${total.toStringAsFixed(1)} EGP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3022))),
                      ],
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckoutScreen(totalAmount: total)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3022),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('إتمام الشراء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B3022))),
        error: (err, _) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(15)),
            child: Image.network(
              item.product.imageUrl ?? '',
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                Text('${item.product.price} EGP', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Row(
            children: [
              Text('الكمية: ${item.quantity}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              const SizedBox(width: 15),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                onPressed: () => ref.read(cartServiceProvider).removeFromCart(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

