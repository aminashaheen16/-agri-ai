import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('مركز المساعدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Support Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3022),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.headset_mic_outlined, color: Colors.white, size: 35),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('نحن هنا لمساعدتك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        Text('تواصل معنا أو ابحث في الأسئلة الشائعة لمعرفة المزيد', style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('الأسئلة الشائعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
            const SizedBox(height: 15),
            
            _buildFAQTile('كيف أبدأ في استخدام المحلل الذكي؟', 'يمكنك الضغط على المايكروفون في شاشة المساعد الذكي وسؤاله عن أي بيانات تقرأها حساسات مزرعتك وسيقوم بتحليلها وتقديم التوصيات.'),
            _buildFAQTile('هل يمكنني تعديل أوقات الري؟', 'نعم، من خلال الجدول الذكي في شاشة الداشبورد يمكنك معرفة المواعيد وإضافة ملاحظاتك الخاصة لكل يوم لري المحاصيل.'),
            _buildFAQTile('ماذا لو لم أجد منتج معين في المتجر؟', 'المتجر يتم تحديثه باستمرار، يمكنك التحقق من قسم (قريباً) لمعرفة المنتجات الجاري توفيرها قريباً.'),
            _buildFAQTile('كيف أغير لغة التطبيق؟', 'من شاشة الإعدادات، قسم التفضيلات الزراعية، يمكنك تغيير اللغة بين العربية والإنجليزية.'),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_outlined, color: Colors.white),
              label: const Text('تحدث مع الدعم الفني الآن', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3022),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        childrenPadding: const EdgeInsets.all(15),
        collapsedIconColor: Colors.grey,
        iconColor: const Color(0xFF1B3022),
        shape: const Border(),
        children: [
          Text(answer, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.5, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}
