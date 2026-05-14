import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  Uint8List? _imageBytes;
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResult = false;
  String? _detectedDisease;
  String? _treatmentReport;
  double? _confidence;

  // Change this to your server IP when running FastAPI
  final String _baseUrl = 'http://localhost:8000'; 

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _imageBytes = bytes;
        _isAnalyzing = true;
        _showResult = false;
      });

      try {
        await _analyzeImage(pickedFile, bytes);
      } catch (e) {
        // Mock fallback if server is not running
        await Future.delayed(const Duration(seconds: 2));
        _showMockResult();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تنبيه: السيرفر غير متصل، تم عرض نتيجة تجريبية', 
              style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  void _showMockResult() {
    setState(() {
      _detectedDisease = 'تبقع الأوراق البكتيري (Bacterial Spot)';
      _confidence = 0.92;
      _treatmentReport = '1. قم بإزالة الأوراق المصابة فوراً.\n2. تجنب الري العلوي (فوق الأوراق).\n3. استخدم مبيداً فطرياً يحتوي على النحاس.';
      _isAnalyzing = false;
      _showResult = true;
    });
  }

  Future<void> _analyzeImage(XFile imageFile, Uint8List bytes) async {
    // If we're on web, we might have CORS issues with localhost if not configured
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/predict'));
    
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'plant.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        _detectedDisease = result['disease'];
        _confidence = result['confidence'];
        _treatmentReport = result['treatment_report'];
        _isAnalyzing = false;
        _showResult = true;
      });
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('فحص صحة النبات', 
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (!_showResult) _buildScanUI() else _buildResultUI(),
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
                      child: const Text('جاري تحليل الصورة بالذكاء الاصطناعي...', 
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              border: Border.all(color: Colors.green.withOpacity(0.1)),
            ),
            child: _imageBytes != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 80, color: Colors.green.shade200),
                    const SizedBox(height: 20),
                    const Text(
                      'اضغط هنا لتحميل صورة النبات\nالمصابة للفحص',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 16),
                    ),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(child: _buildActionBtn('الجاليري', Icons.photo_library, () => _pickImage(ImageSource.gallery), Colors.green.shade700)),
            const SizedBox(width: 15),
            Expanded(child: _buildActionBtn('الكاميرا', Icons.camera_alt, () => _pickImage(ImageSource.camera), Colors.green.shade500)),
          ],
        ),
        const SizedBox(height: 40),
        _buildTipsSection(),
      ],
    );
  }

  Widget _buildResultUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: _imageBytes != null ? Image.memory(_imageBytes!, fit: BoxFit.cover) : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 25),
        
        // Result Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text('تحليل الذكاء الاصطناعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
                ],
              ),
              const Divider(height: 30),
              _buildResultRow('الحالة المكتشفة:', _detectedDisease ?? 'غير معروف', Colors.red.shade700),
              const SizedBox(height: 10),
              _buildResultRow('نسبة التأكد:', '${((_confidence ?? 0) * 100).toStringAsFixed(1)}%', Colors.blue.shade700),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Treatment Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.medication_liquid, color: Colors.green),
                  SizedBox(width: 10),
                  Text('خطة العلاج المقترحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                ],
              ),
              const SizedBox(height: 15),
              Text(_treatmentReport ?? 'لا يوجد تقرير متاح.', style: const TextStyle(height: 1.6, fontFamily: 'Cairo')),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _showResult = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade800,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('فحص نبات آخر', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16)),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 نصائح لفحص دقيق:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 15),
          _buildTipItem(Icons.light_mode_outlined, 'تأكد من وجود إضاءة جيدة عند التصوير'),
          _buildTipItem(Icons.center_focus_strong_outlined, 'اجعل الإصابة في منتصف الصورة'),
          _buildTipItem(Icons.cleaning_services_outlined, 'نظف عدسة الكاميرا قبل التصوير'),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'Cairo'))),
        ],
      ),
    );
  }
}