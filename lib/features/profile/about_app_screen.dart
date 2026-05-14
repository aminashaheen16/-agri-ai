import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('عن التطبيق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            // Logo & Version
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, size: 50, color: Color(0xFF1B3022)),
                  ),
                  const SizedBox(height: 15),
                  const Text('Agri AI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3022),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('إصدار 1.0.0', style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Agri.AI هو رفيقك الزراعي المتكامل الذي يستخدم أحدث تقنيات الذكاء الاصطناعي لخدمة أرضك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 30),
            
            // Features Detailed List
            _buildDetailedFeature(
              Icons.auto_awesome, 
              'ذكاء اصطناعي (AI)', 
              'نستخدم خوارزميات متقدمة لتحليل حالة نباتاتك من خلال الصور وتوفير تشخيص فوري للأمراض، بالإضافة إلى شات بوت ذكي يجيب على كافة استفساراتك الزراعية بدقة.',
              Colors.purple.shade50,
              Colors.purple
            ),
            _buildDetailedFeature(
              Icons.sensors, 
              'حساسات ذكية (IoT)', 
              'التطبيق متصل بحساسات حقيقية تقيس رطوبة التربة والظروف الجوية لحظة بلحظة، مما يسمح لك بمراقبة مزرعتك عن بعد والتحكم في عمليات الري تلقائياً.',
              Colors.blue.shade50,
              Colors.blue
            ),
            _buildDetailedFeature(
              Icons.calendar_month, 
              'جدول تفاعلي', 
              'نظام جدولة ذكي يساعدك على تنظيم مهامك الزراعية اليومية، من ري وتسميد وحصاد، مع إرسال تنبيهات استباقية لضمان عدم نسيان أي خطوة مهمة.',
              Colors.orange.shade50,
              Colors.orange
            ),
            _buildDetailedFeature(
              Icons.storefront, 
              'متجر زراعي', 
              'سوق متكامل يوفر لك كافة احتياجاتك من بذور، أسمدة، ومعدات زراعية عالية الجودة، مع نظام تقييم شفاف وتوصيل سريع حتى باب مزرعتك.',
              Colors.green.shade50,
              Colors.green
            ),
            
            const SizedBox(height: 40),
            
            // Footer
            const Text('❤️ مطور بكل حب للزراعة الذكية', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
            const Text('Amina Shaheen', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedFeature(IconData icon, String title, String description, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.6, fontFamily: 'Cairo'),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
