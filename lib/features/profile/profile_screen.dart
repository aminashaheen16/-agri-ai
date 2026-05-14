import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/widgets/floating_quick_nav.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _avatarUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _isLoading = true;
    });

    try {
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

      setState(() {
        _avatarUrl = imageUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة بنجاح!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
              setState(() => _isLoading = true);
              try {
                // Update Auth Email and Metadata
                await _supabase.auth.updateUser(UserAttributes(
                  email: emailController.text.trim(),
                  data: {
                    'full_name': nameController.text.trim(),
                    'username': usernameController.text.trim(),
                    'phone_number': phoneController.text.trim(),
                  },
                ));
                
                if (mounted) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث البيانات بنجاح! قد تحتاج لتأكيد البريد الجديد.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
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
    final theme = Theme.of(context);
    final user = _supabase.auth.currentUser;
    final email = user?.email ?? 'لم يتم تسجيل البريد';
    final name = user?.userMetadata?['full_name'] ?? 'مستخدم Agri.AI';
    final username = user?.userMetadata?['username'] ?? 'agri_user';
    final phone = user?.userMetadata?['phone_number'] ?? 'لا يوجد رقم هاتف';

    ImageProvider? profileImage;
    if (_avatarUrl != null) {
      profileImage = NetworkImage(_avatarUrl!);
    } else if (_imageBytes != null) {
      profileImage = MemoryImage(_imageBytes!);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      floatingActionButton: const FloatingQuickNav(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Profile Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white24,
                            backgroundImage: profileImage,
                            child: profileImage == null
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                        if (_isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.green, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$email | $phone",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Menu Items Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الإعدادات العامة",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuItem(context, 'تعديل الملف الشخصي', Icons.person_outline, onTap: () => _showEditDialog(name, username, phone, email)),
                  _buildMenuItem(context, 'عناويني', Icons.location_on_outlined, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شاشة العناوين ستكون متوفرة قريباً 📍', style: TextStyle(fontFamily: 'Cairo'))));
                  }),
                  _buildMenuItem(context, 'تاريخ الطلبات', Icons.history, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تاريخ الطلبات فارغ حالياً 📦', style: TextStyle(fontFamily: 'Cairo'))));
                  }),
                  _buildMenuItem(context, 'المساعدة والدعم', Icons.help_outline, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري الاتصال بالدعم الفني... 📞', style: TextStyle(fontFamily: 'Cairo'))));
                  }),
                  const Divider(height: 40),
                  _buildMenuItem(context, 'تسجيل الخروج', Icons.logout, isDestructive: true, onTap: () async {
                    await _supabase.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isDestructive ? Colors.red : Colors.green, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : theme.colorScheme.onSurface,
            fontFamily: 'Cairo',
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 14, 
          color: isDestructive ? Colors.red.withOpacity(0.5) : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        onTap: onTap,
      ),
    );
  }
}