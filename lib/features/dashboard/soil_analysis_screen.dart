import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SoilAnalysisScreen extends StatelessWidget {
  const SoilAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('تحليل التربة الذكي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stats Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('أعلى رطوبة', '82%', Icons.water_drop, Colors.blue)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('أدنى رطوبة', '28%', Icons.warning_amber_rounded, Colors.orange)),
              ],
            ),
            const SizedBox(height: 25),

            // Moisture Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('منحنى الرطوبة (آخر ٢٤ ساعة)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const titles = ['12am', '4am', '8am', '12pm', '4pm', '8pm', 'now'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(titles[value.toInt() % titles.length], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeGroupData(0, 40, Colors.green.withOpacity(0.2)),
                          _makeGroupData(1, 30, Colors.green.withOpacity(0.2)),
                          _makeGroupData(2, 60, Colors.green.withOpacity(0.3)),
                          _makeGroupData(3, 85, Colors.green.withOpacity(0.3)),
                          _makeGroupData(4, 70, Colors.green.withOpacity(0.2)),
                          _makeGroupData(5, 50, Colors.green.withOpacity(0.2)),
                          _makeGroupData(6, 65, const Color(0xFF2E7D32)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Weekly Status Report
            const Text('تقرير الحالة الأسبوعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 15),
            _buildStatusItem('معدل الاستهلاك', 'متوسط (٥ لتر/يوم)', Icons.trending_up, Colors.green),
            _buildStatusItem('حالة الصرف', 'جيد جداً', Icons.check_circle_outline, Colors.teal),
            _buildStatusItem('أوقات الجفاف', '٣ مرات هذا الأسبوع', Icons.history, Colors.red),
            const SizedBox(height: 25),

            // Daily Log
            const Text('سجل التغييرات اليومي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 15),
            _buildLogItem('08:00 AM', 'انخفاض الرطوبة لـ 29% (تنبيه جفاف)', Colors.orange),
            _buildLogItem('08:05 AM', 'بدء عملية الري الآلي', Colors.blue),
            _buildLogItem('08:30 AM', 'وصول الرطوبة لـ 75% (إيقاف الري)', Colors.green),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 25,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.black38, fontSize: 12, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.black87, fontFamily: 'Cairo')),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  Widget _buildLogItem(String time, String event, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(time, style: const TextStyle(color: Colors.black38, fontSize: 12)),
          const SizedBox(width: 15),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(event, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo'))),
        ],
      ),
    );
  }
}
