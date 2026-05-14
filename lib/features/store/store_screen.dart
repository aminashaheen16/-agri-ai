import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'product_service.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/widgets/floating_quick_nav.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsFutureProvider);
    final categoriesAsync = ref.watch(categoriesFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('المتجر الزراعي', 
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F361A),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.refresh(productsFutureProvider),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
          ),
        ],
      ),
      floatingActionButton: const FloatingQuickNav(),
      body: Column(
        children: [
          // Header & Categories
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1F361A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن بذور، تربة، أو معدات...',
                    hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1F361A)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                categoriesAsync.when(
                  data: (categories) => SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(cat, style: TextStyle(fontFamily: 'Cairo', color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
                            selected: isSelected,
                            selectedColor: Colors.green.shade700,
                            backgroundColor: Colors.white,
                            onSelected: (selected) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const SizedBox(height: 40),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCat = _selectedCategory == 'الكل' || p.category == _selectedCategory;
                  return matchesSearch && matchesCat;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات حالياً', style: TextStyle(fontFamily: 'Cairo')));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildProductCard(filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1F361A))),
              error: (err, _) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(
        id: product.id,
        name: product.name,
        price: product.price.toString(),
        image: product.imageUrl!,
        description: product.description,
        rating: product.rating,
      ))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F3EF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Hero(
                      tag: 'prod_${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => const Icon(Icons.shopping_basket, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: Consumer(builder: (context, ref, _) {
                      final isFav = ref.watch(favoritesProvider).contains(product.id);
                      return GestureDetector(
                        onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(product.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 18),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(product.category, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${product.price.toInt()} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F361A), fontSize: 14)),
                      const Icon(Icons.add_circle, color: Color(0xFF1F361A), size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}