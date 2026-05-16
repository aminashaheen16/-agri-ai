import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/cart_service.dart';
import '../../store/cart_screen.dart';
import '../../store/favorites_screen.dart';
import '../../profile/about_app_screen.dart';
import '../../profile/settings_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatSidebar extends ConsumerWidget {
  const ChatSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final notifier = ref.read(chatProvider.notifier);
    final favorites = ref.watch(favoritesProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);
    final profile = ref.watch(profileProvider);
    
    final cartCount = cartItemsAsync.when(
      data: (items) => items.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Drawer(
      child: Column(
        children: [
          // Profile Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1B3022)),
            currentAccountPicture: GestureDetector(
              onTap: () => _showEditProfileDialog(context, ref),
              child: CircleAvatar(
                backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                backgroundColor: Colors.green[700],
                child: profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
              ),
            ),
            accountName: Text(profile?.fullName ?? 'مستخدم Agri.AI', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            accountEmail: Text(profile?.email ?? '', style: const TextStyle(fontSize: 12, opacity: 0.8)),
            onDetailsPressed: () => _showEditProfileDialog(context, ref),
          ),
          
          // Navigation Section
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            title: Text(AppLocalizations.of(context)!.cart, style: const TextStyle(fontFamily: 'Cairo')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
            },
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.favorite_border),
                if (favorites.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('${favorites.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            title: Text(AppLocalizations.of(context)!.favorites, style: const TextStyle(fontFamily: 'Cairo')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
            },
          ),
          
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                notifier.createNewChat();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.newChat, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('المحادثات السابقة', style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: chatState.sessions.length,
              itemBuilder: (context, index) {
                final session = chatState.sessions[index];
                final isActive = session.id == chatState.activeSessionId;

                return ListTile(
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
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontFamily: 'Cairo')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق', style: TextStyle(fontFamily: 'Cairo')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider);
    final nameController = TextEditingController(text: profile?.fullName);
    final userController = TextEditingController(text: profile?.username);
    final phoneController = TextEditingController(text: profile?.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملف الشخصي', style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => ref.read(profileProvider.notifier).uploadAvatar(),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                      backgroundColor: Colors.grey[200],
                      child: profile?.avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.green, child: Icon(Icons.camera_alt, size: 14, color: Colors.white))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: userController, decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: TextEditingController(text: profile?.email), enabled: false, decoration: const InputDecoration(labelText: 'البريد الإلكتروني (لا يمكن تعديله)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async {
              await ref.read(profileProvider.notifier).updateProfile(
                fullName: nameController.text,
                username: userController.text,
                phone: phoneController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح', style: TextStyle(fontFamily: 'Cairo'))));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
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
