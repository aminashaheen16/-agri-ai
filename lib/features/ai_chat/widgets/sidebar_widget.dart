import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/chat_provider.dart';

class ChatSidebar extends ConsumerWidget {
  const ChatSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final notifier = ref.read(chatProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFF1F361A),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.psychology, color: Colors.white, size: 35),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'المساعد الذكي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                notifier.createNewChat();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('محادثة جديدة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: chatState.sessions.length,
              itemBuilder: (context, index) {
                final session = chatState.sessions[index];
                final isActive = session.id == chatState.activeSessionId;

                return Dismissible(
                  key: Key(session.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    _confirmDelete(context, ref, session.id);
                    return false; // Let the dialog handle the deletion
                  },
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? const Color(0xFF2E7D32) : null,
                      ),
                    ),
                    selected: isActive,
                    onTap: () {
                      notifier.setActiveSession(session.id);
                      Navigator.pop(context);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _confirmDelete(context, ref, session.id),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Cairo')),
            onTap: () {
              // Navigate to settings if needed
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المحادثة', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذه المحادثة؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).deleteSession(id);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
