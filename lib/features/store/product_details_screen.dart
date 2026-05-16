import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../core/services/cart_service.dart';
import 'product_service.dart';
import '../../core/providers/favorites_provider.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String id;
  final String name;
  final String price;
  final String image;
  final String? description;
  final double rating;

  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.description,
    this.rating = 0.0, // Default to 0.0 as requested
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int quantity = 1;
  bool _isAdding = false;
  int _userRating = 0;
  double _averageRating = 0.0;
  int _ratingCount = 0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _averageRating = widget.rating;
    _loadProductRatings();
  }

  Future<void> _loadProductRatings() async {
    try {
      final response = await _supabase
          .from('product_ratings')
          .select('rating')
          .eq('product_id', widget.id);
      
      if (response != null && (response as List).isNotEmpty) {
        final ratings = response as List;
        final sum = ratings.fold<double>(0, (prev, element) => prev + (element['rating'] as num).toDouble());
        setState(() {
          _averageRating = sum / ratings.length;
          _ratingCount = ratings.length;
        });
      }

      // Load current user's rating if any
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userRatingRes = await _supabase
            .from('product_ratings')
            .select('rating')
            .eq('product_id', widget.id)
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (userRatingRes != null) {
          setState(() {
            _userRating = userRatingRes['rating'];
          });
        }
      }
    } catch (e) {
      print('Load Ratings Error: $e');
    }
  }

  Future<void> _submitRating(int rating) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول للتقييم', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    try {
      await _supabase.from('product_ratings').upsert({
        'user_id': user.id,
        'product_id': widget.id,
        'rating': rating,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        setState(() => _userRating = rating);
        _loadProductRatings(); // Refresh average
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('شكراً لتقييمك بـ $rating نجوم! ⭐', style: const TextStyle(fontFamily: 'Cairo')))
        );
      }
    } catch (e) {
      print('Submit Rating Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final favorites = ref.watch(favoritesProvider);
              final isFav = favorites.contains(widget.id);
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, 
                  color: isFav ? Colors.red : Colors.black),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(widget.id);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 350,
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Image.network(
                  widget.image,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            const SizedBox(width: 5),
                            Text(_averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (_ratingCount > 0)
                              Text(' ($_ratingCount)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Text('المنتجات الزراعية', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
                  const SizedBox(height: 25),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.price} EGP',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B3022)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            IconButton(onPressed: () => setState(() => quantity > 1 ? quantity-- : null), icon: const Icon(Icons.remove, size: 18)),
                            Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add, size: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  const Text('قيم المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  Row(
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        onPressed: () => _submitRating(starIndex),
                        icon: Icon(
                          _userRating >= starIndex ? Icons.star : Icons.star_border, 
                          color: Colors.orange, 
                          size: 28
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 25),
                  const Text('وصف المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  Text(
                    widget.description ?? 'هذا المنتج مصنوع من خامات عالية الجودة ومناسب جداً لجميع أنواع النباتات المنزلية.',
                    style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _handleAddToCart(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _isAdding ? null : _handleAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3022),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isAdding 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('إضافة إلى السلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      final product = Product(
        id: widget.id,
        name: widget.name,
        price: double.tryParse(widget.price.replaceAll(',', '')) ?? 0.0,
        imageUrl: widget.image,
        category: 'عام',
      );
      await ref.read(cartServiceProvider).addToCart(product, quantity: quantity);
      ref.invalidate(cartItemsProvider);
      
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المنتج للسلة بنجاح ✅', style: TextStyle(fontFamily: 'Cairo'))),
        );
        // Navigate to cart screen as requested
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإضافة: $e', style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }
}
