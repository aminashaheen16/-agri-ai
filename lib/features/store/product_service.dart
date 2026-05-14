import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String category;
  final double rating;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.rating = 4.5,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    String cat = 'عام';

    // تطبيق منطق التصنيف الذكي من النسخة القديمة
    final lowerName = name.toLowerCase();
    if (lowerName.contains('بذور') || lowerName.contains('seed')) {
      cat = 'بذور';
    } else if (lowerName.contains('أداة') || lowerName.contains('أدوات') || lowerName.contains('حوض') || lowerName.contains('اصيص') || lowerName.contains('معدات') || lowerName.contains('tool') || lowerName.contains('pot')) {
      cat = 'معدات';
    } else if (lowerName.contains('تربة') || lowerName.contains('soil') || lowerName.contains('stones') || lowerName.contains('أحجار')) {
      cat = 'تربة';
    } else if (lowerName.contains('سماد') || lowerName.contains('fertilizer') || lowerName.contains('أسمدة')) {
      cat = 'أسمدة';
    } else if (lowerName.contains('مبيد') || lowerName.contains('pesticide')) {
      cat = 'مبيدات';
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: name,
      description: json['description'] ?? 'لا يوجد وصف متاح.',
      price: double.tryParse(json['price_egp']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] ?? json['image'] ?? 'https://via.placeholder.com/150',
      category: cat,
      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
    );
  }
}

class ProductService {
  final _supabase = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _supabase
          .from('products_with_price')
          .select()
          .limit(1000); 
      
      final List data = response as List;
      return data.map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<String>> fetchCategories() async {
    return ['الكل', 'بذور', 'أسمدة', 'تربة', 'معدات', 'مبيدات', 'عام'];
  }
}

final productServiceProvider = Provider((ref) => ProductService());

final productsFutureProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productServiceProvider).fetchProducts();
});

final categoriesFutureProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(productServiceProvider).fetchCategories();
});
