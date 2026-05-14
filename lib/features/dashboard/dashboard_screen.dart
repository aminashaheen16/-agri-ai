import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/providers/weather_provider.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sensor_service.dart';
import '../../core/services/calendar_service.dart';
import 'soil_analysis_screen.dart';
import '../../core/widgets/floating_quick_nav.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/providers/hardware_listener.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize hardware listener to monitor sensors and send notifications
    ref.watch(hardwareListenerProvider);
    
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    
    final weatherAsync = ref.watch(weatherDataProvider((lat: 30.0444, lon: 31.2357)));
    final sensorAsync = ref.watch(sensorDataProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const Icon(Icons.menu, color: Colors.black),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 28),
                    onPressed: () => _showNotificationsBottomSheet(context, notifications, ref),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const IconButton(icon: Icon(Icons.notifications_none_outlined), onPressed: null),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: const FloatingQuickNav(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مزرعتك في حالة جيدة' : 'Your Farm is Doing Great',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      isAr ? 'الحالة الجوية الآن' : 'Current Weather Status',
                      style: const TextStyle(color: Colors.black38, fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF1B5E20), size: 18),
                    Text(isAr ? ' القاهرة' : ' Cairo', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weather Card (Live Data)
            weatherAsync.when(
              data: (weather) => _buildWeatherCard(weather, ref),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF1B5E20)))),
              error: (err, stack) => _buildWeatherErrorCard(),
            ),
            const SizedBox(height: 20),

            // Soil Moisture Main Card (Live Data)
            sensorAsync.when(
              data: (sensor) => _buildSoilMoistureCard(sensor.moisture, sensor.isPumpOn),
              loading: () => _buildSoilMoistureCard(0.0, false, isLoading: true),
              error: (_, __) => _buildSoilMoistureCard(0.0, false, isError: true),
            ),
            const SizedBox(height: 20),

            // Sensors Grid
            Row(
              children: [
                Expanded(
                  child: weatherAsync.when(
                    data: (w) => _buildSmallSensorCard('حرارة الجو', '${w.temp.toStringAsFixed(1)}°C', Icons.thermostat, Colors.orange),
                    loading: () => _buildSmallSensorCard('حرارة الجو', '--', Icons.thermostat, Colors.orange),
                    error: (_, __) => _buildSmallSensorCard('حرارة الجو', 'N/A', Icons.thermostat, Colors.orange),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: sensorAsync.when(
                    data: (s) => _buildSmallSensorCard('رطوبة التربة', '${s.moisture.toStringAsFixed(1)}%', Icons.water_drop, Colors.blue),
                    loading: () => _buildSmallSensorCard('رطوبة التربة', '--', Icons.water_drop, Colors.blue),
                    error: (_, __) => _buildSmallSensorCard('رطوبة التربة', 'N/A', Icons.water_drop, Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // New Interactive Irrigation Control Card
            sensorAsync.when(
              data: (sensor) => _buildIrrigationControlCard(sensor.isPumpOn, ref),
              loading: () => _buildIrrigationControlCard(false, ref, isLoading: true),
              error: (_, __) => _buildIrrigationControlCard(false, ref, isError: true),
            ),
            const SizedBox(height: 30),

            // NPK Section
            const Text(
              '(NPK) العناصر الغذائية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 15),
            _buildNPKBar('نيتروجين (N)', 0.45, Colors.purple),
            _buildNPKBar('فوسفور (P)', 0.30, Colors.orange),
            _buildNPKBar('بوتاسيوم (K)', 0.25, Colors.green),
            const SizedBox(height: 20),

            const SizedBox(height: 10),
            const SizedBox(height: 30),

            // AI Recommendation
            _buildAIRecommendation(),
            const SizedBox(height: 30),

            // Smart Schedule
            _buildScheduleSection(context),
            const SizedBox(height: 15),
            _buildScheduleCardsRow(),
            const SizedBox(height: 10),

            const SizedBox(height: 20),
            const SizedBox(height: 20),
            
            // Detailed Analysis Button
            _buildDetailedAnalysisButton(context),
            const SizedBox(height: 100), // Bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    final temp = ref.read(settingsProvider.notifier).convertTemp(weather.temp);
    final unit = settings.tempUnit;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                width: 50,
                errorBuilder: (c, e, s) => const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${temp.toStringAsFixed(1)}°$unit', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(isAr ? weather.description : 'Cloudy / Clear', style: const TextStyle(color: Colors.black38, fontFamily: 'Cairo')),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isAr ? 'الرطوبة الجوية' : 'Air Humidity', style: const TextStyle(color: Colors.black38, fontSize: 12, fontFamily: 'Cairo')),
              Text('${weather.humidity}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(25)),
      child: const Center(child: Text('عذراً، تعذر جلب بيانات الطقس', style: TextStyle(color: Colors.red, fontFamily: 'Cairo'))),
    );
  }

  Widget _buildIrrigationControlCard(bool isPumpOn, WidgetRef ref, {bool isLoading = false, bool isError = false}) {
    return GestureDetector(
      onTap: isLoading || isError ? null : () => ref.read(sensorServiceProvider).togglePump(!isPumpOn),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isError 
              ? [Colors.red[400]!, Colors.red[700]!] 
              : (isPumpOn 
                  ? [const Color(0xFF2196F3), const Color(0xFF1976D2)] 
                  : [const Color(0xFF1B3022), const Color(0xFF2C4A35)]),
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (isError ? Colors.red : (isPumpOn ? Colors.blue : Colors.green)).withOpacity(0.3), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('لوحة تحكم الري', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    isError 
                      ? 'خطأ في الاتصال بالحساسات' 
                      : (isLoading 
                          ? 'جاري التحميل...' 
                          : (isPumpOn ? 'الري يعمل الآن - اضغط للإيقاف' : 'الري متوقف - اضغط للبدء')),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: isLoading 
                    ? const SizedBox(width: 35, height: 35, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Icon(
                        isError ? Icons.error_outline : (isPumpOn ? Icons.water_drop : Icons.power_settings_new), 
                        color: Colors.white, 
                        size: 35
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isError ? 'خطأ' : (isPumpOn ? 'نشط' : 'موقف'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('الجدول الذكي للمزرعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined, color: Colors.black54),
          onPressed: () => _showAgendaBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildScheduleCardsRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildScheduleCard('تسميد نيتروجيني', 'غداً - 9:00ص', Icons.opacity, Colors.orange)),
            const SizedBox(width: 15),
            Expanded(child: _buildScheduleCard('جو معتدل', 'طقس مستقر', Icons.wb_sunny_outlined, Colors.green)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildScheduleCard('الري القادم', 'اليوم - 6:00م', Icons.water_drop, Colors.blue)),
            const SizedBox(width: 15),
            Expanded(child: _buildScheduleCard('تنبيه جوي', 'رياح خفيفة', Icons.warning_amber_rounded, Colors.amber)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedAnalysisButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SoilAnalysisScreen()));
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: const BorderSide(color: Colors.black12),
      ),
      child: const Text('عرض التحليل التفصيلي للتربة 📊', style: TextStyle(color: Colors.black87, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSoilMoistureCard(double moisture, bool isPumpOn, {bool isLoading = false, bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isError ? Colors.red[400] : const Color(0xFF4C7B4D),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('رطوبة التربة الحقيقية', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else if (isError)
                const Text('خطأ في الاتصال', style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'Cairo'))
              else
                Text('${moisture.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPumpOn ? 'يتم الري لتعويض النقص' : 'حالة التربة مستقرة',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.water_drop, color: isPumpOn ? Colors.blue[200] : Colors.white, size: 35),
              ),
              const SizedBox(height: 10),
              Text(
                isPumpOn ? 'الري نشط' : 'الري متوقف',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.7)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.black38, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildNPKBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 10),
              const Text('توصية الذكاء الاصطناعي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'يفضل إضافة سماد نيتروجيني خفيف خلال الـ 48 ساعة القادمة لتحسين جودة الأوراق.',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingIrrigationCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الري القادم',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اليوم - 6:00 مساءً',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'تحتاج التربة لترطيب خفيف',
                  style: TextStyle(fontSize: 12, color: Colors.black38, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue, size: 14),
                SizedBox(width: 5),
                Text('6:00م', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertCard(WeatherData weather) {
    bool isLowHumidity = weather.humidity < 30;
    bool isHighWind = weather.windSpeed > 10;
    
    if (!isLowHumidity && !isHighWind) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.07), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_cloudy_outlined, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'تنبيه جوي',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isLowHumidity ? 'رطوبة منخفضة حالياً (${weather.humidity}%)' : 'رياح قوية متوقعة (${weather.windSpeed} م/ث)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 4),
                Text(
                  isLowHumidity ? 'يُنصح بزيادة دورة الري لتعويض الجفاف' : 'تأكد من تأمين البيوت المحمية والمعدات',
                  style: const TextStyle(fontSize: 11, color: Colors.black38, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 15),
          Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
          const Text('لتعزيز نمو الأوراق', style: TextStyle(fontSize: 10, color: Colors.black26, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  void _showAgendaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AgendaContent(),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, List<NotificationModel> notifications, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 20),
            const Text('سجل التنبيهات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 10),
            Expanded(
              child: notifications.isEmpty 
                ? const Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) => _buildNotificationItem(notifications[index], ref),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, WidgetRef ref) {
    IconData icon;
    Color color;
    switch (notification.type) {
      case 'sensor': icon = Icons.sensors; color = Colors.blue; break;
      case 'weather': icon = Icons.wb_sunny; color = Colors.orange; break;
      case 'order': icon = Icons.shopping_bag; color = Colors.green; break;
      default: icon = Icons.notifications; color = Colors.grey;
    }

    return GestureDetector(
      onTap: () => ref.read(notificationServiceProvider).markAsRead(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.grey[50] : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                  Text(notification.body, style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Cairo')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaContent extends ConsumerStatefulWidget {
  const _AgendaContent();

  @override
  ConsumerState<_AgendaContent> createState() => _AgendaContentState();
}

class _AgendaContentState extends ConsumerState<_AgendaContent> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(calendarNotesProvider);
    final isAr = ref.watch(settingsProvider).language == 'ar';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
          const SizedBox(height: 15),
          Text(isAr ? 'أجندة المزرعة الذكية' : 'Smart Farm Agenda', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  // Month Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                        ),
                        Text(
                          '${_focusedDay.year} - ${_focusedDay.month}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                        ),
                      ],
                    ),
                  ),

                  // Custom Calendar Grid
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                      ),
                      itemCount: DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final isSelected = _selectedDay.year == _focusedDay.year && 
                                         _selectedDay.month == _focusedDay.month && 
                                         _selectedDay.day == day;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, day)),
                          onLongPress: () {
                            setState(() => _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, day));
                            _showAddNoteDialog(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1B3022) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('$day', style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black, 
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              )),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'ملاحظات اليوم:' : 'Tasks for Today:', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        IconButton(
                          onPressed: () => _showAddNoteDialog(context),
                          icon: const Icon(Icons.add_circle, color: Color(0xFF1B3022), size: 30),
                        ),
                      ],
                    ),
                  ),
                  
                  notesAsync.when(
                    data: (notes) {
                      final dayNotes = notes.where((n) => 
                        n.scheduledDate.year == _selectedDay.year &&
                        n.scheduledDate.month == _selectedDay.month &&
                        n.scheduledDate.day == _selectedDay.day
                      ).toList();

                      if (dayNotes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(isAr ? 'لا توجد مهام لهذا اليوم' : 'No tasks for this day', 
                            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dayNotes.length,
                        itemBuilder: (context, index) {
                          final note = dayNotes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: const Color(0xFFF1F4F1), borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              children: [
                                const Icon(Icons.push_pin, color: Colors.green, size: 18),
                                const SizedBox(width: 15),
                                Expanded(child: Text(note.title, style: const TextStyle(fontFamily: 'Cairo'))),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => ref.read(calendarServiceProvider).deleteNote(note.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error loading notes')),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3022),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(isAr ? 'إغلاق' : 'Close', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مهمة جديدة', style: TextStyle(fontFamily: 'Cairo')),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'مثلاً: ري قطعة الأرض رقم 5', hintStyle: TextStyle(fontSize: 12)),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await ref.read(calendarServiceProvider).addNote(controller.text, _selectedDay);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ المهمة بنجاح! ✅', style: TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في الحفظ: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3022), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, List<NotificationModel> notifications, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 20),
            const Text('سجل التنبيهات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 10),
            Expanded(
              child: notifications.isEmpty 
                ? const Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) => _buildNotificationItem(notifications[index], ref),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, WidgetRef ref) {
    IconData icon;
    Color color;
    switch (notification.type) {
      case 'sensor': icon = Icons.sensors; color = Colors.blue; break;
      case 'weather': icon = Icons.wb_sunny; color = Colors.orange; break;
      case 'order': icon = Icons.shopping_bag; color = Colors.green; break;
      default: icon = Icons.notifications; color = Colors.grey;
    }

    return GestureDetector(
      onTap: () => ref.read(notificationServiceProvider).markAsRead(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.grey[50] : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: notification.isRead ? Colors.transparent : color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo', color: notification.isRead ? Colors.black54 : Colors.black)),
                  Text(notification.body, style: const TextStyle(fontSize: 12, color: Colors.black38, fontFamily: 'Cairo')),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}