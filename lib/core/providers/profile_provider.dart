import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String phone;
  final String? avatarUrl;
  final String email;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phone,
    this.avatarUrl,
    required this.email,
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> json, String email) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      email: email,
    );
  }
}

class ProfileNotifier extends StateNotifier<UserProfile?> {
  final _supabase = Supabase.instance.client;

  ProfileNotifier() : super(null) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (data != null) {
        state = UserProfile.fromSupabase(data, user.email ?? '');
      } else {
        // Create initial profile if not exists
        final initial = {
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'مستخدم Agri.AI',
          'username': user.email?.split('@')[0] ?? 'user',
          'updated_at': DateTime.now().toIso8601String(),
        };
        await _supabase.from('profiles').upsert(initial);
        state = UserProfile.fromSupabase(initial, user.email ?? '');
      }
    } catch (e) {
      print('Profile Load Error: $e');
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String username,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = {
      'id': user.id,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'avatar_url': avatarUrl ?? state?.avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').upsert(updates);
    state = UserProfile.fromSupabase(updates, user.email ?? '');
  }

  Future<String?> uploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image == null) return null;
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final file = File(image.path);
    final fileExt = image.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = fileName;

    try {
      await _supabase.storage.from('avatars').upload(filePath, file);
      final url = _supabase.storage.from('avatars').getPublicUrl(filePath);
      
      await updateProfile(
        fullName: state?.fullName ?? '',
        username: state?.username ?? '',
        phone: state?.phone ?? '',
        avatarUrl: url,
      );
      return url;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>((ref) {
  return ProfileNotifier();
});
