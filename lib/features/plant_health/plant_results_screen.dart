import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'dart:typed_data';
import '../../core/services/groq_service.dart';
import '../../features/store/product_service.dart';
import '../ai_chat/widgets/product_card_widget.dart';

class PlantResultsScreen extends ConsumerStatefulWidget {
  final String modelResult;
  final Uint8List imageBytes;

  const PlantResultsScreen({
    super.key,
    required this.modelResult,
    required this.imageBytes,
  });

  @override
  ConsumerState<PlantResultsScreen> createState() => _PlantResultsScreenState();
}

class _PlantResultsScreenState extends ConsumerState<PlantResultsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analysis = {};
  List<Product> _suggestedProducts = [];
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final analysis = await ref.read(groqServiceProvider).getPlantAnalysis(widget.modelResult);
      
      List<Product> products = [];
      if (analysis['status'] == 'warning') {
        final searchKey = analysis['plantName'] ?? widget.modelResult.split(' ').first;
        // Using products_with_price to match the main store's data structure
        final response = await _supabase
            .from('products_with_price')
            .select('*')
            .or('description.ilike.%$searchKey%,name.ilike.%$searchKey%')
            .limit(3);
        products = (response as List).map((p) => Product.fromJson(p)).toList();
      }

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _suggestedProducts = products;
          _isLoading = false;
        });
        _saveToHistory();
      }
    } catch (e) {
      print('Fetch Analysis Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('plant_scans').insert({
        'user_id': user.id,
        'plant_name': _analysis['plantName'] ?? widget.modelResult,
        'status': _analysis['status'] ?? 'unknown',
        'diagnosis': _analysis['diagnosis'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Save History Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FBFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1F361A)),
              const SizedBox(height: 20),
              const Text('جاري إنشاء تقرير مفصل...', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final isHealthy = _analysis['status'] == 'healthy';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('نتائج الفحص الذكي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F361A),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Header Card - Health Status
            _buildHeaderCard(isHealthy),
            const SizedBox(height: 20),

            // 2. Analysis Cards
            _buildSectionCard(
              title: 'التشخيص والتحليل',
              content: _analysis['diagnosis'] ?? '',
              icon: Icons.search_rounded,
              iconColor: Colors.blue,
            ),
            _buildSectionCard(
              title: 'احتياجات الري',
              content: _analysis['watering'] ?? '',
              icon: Icons.water_drop_rounded,
              iconColor: Colors.lightBlue,
            ),
            _buildSectionCard(
              title: 'البيئة والإضاءة',
              content: _analysis['environment'] ?? '',
              icon: Icons.wb_sunny_rounded,
              iconColor: Colors.orange,
            ),
            _buildTipsCard(_analysis['tips'] ?? []),
            _buildSmartCard(
              title: 'توصية السماد',
              badge: 'توصية ذكية',
              content: "${_analysis['fertilizer']?['type'] ?? ''}\nالنسبة: ${_analysis['fertilizer']?['ratio'] ?? ''}\nالسبب: ${_analysis['fertilizer']?['reason'] ?? ''}",
              icon: Icons.edit_note_rounded,
              iconColor: Colors.purple,
              bgColor: const Color(0xFFF3E5F5),
            ),
            _buildSmartCard(
              title: 'حجم القصيص',
              badge: 'توصية ذكية',
              content: _analysis['potSize'] ?? '',
              icon: Icons.eco_rounded,
              iconColor: Colors.purple,
              bgColor: const Color(0xFFF3E5F5),
            ),
            _buildSectionCard(
              title: 'خطة العلاج',
              content: _analysis['treatment'] ?? '',
              icon: Icons.track_changes_rounded,
              iconColor: Colors.red,
            ),

            // 3. Store Products
            if (!isHealthy && _suggestedProducts.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('منتجات مقترحة من متجرنا 🛒', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1F361A))),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestedProducts.length,
                  itemBuilder: (context, index) => ProductRecommendationCard(product: _suggestedProducts[index]),
                ),
              ),
            ],

            const SizedBox(height: 30),
            // 4. Bottom Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F361A),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('تحليل صورة جديدة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isHealthy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(widget.imageBytes, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          Text(
            _analysis['plantName'] ?? widget.modelResult,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isHealthy ? Colors.green.shade200 : Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isHealthy ? Icons.check_circle : Icons.warning_amber_rounded, color: isHealthy ? Colors.green : Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  isHealthy ? 'نبتة صحية' : 'انتبه للزرعة',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: isHealthy ? Colors.green : Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'نوع النبات: ${_analysis['plantName'] ?? widget.modelResult}',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content, required IconData icon, required Color iconColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: Color(0xFF1F361A))),
            ],
          ),
          const Divider(height: 25),
          Text(content, style: const TextStyle(height: 1.6, fontFamily: 'Cairo', fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List<dynamic> tips) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 10),
              Text('نصائح الاهتمام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: Color(0xFF1F361A))),
            ],
          ),
          const Divider(height: 25),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Expanded(child: Text(tip.toString(), style: const TextStyle(height: 1.4, fontFamily: 'Cairo', fontSize: 13, color: Colors.black87))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSmartCard({required String title, required String badge, required String content, required IconData icon, required Color iconColor, required Color bgColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: Color(0xFF1F361A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
            ],
          ),
          const Divider(height: 25, color: Colors.black12),
          Text(content, style: const TextStyle(height: 1.6, fontFamily: 'Cairo', fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}
