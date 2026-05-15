import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/profile/settings_screen.dart';
import '../../features/profile/help_center_screen.dart';
import '../../features/profile/about_app_screen.dart';
import '../../features/store/cart_screen.dart';
import '../../features/store/store_screen.dart';
import '../../features/store/favorites_screen.dart';
import '../../features/plant_health/plant_health_screen.dart';
import '../../features/ai_chat/chat_screen.dart';
import '../../core/providers/settings_provider.dart';
import '../../features/auth/login_screen.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final _supabase = Supabase.instance.client;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = image.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await _supabase.storage.from('avatars').uploadBinary(
        filePath, 
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      await _supabase.auth.updateUser(UserAttributes(
        data: {'avatar_url': imageUrl},
      ));

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة بنجاح!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e')),
        );
      }
    }
  }

  void _showEditDialog(String currentName, String currentUsername, String currentPhone, String currentEmail) {
    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentUsername);
    final phoneController = TextEditingController(text: currentPhone);
    final emailController = TextEditingController(text: currentEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل البيانات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                style: const TextStyle(fontFamily: 'Cairo'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                style: const TextStyle(fontFamily: 'Cairo'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabase.auth.updateUser(UserAttributes(
                  email: emailController.text.trim(),
                  data: {
                    'full_name': nameController.text.trim(),
                    'username': usernameController.text.trim(),
                    'phone_number': phoneController.text.trim(),
                  },
                ));
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث البيانات بنجاح!'), backgroundColor: Colors.green),
                  );
                  setState(() {}); // Refresh header
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.language == 'ar';
    
    final user = _supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? (isAr ? 'مستخدم Agri.AI' : 'Agri.AI User');
    final username = user?.userMetadata?['username'] ?? 'agri_user';
    final email = user?.email ?? '';
    final phone = user?.userMetadata?['phone_number'] ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // New Premium Centered Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 25, left: 20, right: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade900, Colors.green.shade700],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white24,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 50) : null,
                      ),
                    ),
                    if (_isUploading)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.green, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => _showEditDialog(name, username, phone, email),
                      child: const Icon(Icons.edit, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildItem(context, Icons.grid_view_rounded, isAr ? 'لوحة التحكم' : 'Dashboard', () => Navigator.pop(context)),
                _buildItem(context, Icons.chat_bubble_rounded, isAr ? 'المساعد الذكي' : 'AI Assistant', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                }),
                _buildItem(context, Icons.eco_rounded, isAr ? 'فحص النباتات' : 'Plant Health', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantHealthScreen()));
                }),
                _buildItem(context, Icons.storefront_rounded, isAr ? 'المتجر الزراعي' : 'Store', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                }),
                const Divider(indent: 20, endIndent: 20, height: 30),
                _buildItem(context, Icons.shopping_cart_rounded, isAr ? 'سلة المشتريات' : 'Cart', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                }),
                _buildItem(context, Icons.favorite_rounded, isAr ? 'المفضلة' : 'Favorites', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                }),
                const Divider(indent: 20, endIndent: 20, height: 30),
                _buildItem(context, Icons.settings_rounded, isAr ? 'الإعدادات' : 'Settings', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _buildItem(context, Icons.help_center_rounded, isAr ? 'مركز المساعدة' : 'Help Center', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                }),
                _buildItem(context, Icons.logout_rounded, isAr ? 'تسجيل الخروج' : 'Logout', () async {
                  await _supabase.auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(isAr ? 'Agri.AI v1.0.1 | مطور بكل حب 🌿' : 'Agri.AI v1.0.1 | Built with Love 🌿', 
              style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade800, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black12),
      onTap: onTap,
    );
  }
}
