import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('عن التطبيق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
              ),
              child: const Icon(Icons.eco_rounded, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Agri.AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B3022)),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('Version 1.0.0', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: Text(
                'Agri.AI هو مساعدك الزراعي الذكي المتكامل. نستخدم أحدث تقنيات الذكاء الاصطناعي لمساعدتك في تشخيص أمراض النباتات، مراقبة مزرعتك عن بعد، والحصول على نصائح زراعية دقيقة لتحسين إنتاجك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.black54, height: 1.6),
              ),
            ),

            // Features Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  _buildFeatureCard(Icons.psychology, 'ذكاء اصطناعي'),
                  _buildFeatureCard(Icons.sensors, 'حساسات ذكية'),
                  _buildFeatureCard(Icons.calendar_month, 'جدول تفاعلي'),
                  _buildFeatureCard(Icons.shopping_basket, 'متجر زراعي'),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Text('مطور بكل حب 💚', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            const Text('Amin Shaheen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.green, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
