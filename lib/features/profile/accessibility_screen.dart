import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccessibilityScreen extends ConsumerWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isAr = settings.language == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: settings.themeMode == ThemeMode.dark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(isAr ? 'مركز مساعدة ذوي الهمم' : 'Accessibility Center', 
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.plantHealth), // Using a placeholder for Font Size section if needed
            _buildSettingCard(
              settings,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.format_size, size: 20),
                        Expanded(
                          child: Slider(
                            value: settings.fontSizeMultiplier,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            activeColor: Colors.green,
                            onChanged: (val) => notifier.setFontSize(val),
                          ),
                        ),
                        const Icon(Icons.format_size, size: 32),
                      ],
                    ),
                    Text(
                      isAr ? 'اسحب لتغيير حجم الخط في التطبيق' : 'Drag to resize app text',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle(isAr ? 'المظهر والتباين' : 'Appearance & Contrast'),
            _buildSettingCard(
              settings,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
                    title: Text(isAr ? 'الوضع الليلي' : 'Dark Mode', style: const TextStyle(fontFamily: 'Cairo')),
                    value: settings.themeMode == ThemeMode.dark,
                    activeColor: Colors.green,
                    onChanged: (val) => notifier.setThemeMode(val ? ThemeMode.dark : ThemeMode.light),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.contrast, color: Colors.orange),
                    title: Text(isAr ? 'تباين عالٍ' : 'High Contrast', style: const TextStyle(fontFamily: 'Cairo')),
                    value: settings.highContrast,
                    activeColor: Colors.green,
                    onChanged: (val) => notifier.toggleContrast(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle(isAr ? 'خيارات إضافية' : 'Advanced Options'),
            _buildSettingCard(
              settings,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.ads_click, color: Colors.blue),
                    title: Text(isAr ? 'أزرار كبيرة' : 'Large Buttons', style: const TextStyle(fontFamily: 'Cairo')),
                    value: settings.largeButtons,
                    activeColor: Colors.green,
                    onChanged: (val) => notifier.setLargeButtons(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration, color: Colors.teal),
                    title: Text(isAr ? 'الاهتزاز عند اللمس' : 'Touch Vibration', style: const TextStyle(fontFamily: 'Cairo')),
                    value: settings.vibration,
                    activeColor: Colors.green,
                    onChanged: (val) => notifier.setVibration(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_fix_high, color: Colors.purple),
                    title: Text(isAr ? 'واجهة مبسطة' : 'Simplified UI', style: const TextStyle(fontFamily: 'Cairo')),
                    value: settings.simplifiedUI,
                    activeColor: Colors.green,
                    onChanged: (val) => notifier.setSimplifiedUI(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.green),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      isAr 
                        ? 'هذه الإعدادات مصممة لمساعدة ذوي الهمم وضعاف البصر للحصول على تجربة استخدام أفضل.' 
                        : 'These settings are designed to help people with special needs and low vision have a better experience.',
                      style: const TextStyle(fontSize: 13, fontFamily: 'Cairo', color: Colors.green),
                    ),
                  ),
                ],
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

  Widget _buildSettingCard(SettingsState settings, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: settings.themeMode == ThemeMode.dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: settings.highContrast ? Border.all(color: settings.themeMode == ThemeMode.dark ? Colors.white : Colors.black, width: 2) : null,
      ),
      child: child,
    );
  }
}
