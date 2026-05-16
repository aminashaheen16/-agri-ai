import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../ai_chat/chat_screen.dart';
import '../ai_chat/widgets/product_card_widget.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/notification_service.dart';
import '../../features/store/product_service.dart';
import 'plant_results_screen.dart'; // Import the new results screen

class PlantHealthScreen extends ConsumerStatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  ConsumerState<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends ConsumerState<PlantHealthScreen> {
  Uint8List? _imageBytes;
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResult = false;
  
  String? _detectedDisease;
  String? _aiAnalysis;
  double? _confidence;
  bool _isHealthy = false;
  List<Product> _recommendedProducts = [];

  // API for ML model (FastAPI/Kaggle)
  final String _baseUrl = 'http://localhost:8000'; 
  final _supabase = Supabase.instance.client;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _imageBytes = bytes;
        _isAnalyzing = true;
        _showResult = false;
        _recommendedProducts = [];
      });

      try {
        await _processPlantScan(pickedFile, bytes);
      } catch (e) {
        print('Detailed Scan Processing Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الاتصال بنموذج التحليل: $e', style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _processPlantScan(XFile imageFile, Uint8List bytes) async {
    // 1. Send to ML Model API
    final modelResult = await _analyzeImageWithModel(imageFile, bytes);
    
    // 2. Determine Health Status
    final diseaseName = modelResult['disease'] ?? 'Unknown';
    final isHealthy = diseaseName.toLowerCase().contains('healthy');
    
    // 3. Get AI Explanation from Groq (Existing logic)
    final aiExplanation = await _getAIAnalysis(diseaseName, isHealthy);
    
    // 4. Search Products in Supabase (Existing logic)
    final products = await _searchRelevantProducts(diseaseName);

    // 5. Save to Supabase Storage & Database (Background)
    _saveScanToHistory(imageFile, bytes, diseaseName, aiExplanation, isHealthy);

    // 6. Send notification
    ref.read(notificationServiceProvider).addNotification(
      title: 'اكتمل تحليل النبتة 🌿',
      body: 'تم تحليل نبتتك بنجاح. الحالة: ${isHealthy ? "سليمة" : "تحتاج عناية"}. اضغط لعرض التفاصيل.',
      type: 'زراعية',
    );

    if (mounted) {
      setState(() {
        _detectedDisease = diseaseName;
        _aiAnalysis = aiExplanation;
        _confidence = modelResult['confidence'];
        _isHealthy = isHealthy;
        _recommendedProducts = products;
        _isAnalyzing = false;
        // Navigation to NEW Results Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantResultsScreen(
              modelResult: diseaseName,
              imageBytes: bytes,
            ),
          ),
        );
      });
    }
  }

  Future<Map<String, dynamic>> _analyzeImageWithModel(XFile imageFile, Uint8List bytes) async {
    final url = Uri.parse('$_baseUrl/predict');
    print('🚀 Sending request to Model API: $url');
    
    try {
      final request = http.MultipartRequest('POST', url);
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'plant.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📊 Model API Status: ${response.statusCode}');
      print('📦 Model API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Model API Error: $e');
      rethrow;
    }
  }

  Future<String> _getAIAnalysis(String diseaseName, bool isHealthy) async {
    final prompt = """
    نتيجة تحليل النبتة من النموذج: $diseaseName
    الحالة: ${isHealthy ? "سليمة" : "تحتاج عناية"}
    
    إذا كانت النبتة مريضة أو بها مشكلة:
    - اشرح المشكلة بوضوح
    - اذكر الأسباب المحتملة
    - اقترح العلاج المناسب
    - اذكر طرق الوقاية
    
    إذا كانت النبتة سليمة وصحية:
    - أخبر المستخدم أن النبتة بصحة جيدة
    - اذكر مميزات هذه النبتة
    - اعطِ نصائح للحفاظ على صحتها
    
    أجب باللغة العربية فقط بأسلوب مهني وودود وبدون نجوم أو رموز markdown.
    """;

    return await ref.read(groqServiceProvider).getSingleResponse(prompt);
  }

  Future<List<Product>> _searchRelevantProducts(String diseaseName) async {
    try {
      // Simplified keyword extraction
      String searchKeyword = diseaseName.split(' ').first;
      if (diseaseName.toLowerCase().contains('healthy')) {
        searchKeyword = 'سماد'; // Suggest fertilizers for healthy plants
      }

      final response = await _supabase
          .from('products')
          .select('*')
          .ilike('description', '%$searchKeyword%')
          .limit(3);
      
      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      print('Supabase Product Search Error: $e');
      return [];
    }
  }

  Future<void> _saveScanToHistory(XFile file, Uint8List bytes, String name, String analysis, bool healthy) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Upload Image to Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'scans/${user.id}/$fileName';
      await _supabase.storage.from('plant-scans').uploadBinary(path, bytes);
      final imageUrl = _supabase.storage.from('plant-scans').getPublicUrl(path);

      // 2. Save to Database
      await _supabase.from('plant_scans').insert({
        'user_id': user.id,
        'image_url': imageUrl,
        'plant_name': name,
        'ai_analysis': analysis,
        'is_healthy': healthy,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Save to History Error: $e');
    }
  }

  void _showMockResult() {
    // Logic removed as per user request to show real errors instead of fake results
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('فحص صحة النبات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F361A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildScanUI(), // Only show scanner UI
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: const Text('جاري تحليل النبتة بالذكاء الاصطناعي...', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanUI() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            width: double.infinity,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.green.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: _imageBytes != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 80, color: Colors.green.shade200),
                    const SizedBox(height: 20),
                    const Text('اضغط هنا لتحميل صورة النبات\nالمصابة للفحص', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 16)),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(child: _buildActionBtn('الجاليري', Icons.photo_library, () => _pickImage(ImageSource.gallery), const Color(0xFF2E7D32))),
            const SizedBox(width: 15),
            Expanded(child: _buildActionBtn('الكاميرا', Icons.camera_alt, () => _pickImage(ImageSource.camera), const Color(0xFF1F361A))),
          ],
        ),
      ],
    );
  }

  // Result UI is now handled by the new screen, but we keep the method for safety/compatibility
  Widget _buildResultUI() {
    return const SizedBox.shrink();
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)), Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: valueColor))]);
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, color: Colors.white, size: 20), label: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0));
  }
}