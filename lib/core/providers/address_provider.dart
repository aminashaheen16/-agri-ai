import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressModel {
  final String id;
  final String label;
  final String governorate;
  final String city;
  final String street;
  final String? landmark;
  final String phone;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.governorate,
    required this.city,
    required this.street,
    this.landmark,
    required this.phone,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      label: json['label'] ?? '',
      governorate: json['governorate'] ?? '',
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      landmark: json['landmark'],
      phone: json['phone'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  String get fullAddress => '$governorate، $city، $street${landmark != null ? ' ($landmark)' : ''}';
}

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final _supabase = Supabase.instance.client;

  AddressNotifier() : super(const AsyncValue.loading()) {
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_default', ascending: false);
      
      state = AsyncValue.data((data as List).map((e) => AddressModel.fromJson(e)).toList());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAddress({
    required String label,
    required String governorate,
    required String city,
    required String street,
    String? landmark,
    required String phone,
    required bool isDefault,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (isDefault) {
      await _supabase.from('addresses').update({'is_default': false}).eq('user_id', user.id);
    }

    await _supabase.from('addresses').insert({
      'user_id': user.id,
      'label': label,
      'governorate': governorate,
      'city': city,
      'street': street,
      'landmark': landmark,
      'phone': phone,
      'is_default': isDefault,
      'created_at': DateTime.now().toIso8601String(),
    });

    await loadAddresses();
  }

  Future<void> deleteAddress(String id) async {
    await _supabase.from('addresses').delete().eq('id', id);
    await loadAddresses();
  }

  Future<void> setAsDefault(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('addresses').update({'is_default': false}).eq('user_id', user.id);
    await _supabase.from('addresses').update({'is_default': true}).eq('id', id);
    await loadAddresses();
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>((ref) {
  return AddressNotifier();
});
