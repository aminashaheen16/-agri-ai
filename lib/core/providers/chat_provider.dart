import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../services/groq_service.dart';
import '../constants/app_constants.dart';

final groqServiceProvider = Provider<GroqService>((ref) {
  return GroqService();
});

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.content, required this.isUser, required this.timestamp});

  Map<String, dynamic> toJson(String sessionId) {
    return {
      'session_id': sessionId,
      'content': content,
      'is_user': isUser,
      'created_at': timestamp.toIso8601String(),
    };
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String conversationTitle;
  final String? currentSessionId;

  ChatState({
    required this.messages,
    required this.isLoading,
    this.conversationTitle = 'المساعد الذكي',
    this.currentSessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? conversationTitle,
    String? currentSessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GroqService _groqService;
  final _supabase = Supabase.instance.client;
  bool _titleGenerated = false;

  ChatNotifier(this._groqService)
      : super(ChatState(messages: [], isLoading: false)) {
    _initChat();
  }

  Future<void> _initChat() async {
    if (state.isLoading) return;
    
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final sessionResponse = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (sessionResponse != null) {
        final sessionId = sessionResponse['id'];
        final title = sessionResponse['title'] ?? 'المساعد الذكي';
        
        // Load messages
        final messagesResponse = await _supabase
            .from('chat_messages')
            .select()
            .eq('session_id', sessionId)
            .order('created_at', ascending: true);

        final loadedMessages = (messagesResponse as List).map((m) {
          return ChatMessage(
            content: m['content'],
            isUser: m['is_user'],
            timestamp: DateTime.parse(m['created_at']),
          );
        }).toList();

        state = state.copyWith(
          messages: loadedMessages,
          currentSessionId: sessionId,
          conversationTitle: title,
          isLoading: false,
        );
        _titleGenerated = true;
      } else {
        // No session found, start fresh
        clearChat();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      clearChat();
    }
  }

  List<Map<String, String>> _buildHistory() {
    return state.messages.map((m) {
      return {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.content,
      };
    }).toList();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Create session if not exists
    String? sessionId = state.currentSessionId;
    if (sessionId == null) {
      final newSession = await _supabase.from('chat_sessions').insert({
        'user_id': userId,
        'title': 'محادثة جديدة',
      }).select().single();
      sessionId = newSession['id'];
      state = state.copyWith(currentSessionId: sessionId);
    }

    final userMessage = ChatMessage(
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Save user message to Supabase
    await _supabase.from('chat_messages').insert(userMessage.toJson(sessionId!));

    final history = _buildHistory();
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final response = await _groqService.getChatResponse(text, history);
      final botMessage = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Save bot response to Supabase
      await _supabase.from('chat_messages').insert(botMessage.toJson(sessionId));

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );

      if (!_titleGenerated) {
        _titleGenerated = true;
        final title = await _groqService.generateTitle(text);
        await _supabase.from('chat_sessions').update({'title': title}).eq('id', sessionId);
        state = state.copyWith(conversationTitle: title);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      final errorMessage = ChatMessage(
        content: 'عذراً، واجهت مشكلة في الاتصال بالذكاء الاصطناعي. يرجى المحاولة مرة أخرى لاحقاً. ⚠️',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errorMessage]);
    }
  }

  void clearChat() async {
    _titleGenerated = false;
    state = ChatState(
      messages: [
        ChatMessage(
          content: 'مرحباً بك في مساعد Agri.AI الذكي! 🌿\nكيف يمكنني مساعدتك اليوم؟',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      conversationTitle: 'المساعد الذكي',
      currentSessionId: null,
    );
  }

  void refreshChat() {
    _initChat();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final groqService = ref.watch(groqServiceProvider);
  return ChatNotifier(groqService);
});
