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
      // Using the 'cart' table as requested by the user
      final data = await _supabase
          .from('cart')
          .select('*, products(*)')
          .eq('user_id', user.id);

      return (data as List).map((item) {
        final prodData = item['products'];
        final product = Product.fromJson(prodData);
        
        return CartItem(
          id: item['id']?.toString() ?? '',
          product: product,
          quantity: item['quantity'] ?? 1,
        );
      }).toList();
    } catch (e) {
      print('Cart Load Error: $e');
      // Fallback to simpler mapping if join fails
      return [];
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('cart').upsert({
        'user_id': user.id,
        'product_id': product.id,
        'quantity': quantity,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id'); 
      // Note: Assumes a unique constraint on (user_id, product_id) in the 'cart' table
    } catch (e) {
      print('Cart Add Error: $e');
      // Fallback to insert if upsert/unique constraint not ready
      await _supabase.from('cart').insert({
        'user_id': user.id,
        'product_id': product.id,
        'quantity': quantity,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeFromCart(String itemId) async {
    await _supabase.from('cart').delete().eq('id', itemId);
  }

  Future<void> clearCart() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('cart').delete().eq('user_id', user.id);
  }
}

final cartServiceProvider = Provider((ref) => CartService());

final cartItemsProvider = FutureProvider<List<CartItem>>((ref) async {
  return ref.watch(cartServiceProvider).getCartItems();
});
