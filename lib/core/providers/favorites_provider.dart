import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  final _supabase = Supabase.instance.client;

  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', user.id);
      
      final ids = (response as List).map((item) => item['product_id'].toString()).toList();
      state = ids;
    } catch (e) {
      print('Load Favorites Error: $e');
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (state.contains(productId)) {
      // إزالة من المفضلة
      state = state.where((id) => id != productId).toList();
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    } else {
      // إضافة للمفضلة
      state = [...state, productId];
      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'product_id': productId,
      });
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});
