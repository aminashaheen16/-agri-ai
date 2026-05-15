import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';

class ChatStorageService {
  static const String _chatsKey = 'ai_chats_history';

  Future<void> saveChats(List<ChatSession> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(chats.map((c) => c.toJson()).toList());
    await prefs.setString(_chatsKey, encoded);
  }

  Future<List<ChatSession>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_chatsKey);
    if (encoded == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((item) => ChatSession.fromJson(item)).toList();
    } catch (e) {
      print('Error loading chats: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatsKey);
  }
}
