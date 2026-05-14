import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_service.dart';
import 'product_details_screen.dart';
import '../../core/providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(productsFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('المفضلة ❤️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: productsAsync.when(
        data: (products) {
          final favoriteProducts = products.where((p) => favorites.contains(p.id)).toList();

          if (favoriteProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text('قائمة المفضلة فارغة حالياً', 
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('العودة للمتجر', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  subtitle: Text('${product.price} EGP', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(product.id),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(
                      id: product.id,
                      name: product.name,
                      price: product.price.toString(),
                      image: product.imageUrl!,
                      description: product.description,
                      rating: product.rating,
                    )));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
