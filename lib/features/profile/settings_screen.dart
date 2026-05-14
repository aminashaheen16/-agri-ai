import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import 'accessibility_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final isAr = settings.language == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings', 
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(isAr ? 'اللغة' : 'Language'),
            _buildSettingCard(
              child: ListTile(
                leading: const Icon(Icons.language, color: Colors.green),
                title: Text(isAr ? 'لغة التطبيق' : 'App Language', style: const TextStyle(fontFamily: 'Cairo')),
                trailing: DropdownButton<String>(
                  value: settings.language,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'ar', child: Text(isAr ? 'العربية' : 'Arabic')),
                    DropdownMenuItem(value: 'en', child: Text(isAr ? 'الإنجليزية' : 'English')),
                  ],
                  onChanged: (val) {
                    if (val != null) notifier.setLanguage(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle(isAr ? 'سهولة الاستخدام' : 'Accessibility'),
            _buildSettingCard(
              child: ListTile(
                leading: const Icon(Icons.accessibility_new, color: Colors.blue),
                title: Text(isAr ? 'مركز مساعدة ذوي الهمم' : 'Accessibility Center', style: const TextStyle(fontFamily: 'Cairo')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilityScreen()));
                },
              ),
            ),
            const SizedBox(height: 25),
            
            _buildSectionTitle(isAr ? 'وحدات القياس' : 'Measurement Units'),
            _buildSettingCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.thermostat, color: Colors.orange),
                    title: Text(isAr ? 'درجة الحرارة' : 'Temperature', style: const TextStyle(fontFamily: 'Cairo')),
                    trailing: DropdownButton<String>(
                      value: settings.tempUnit,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'C', child: Text('Celsius (°C)')),
                        DropdownMenuItem(value: 'F', child: Text('Fahrenheit (°F)')),
                      ],
                      onChanged: (val) {
                        if (val != null) notifier.setTempUnit(val);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.square_foot, color: Colors.blue),
                    title: Text(isAr ? 'وحدة المساحة' : 'Area Unit', style: const TextStyle(fontFamily: 'Cairo')),
                    trailing: DropdownButton<String>(
                      value: settings.areaUnit,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'm2', child: Text(isAr ? 'متر مربع' : 'Sq Meter')),
                        DropdownMenuItem(value: 'acre', child: Text(isAr ? 'فدان / Acre' : 'Acre')),
                      ],
                      onChanged: (val) {
                        if (val != null) notifier.setAreaUnit(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                isAr ? 'Agri.AI v1.0.1 | مطور بكل حب 🌿' : 'Agri.AI v1.0.1 | Made with Love 🌿',
                style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: child,
    );
  }
}
