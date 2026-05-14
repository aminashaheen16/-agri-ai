import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/store/product_service.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;

  CartItem({required this.id, required this.product, required this.quantity});
}

class CartService {
  final _supabase = Supabase.instance.client;

  Future<List<CartItem>> getCartItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id);

      return (data as List).map((item) {
        final product = Product(
          id: item['product_id']?.toString() ?? '',
          name: item['product_name'] ?? '',
          price: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          imageUrl: item['image_url'],
          category: 'عام',
        );
        return CartItem(
          id: item['id']?.toString() ?? '',
          product: product,
          quantity: item['quantity'] ?? 1,
        );
      }).toList();
    } catch (e) {
      print('Cart Error: $e');
      return [];
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', product.id)
          .maybeSingle();

      if (existing != null) {
        final newQty = (existing['quantity'] as int) + quantity;
        await _supabase
            .from('cart_items')
            .update({'quantity': newQty})
            .eq('id', existing['id']);
      } else {
        await _supabase.from('cart_items').insert({
          'user_id': user.id,
          'product_id': product.id,
          'quantity': quantity,
          'product_name': product.name,
          'price': product.price,
          'image_url': product.imageUrl,
        });
      }
    } catch (e) {
      print('Cart Error: $e');
    }
  }

  Future<void> removeFromCart(String itemId) async {
    await _supabase.from('cart_items').delete().eq('id', itemId);
  }

  Future<void> clearCart() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('cart_items').delete().eq('user_id', user.id);
  }
}

final cartServiceProvider = Provider((ref) => CartService());

final cartItemsProvider = FutureProvider<List<CartItem>>((ref) async {
  return ref.watch(cartServiceProvider).getCartItems();
});

