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
import 'package:agri_ai/l10n/app_localizations.dart';
import '../profile/notifications_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hardwareListenerProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.farmStatusGood,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      l10n.weatherStatus,
                      style: const TextStyle(color: Colors.black38, fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF1B5E20), size: 18),
                    Text(settings.language == 'ar' ? ' القاهرة' : ' Cairo', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            weatherAsync.when(
              data: (weather) => _buildWeatherCard(context, weather, ref),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF1B5E20)))),
              error: (err, stack) => _buildWeatherErrorCard(),
            ),
            const SizedBox(height: 20),

            sensorAsync.when(
              data: (sensor) => _buildSoilMoistureCard(context, sensor.moisture, sensor.isPumpOn),
              loading: () => _buildSoilMoistureCard(context, 0.0, false, isLoading: true),
              error: (_, __) => _buildSoilMoistureCard(context, 0.0, false, isError: true),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: weatherAsync.when(
                    data: (w) => _buildSmallSensorCard(context, l10n.weatherStatus, '${w.temp.toStringAsFixed(1)}°C', Icons.thermostat, Colors.orange),
                    loading: () => _buildSmallSensorCard(context, l10n.weatherStatus, '--', Icons.thermostat, Colors.orange),
                    error: (_, __) => _buildSmallSensorCard(context, l10n.weatherStatus, 'N/A', Icons.thermostat, Colors.orange),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: sensorAsync.when(
                    data: (s) => _buildSmallSensorCard(context, l10n.soilMoisture, '${s.moisture.toStringAsFixed(1)}%', Icons.water_drop, Colors.blue),
                    loading: () => _buildSmallSensorCard(context, l10n.soilMoisture, '--', Icons.water_drop, Colors.blue),
                    error: (_, __) => _buildSmallSensorCard(context, l10n.soilMoisture, 'N/A', Icons.water_drop, Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            sensorAsync.when(
              data: (sensor) => _buildIrrigationControlCard(context, sensor.isPumpOn, ref),
              loading: () => _buildIrrigationControlCard(context, false, ref, isLoading: true),
              error: (_, __) => _buildIrrigationControlCard(context, false, ref, isError: true),
            ),
            const SizedBox(height: 30),

            Text(
              l10n.npkNutrients,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 15),
            _buildNPKBar('Nitrogen (N)', 0.45, Colors.purple),
            _buildNPKBar('Phosphorus (P)', 0.30, Colors.orange),
            _buildNPKBar('Potassium (K)', 0.25, Colors.green),
            const SizedBox(height: 20),

            _buildAIRecommendation(context),
            const SizedBox(height: 30),

            _buildScheduleSection(context),
            const SizedBox(height: 15),
            _buildScheduleCardsRow(),
            const SizedBox(height: 19),
            
            _buildDetailedAnalysisButton(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherData weather, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
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
                  Text(settings.language == 'ar' ? weather.description : 'Cloudy / Clear', style: const TextStyle(color: Colors.black38, fontFamily: 'Cairo')),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(settings.language == 'ar' ? 'الرطوبة الجوية' : 'Air Humidity', style: const TextStyle(color: Colors.black38, fontSize: 12, fontFamily: 'Cairo')),
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

  Widget _buildIrrigationControlCard(BuildContext context, bool isPumpOn, WidgetRef ref, {bool isLoading = false, bool isError = false}) {
    final l10n = AppLocalizations.of(context)!;
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
                Text(l10n.irrigationControl, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    isError 
                      ? 'Error connecting to sensors' 
                      : (isLoading 
                          ? 'Loading...' 
                          : (isPumpOn ? 'Irrigation ON - Tap to Stop' : 'Irrigation OFF - Tap to Start')),
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
                  isError ? 'Error' : (isPumpOn ? 'Active' : 'Standby'),
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.smartSchedule, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
            Expanded(child: _buildScheduleCard('Fertilizer', 'Tomorrow - 9:00AM', Icons.opacity, Colors.orange)),
            const SizedBox(width: 15),
            Expanded(child: _buildScheduleCard('Weather', 'Stable Weather', Icons.wb_sunny_outlined, Colors.green)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildScheduleCard('Next Irrigation', 'Today - 6:00PM', Icons.water_drop, Colors.blue)),
            const SizedBox(width: 15),
            Expanded(child: _buildScheduleCard('Alert', 'Light Winds', Icons.warning_amber_rounded, Colors.amber)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedAnalysisButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SoilAnalysisScreen()));
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Text(l10n.detailedAnalysis, style: const TextStyle(color: Colors.black87, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSoilMoistureCard(BuildContext context, double moisture, bool isPumpOn, {bool isLoading = false, bool isError = false}) {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.soilMoistureReal, style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else if (isError)
                const Text('Connection Error', style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'Cairo'))
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
                  isPumpOn ? 'Irrigating now...' : 'Soil condition is stable',
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
                isPumpOn ? 'Active' : 'Standby',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSensorCard(BuildContext context, String title, String value, IconData icon, Color color) {
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

  Widget _buildAIRecommendation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.aiRecommendation, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'We recommend adding light nitrogen fertilizer within the next 48 hours to improve leaf quality.',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
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
            const Text('Notifications History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 10),
            Expanded(
              child: notifications.isEmpty 
                ? const Center(child: Text('No notifications currently', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
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
    );
  }
}

class _AgendaContent extends ConsumerStatefulWidget {
  const _AgendaContent({super.key});

  @override
  ConsumerState<_AgendaContent> createState() => _AgendaContentState();
}

class _AgendaContentState extends ConsumerState<_AgendaContent> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(calendarNotesProvider);
    final isAr = ref.watch(settingsProvider).language == 'ar';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'أجندة المزرعة الذكية' : 'Smart Farm Agenda', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                IconButton(
                  onPressed: () => _showAddNoteSheet(context),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF1B3022), size: 35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: 30,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index - 5));
                final isSelected = date.day == _selectedDay.day && date.month == _selectedDay.month;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1B3022) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isAr ? _getArDay(date.weekday) : _getEnDay(date.weekday),
                          style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 10, fontFamily: 'Cairo'),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (notesAsync.maybeWhen(data: (notes) => notes.any((n) => n.date.day == date.day && n.date.month == date.month), orElse: () => false))
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final dayNotes = notes.where((n) => n.date.day == _selectedDay.day && n.date.month == _selectedDay.month).toList();
                if (dayNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 15),
                        Text(isAr ? 'لا توجد مهام لهذا اليوم' : 'No tasks for this day', 
                          style: TextStyle(color: Colors.grey[400], fontFamily: 'Cairo')),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dayNotes.length,
                  itemBuilder: (context, index) => _buildNoteCard(dayNotes[index], isAr),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(CalendarNote note, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: note.isDone ? Colors.grey : Colors.green, width: 5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Checkbox(
          value: note.isDone,
          onChanged: (val) => ref.read(calendarServiceProvider).toggleDone(note.id, val ?? false),
          activeColor: Colors.green,
        ),
        title: Text(
          note.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            decoration: note.isDone ? TextDecoration.lineThrough : null,
            color: note.isDone ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.details.isNotEmpty)
              Text(note.details, style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Cairo')),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  '${note.reminderTime.hour}:${note.reminderTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => ref.read(calendarServiceProvider).deleteNote(note.id),
        ),
      ),
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    final isAr = ref.read(settingsProvider).language == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isAr ? 'إضافة مهمة جديدة' : 'Add New Task', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: isAr ? 'عنوان المهمة' : 'Task Title',
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(
                  hintText: isAr ? 'التفاصيل (اختياري)' : 'Details (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(isAr ? 'وقت التذكير' : 'Reminder Time', style: const TextStyle(fontFamily: 'Cairo')),
                trailing: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: selectedTime);
                  if (time != null) setSheetState(() => selectedTime = time);
                },
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  final reminder = DateTime(
                    _selectedDay.year,
                    _selectedDay.month,
                    _selectedDay.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  ref.read(calendarServiceProvider).addNote(
                    title: titleController.text,
                    details: detailsController.text,
                    date: _selectedDay,
                    reminderTime: reminder,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: const Color(0xFF1B3022),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(isAr ? 'إضافة' : 'Add', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _getArDay(int day) {
    switch (day) {
      case 1: return 'الاثنين';
      case 2: return 'الثلاثاء';
      case 3: return 'الأربعاء';
      case 4: return 'الخميس';
      case 5: return 'الجمعة';
      case 6: return 'السبت';
      case 7: return 'الأحد';
      default: return '';
    }
  }

  String _getEnDay(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
