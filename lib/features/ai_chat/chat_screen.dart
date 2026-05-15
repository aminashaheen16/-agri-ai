import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/chat_provider.dart';
import '../plant_health/plant_health_screen.dart';
import 'widgets/sidebar_widget.dart';
import 'widgets/product_card_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final activeSession = chatState.activeSession;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F0A) : const Color(0xFFF9FBFA),
      drawer: const ChatSidebar(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المساعد الذكي',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
            ),
            if (activeSession != null)
              Text(
                activeSession.title,
                style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'Cairo'),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1F361A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: activeSession == null || activeSession.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: activeSession.messages.length + (chatState.streamingResponse.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < activeSession.messages.length) {
                        final message = activeSession.messages[index];
                        final isLastMessage = index == activeSession.messages.length - 1;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChatBubble(message.cleanContent, message.isUser),
                            if (!message.isUser && message.recommendedProducts.isNotEmpty)
                              _buildRecommendationList(message.recommendedProducts),
                            if (!message.isUser && message.showScannerSuggestion)
                              _buildScannerSuggestionCard(),
                            if (isLastMessage && !message.isUser && chatState.isLoading && chatState.pendingRecommendations.isNotEmpty)
                              _buildRecommendationList(chatState.pendingRecommendations),
                          ],
                        );
                      } else {
                        final cleanStreaming = chatState.streamingResponse
                            .replaceAll('**', '').replaceAll('*', '')
                            .replaceAll('##', '').replaceAll('#', '');
                        return _buildChatBubble(cleanStreaming, false, isStreaming: true);
                      }
                    },
                  ),
          ),
          if (chatState.isLoading && chatState.streamingResponse.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
              ),
            ),
          _buildInputArea(chatState.isLoading),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.green.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text(
            'أهلاً بك! أنا المساعد الذكي\nكيف يمكنني مساعدتك اليوم؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Cairo', height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String content, bool isUser, {bool isStreaming = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser 
              ? const Color(0xFF2E7D32) 
              : (isDark ? const Color(0xFF1E291B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
            fontFamily: 'Cairo',
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationList(List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 10, bottom: 5),
          child: Text(
            'المنتجات المقترحة من المتجر:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF2E7D32)),
          ),
        ),
        Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 15),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            itemBuilder: (context, index) => ProductRecommendationCard(product: products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerSuggestionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فحص النبات بالصورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo', color: Color(0xFF1B3022))),
                    Text('احصل على تشخيص دقيق عن طريق رفع صورة نبتتك', style: TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Cairo')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantHealthScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ابدأ الفحص الآن', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E291B) : const Color(0xFFF1F5F1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontFamily: 'Cairo'),
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    hintText: 'اسأل المساعد الذكي...',
                    hintStyle: TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isLoading ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLoading ? Colors.grey : const Color(0xFF2E7D32), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(_messageController.text.trim());
    _messageController.clear();
    _scrollToBottom();
  }
}