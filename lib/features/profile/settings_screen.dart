import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isAr = settings.language == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(isAr ? 'اللغة والوحدات' : 'Language & Units'),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: Text(isAr ? 'لغة التطبيق' : 'App Language', style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<String>(
                value: settings.language,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'ar', child: Text(isAr ? 'العربية' : 'Arabic')),
                  DropdownMenuItem(value: 'en', child: Text(isAr ? 'الإنجليزية' : 'English')),
                ],
                onChanged: (val) => notifier.setLanguage(val!),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.thermostat, color: Colors.orange),
              title: Text(isAr ? 'وحدة الحرارة' : 'Temp Unit', style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<String>(
                value: settings.tempUnit,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'celsius', child: Text(isAr ? 'سليزيوس' : 'Celsius')),
                  DropdownMenuItem(value: 'fahrenheit', child: Text(isAr ? 'فهرنهايت' : 'Fahrenheit')),
                ],
                onChanged: (val) => notifier.setTempUnit(val!),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.square_foot, color: Colors.green),
              title: Text(isAr ? 'وحدة المساحة' : 'Area Unit', style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<String>(
                value: settings.areaUnit,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'sqm', child: Text(isAr ? 'متر مربع' : 'Sq Meter')),
                  DropdownMenuItem(value: 'acre', child: Text(isAr ? 'فدان' : 'Acre')),
                  DropdownMenuItem(value: 'hectare', child: Text(isAr ? 'هكتار' : 'Hectare')),
                ],
                onChanged: (val) => notifier.setAreaUnit(val!),
              ),
            ),
          ]),

          const SizedBox(height: 25),
          _buildSectionTitle(isAr ? 'إعدادات الإشعارات' : 'Notification Settings'),
          _buildSettingCard([
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active, color: Colors.green),
              title: Text(isAr ? 'تنبيهات الأجندة' : 'Agenda Reminders', style: const TextStyle(fontFamily: 'Cairo')),
              value: settings.agendaNotify,
              activeColor: Colors.green,
              onChanged: (val) => notifier.toggleAgendaNotify(val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.sensors, color: Colors.orange),
              title: Text(isAr ? 'تنبيهات الحساسات' : 'Sensor Alerts', style: const TextStyle(fontFamily: 'Cairo')),
              value: settings.sensorNotify,
              activeColor: Colors.green,
              onChanged: (val) => notifier.toggleSensorNotify(val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.shopping_bag, color: Colors.blue),
              title: Text(isAr ? 'تنبيهات المتجر' : 'Store Updates', style: const TextStyle(fontFamily: 'Cairo')),
              value: settings.storeNotify,
              activeColor: Colors.green,
              onChanged: (val) => notifier.toggleStoreNotify(val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.summarize, color: Colors.teal),
              title: Text(isAr ? 'الملخص اليومي' : 'Daily Summary', style: const TextStyle(fontFamily: 'Cairo')),
              value: settings.dailySummaryNotify,
              activeColor: Colors.green,
              onChanged: (val) => notifier.toggleDailySummary(val),
            ),
          ]),

          const SizedBox(height: 25),
          _buildSectionTitle(isAr ? 'الأمان والحساب' : 'Security & Account'),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.redAccent),
              title: Text(isAr ? 'تغيير كلمة المرور' : 'Change Password', style: const TextStyle(fontFamily: 'Cairo')),
              onTap: () => _showPasswordResetDialog(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(isAr ? 'حذف الحساب' : 'Delete Account', style: const TextStyle(fontFamily: 'Cairo', color: Colors.red)),
              onTap: () => _showDeleteConfirmDialog(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: Text(isAr ? 'الإصدار' : 'Version', style: const TextStyle(fontFamily: 'Cairo')),
              trailing: const Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ]),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              isAr ? 'مطور بكل حب بواسطة Amin 💚' : 'Developed with love by Amin 💚',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  void _showPasswordResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرابط بنجاح', style: TextStyle(fontFamily: 'Cairo'))));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
        content: const Text('هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).deleteAccount();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
