import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarNote {
  final String id;
  final String title;
  final DateTime scheduledDate;
  final String? type;

  CalendarNote({
    required this.id, 
    required this.title, 
    required this.scheduledDate,
    this.type,
  });

  factory CalendarNote.fromJson(Map<String, dynamic> json) {
    return CalendarNote(
      id: json['id'].toString(),
      title: json['title'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] ?? json['created_at']),
      type: json['type'] as String?,
    );
  }
}

class CalendarService {
  final _supabase = Supabase.instance.client;

  Stream<List<CalendarNote>> getNotesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    
    return _supabase
        .from('calendar_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('scheduled_date')
        .map((data) => data.map((json) => CalendarNote.fromJson(json)).toList());
  }

  Future<void> addNote(String title, DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('calendar_notes').insert({
      'user_id': userId,
      'title': title,
      'scheduled_date': date.toIso8601String(),
    });
  }

  Future<void> deleteNote(String id) async {
    await _supabase.from('calendar_notes').delete().eq('id', id);
  }
}

final calendarServiceProvider = Provider((ref) => CalendarService());

final calendarNotesProvider = StreamProvider<List<CalendarNote>>((ref) {
  return ref.watch(calendarServiceProvider).getNotesStream();
});
