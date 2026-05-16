import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class CalendarNote {
  final String id;
  final String title;
  final String details;
  final DateTime date;
  final DateTime reminderTime;
  final bool isDone;

  CalendarNote({
    required this.id, 
    required this.title, 
    required this.details,
    required this.date,
    required this.reminderTime,
    required this.isDone,
  });

  factory CalendarNote.fromJson(Map<String, dynamic> json) {
    return CalendarNote(
      id: json['id'].toString(),
      title: json['title'] as String,
      details: json['details'] ?? '',
      date: DateTime.parse(json['date']),
      reminderTime: DateTime.parse(json['reminder_time']),
      isDone: json['is_done'] ?? false,
    );
  }

  Map<String, dynamic> toJson(String userId) => {
    'user_id': userId,
    'title': title,
    'details': details,
    'date': date.toIso8601String(),
    'reminder_time': reminderTime.toIso8601String(),
    'is_done': isDone,
    'created_at': DateTime.now().toIso8601String(),
  };
}

class CalendarService {
  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  CalendarService() {
    tz.initializeTimeZones();
  }

  Stream<List<CalendarNote>> getNotesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    
    return _supabase
        .from('farm_agenda')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date')
        .map((data) => data.map((json) => CalendarNote.fromJson(json)).toList());
  }

  Future<void> addNote({
    required String title,
    required String details,
    required DateTime date,
    required DateTime reminderTime,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _supabase.from('farm_agenda').insert({
      'user_id': userId,
      'title': title,
      'details': details,
      'date': date.toIso8601String(),
      'reminder_time': reminderTime.toIso8601String(),
      'is_done': false,
      'created_at': DateTime.now().toIso8601String()
    }).select().single();

    final note = CalendarNote.fromJson(response);
    await _scheduleNotification(note);
  }

  Future<void> toggleDone(String id, bool isDone) async {
    await _supabase.from('farm_agenda').update({'is_done': isDone}).eq('id', id);
  }

  Future<void> deleteNote(String id) async {
    await _supabase.from('farm_agenda').delete().eq('id', id);
    await _notificationsPlugin.cancel(int.parse(id.hashCode.toString().substring(0, 8)));
  }

  Future<void> _scheduleNotification(CalendarNote note) async {
    final scheduledTime = tz.TZDateTime.from(note.reminderTime, tz.local);
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'farm_agenda_channel',
      'Farm Agenda Reminders',
      channelDescription: 'Notifications for your smart farm schedule',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      note.id.hashCode.abs() % 1000000,
      'تذكير من أجندة المزرعة 🌱',
      '${note.title}\n${note.details}',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

final calendarServiceProvider = Provider((ref) => CalendarService());

final calendarNotesProvider = StreamProvider<List<CalendarNote>>((ref) {
  return ref.watch(calendarServiceProvider).getNotesStream();
});
