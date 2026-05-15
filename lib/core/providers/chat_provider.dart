import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:uuid/uuid.dart';
import '../services/groq_service.dart';
import '../services/chat_storage_service.dart';
import '../../features/store/product_service.dart';

final groqServiceProvider = Provider<GroqService>((ref) => GroqService());
final chatStorageServiceProvider = Provider<ChatStorageService>((ref) => ChatStorageService());

class ChatMessage {
  final String id;
  final String chatId;
  final String role;
  final String content;
  final DateTime createdAt;
  final List<Product> recommendedProducts;
  final bool showScannerSuggestion;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.recommendedProducts = const [],
    this.showScannerSuggestion = false,
  });

  bool get isUser => role == 'user';

  String get cleanContent {
    return content
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': chatId,
    'role': role,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'show_scanner_suggestion': showScannerSuggestion,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? const Uuid().v4(),
    chatId: json['chat_id'] ?? '',
    role: json['role'] ?? (json['is_user'] == true ? 'user' : 'assistant'),
    content: json['content'] ?? '',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    recommendedProducts: [],
    showScannerSuggestion: json['show_scanner_suggestion'] ?? false,
  );
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': id, // Alias for older compatibility if needed
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json, [List<ChatMessage> messages = const []]) => ChatSession(
    id: json['id'],
    title: json['title'] ?? 'محادثة جديدة',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    messages: messages,
  );

  ChatSession copyWith({String? title, List<ChatMessage>? messages, DateTime? updatedAt}) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class ChatState {
  final List<ChatSession> sessions;
  final String? activeSessionId;
  final bool isLoading;
  final String streamingResponse;
  final List<Product> pendingRecommendations;

  ChatState({
    required this.sessions,
    this.activeSessionId,
    this.isLoading = false,
    this.streamingResponse = '',
    this.pendingRecommendations = const [],
  });

  ChatSession? get activeSession {
    if (activeSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == activeSessionId);
    } catch (_) {
      return null;
    }
  }

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? streamingResponse,
    List<Product>? pendingRecommendations,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      streamingResponse: streamingResponse ?? this.streamingResponse,
      pendingRecommendations: pendingRecommendations ?? this.pendingRecommendations,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GroqService _groqService;
  final ChatStorageService _storageService;
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  ChatNotifier(this._groqService, this._storageService) 
      : super(ChatState(sessions: [])) {
    _init();
  }

  Future<void> _init() async {
    final localSessions = await _storageService.loadChats();
    if (localSessions.isNotEmpty) {
      state = state.copyWith(sessions: localSessions, activeSessionId: localSessions.first.id);
    }
    await syncWithSupabase();
  }

  Future<void> syncWithSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final chatsResponse = await _supabase.from('chats').select().order('updated_at', ascending: false);
      List<ChatSession> remoteSessions = [];
      for (var chatJson in chatsResponse) {
        final messagesResponse = await _supabase.from('messages').select().eq('chat_id', chatJson['id']).order('created_at', ascending: true);
        final messages = (messagesResponse as List).map((m) => ChatMessage.fromJson(m)).toList();
        remoteSessions.add(ChatSession.fromJson(chatJson, messages));
      }
      if (remoteSessions.isNotEmpty) {
        state = state.copyWith(sessions: remoteSessions, activeSessionId: state.activeSessionId ?? remoteSessions.first.id);
        _saveLocal();
      }
    } catch (e) {
      print('Supabase Sync Error: $e');
    }
  }

  void createNewChat() async {
    final id = _uuid.v4();
    final newSession = ChatSession(
      id: id,
      title: 'محادثة جديدة',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          chatId: id,
          role: 'assistant',
          content: 'مرحباً! أنا المساعد الذكي، كيف يمكنني مساعدتك اليوم؟',
          createdAt: DateTime.now(),
        ),
      ],
    );
    state = state.copyWith(sessions: [newSession, ...state.sessions], activeSessionId: newSession.id, streamingResponse: '');
    _saveLocal();
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('chats').insert({'id': newSession.id, 'title': newSession.title, 'user_id': user.id, 'created_at': newSession.createdAt.toIso8601String(), 'updated_at': newSession.updatedAt.toIso8601String()});
        await _supabase.from('messages').insert(newSession.messages.first.toJson());
      } catch (e) {
        print('Supabase Save Error: $e');
      }
    }
  }

  void setActiveSession(String id) {
    state = state.copyWith(activeSessionId: id, streamingResponse: '', pendingRecommendations: []);
  }

  void deleteSession(String id) async {
    final newSessions = state.sessions.where((s) => s.id != id).toList();
    String? newActiveId = state.activeSessionId;
    if (id == state.activeSessionId) {
      newActiveId = newSessions.isNotEmpty ? newSessions.first.id : null;
    }
    state = state.copyWith(sessions: newSessions, activeSessionId: newActiveId);
    if (newSessions.isEmpty) createNewChat();
    _saveLocal();
    try {
      await _supabase.from('chats').delete().eq('id', id);
    } catch (e) {
      print('Supabase Delete Error: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;
    
    final currentSession = state.activeSession;
    if (currentSession == null) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      chatId: currentSession.id,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...currentSession.messages, userMessage];
    _updateActiveSession(messages: updatedMessages, updatedAt: DateTime.now());
    state = state.copyWith(isLoading: true, streamingResponse: '', pendingRecommendations: []);

    _saveMessageToSupabase(userMessage);

    try {
      if (currentSession.messages.length == 1) {
        final words = text.split(' ');
        final title = words.length > 5 ? '${words.take(5).join(' ')}...' : text;
        _updateActiveSession(title: title);
        _updateChatTitleInSupabase(currentSession.id, title);
      }

      final historyMap = updatedMessages.map((m) => {'role': m.role, 'content': m.content}).toList();
      
      String diagnosis = '';
      await for (final chunk in _groqService.getChatResponseStream("قدم تشخيصاً مختصراً جداً (كلمات مفتاحية) للمشكلة التالية: $text", historyMap.sublist(0, historyMap.length - 1))) {
        diagnosis += chunk;
      }

      final relevantProducts = await _searchRelevantProducts(diagnosis + " " + text);
      state = state.copyWith(pendingRecommendations: relevantProducts);

      // Visual Problem Detection
      final visualKeywords = ['أوراق', 'ورق', 'ورقة', 'اصفرار', 'تحول اللون', 'بقع', 'مرض', 'عفن', 'تلف', 'حشرات', 'شكل غريب', 'تشوه', 'لون', 'مظهر'];
      bool isVisualProblem = visualKeywords.any((kw) => text.contains(kw) || diagnosis.contains(kw));

      String productContext = '';
      if (relevantProducts.isNotEmpty) {
        productContext = "\n\nالمنتجات المتاحة في متجرنا التي تناسب هذه المشكلة:\n" + 
            relevantProducts.map((p) => "- ${p.name}: ${p.description} - السعر: ${p.price} جنيه").join('\n');
      }

      String systemHint = "\n\n[تعليق النظام: يرجى التوصية بالمنتجات التالية بشكل طبيعي في إجابتك: $productContext]";
      if (isVisualProblem) {
        systemHint += "\nأيضاً، اقترح على المستخدم استخدام ميزة 'فحص النبات' في التطبيق للحصول على تشخيص أدق بالصورة.";
      }

      final finalPrompt = text + systemHint;

      String fullResponse = '';
      await for (final chunk in _groqService.getChatResponseStream(finalPrompt, historyMap.sublist(0, historyMap.length - 1))) {
        fullResponse += chunk;
        state = state.copyWith(streamingResponse: fullResponse);
      }

      final botMessage = ChatMessage(
        id: _uuid.v4(),
        chatId: currentSession.id,
        role: 'assistant',
        content: fullResponse,
        createdAt: DateTime.now(),
        recommendedProducts: relevantProducts,
        showScannerSuggestion: isVisualProblem,
      );

      _updateActiveSession(messages: [...updatedMessages, botMessage], updatedAt: DateTime.now());
      state = state.copyWith(isLoading: false, streamingResponse: '');
      _saveLocal();
      _saveMessageToSupabase(botMessage);
    } catch (e) {
      print('Error in sendMessage: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<Product>> _searchRelevantProducts(String text) async {
    try {
      String? searchKey;
      if (text.contains('نيتروجين') || text.contains('اصفرار') || text.contains('سماد')) {
        searchKey = 'سماد';
      } else if (text.contains('حشرات') || text.contains('آفات') || text.contains('مبيد') || text.contains('ذباب')) {
        searchKey = 'مبيد';
      } else if (text.contains('تربة') || text.contains('جذور') || text.contains('خرطوم')) {
        searchKey = 'تربة';
      } else if (text.contains('بذور') || text.contains('زراعة') || text.contains('شتلات')) {
        searchKey = 'بذور';
      }
      if (searchKey == null) searchKey = text.split(' ').first;

      final response = await _supabase.from('products').select('*').or('description.ilike.%$searchKey%,name.ilike.%$searchKey%').limit(3);
      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      print('Supabase Product Search Error: $e');
      return [];
    }
  }

  Future<void> _saveMessageToSupabase(ChatMessage message) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('messages').insert(message.toJson());
    } catch (e) {
      print('Supabase Message Save Error: $e');
    }
  }

  Future<void> _updateChatTitleInSupabase(String chatId, String title) async {
    try {
      await _supabase.from('chats').update({'title': title}).eq('id', chatId);
    } catch (e) {
      print('Supabase Title Update Error: $e');
    }
  }

  void _updateActiveSession({String? title, List<ChatMessage>? messages, DateTime? updatedAt}) {
    final updatedSessions = state.sessions.map((s) {
      if (s.id == state.activeSessionId) {
        return s.copyWith(title: title, messages: messages, updatedAt: updatedAt);
      }
      return s;
    }).toList();
    state = state.copyWith(sessions: updatedSessions);
  }

  Future<void> _saveLocal() async {
    await _storageService.saveChats(state.sessions);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final groqService = ref.watch(groqServiceProvider);
  final storageService = ref.watch(chatStorageServiceProvider);
  return ChatNotifier(groqService, storageService);
});
