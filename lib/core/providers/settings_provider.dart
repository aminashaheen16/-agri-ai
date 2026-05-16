import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsState {
  final String language;
  final String tempUnit;
  final String areaUnit;
  final ThemeMode themeMode;
  final bool highContrast;
  final double fontSizeMultiplier;
  final bool largeButtons;
  final bool simplifiedUI;
  final bool vibration;
  final bool notificationsEnabled;
  final bool agendaNotify;
  final bool sensorNotify;
  final bool storeNotify;
  final bool dailySummaryNotify;

  SettingsState({
    this.language = 'ar',
    this.tempUnit = 'celsius',
    this.areaUnit = 'sqm',
    this.themeMode = ThemeMode.light,
    this.highContrast = false,
    this.fontSizeMultiplier = 1.0,
    this.largeButtons = false,
    this.simplifiedUI = false,
    this.vibration = true,
    this.notificationsEnabled = true,
    this.agendaNotify = true,
    this.sensorNotify = true,
    this.storeNotify = true,
    this.dailySummaryNotify = true,
  });

  SettingsState copyWith({
    String? language,
    String? tempUnit,
    String? areaUnit,
    ThemeMode? themeMode,
    bool? highContrast,
    double? fontSizeMultiplier,
    bool? largeButtons,
    bool? simplifiedUI,
    bool? vibration,
    bool? notificationsEnabled,
    bool? agendaNotify,
    bool? sensorNotify,
    bool? storeNotify,
    bool? dailySummaryNotify,
  }) {
    return SettingsState(
      language: language ?? this.language,
      tempUnit: tempUnit ?? this.tempUnit,
      areaUnit: areaUnit ?? this.areaUnit,
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      largeButtons: largeButtons ?? this.largeButtons,
      simplifiedUI: simplifiedUI ?? this.simplifiedUI,
      vibration: vibration ?? this.vibration,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      agendaNotify: agendaNotify ?? this.agendaNotify,
      sensorNotify: sensorNotify ?? this.sensorNotify,
      storeNotify: storeNotify ?? this.storeNotify,
      dailySummaryNotify: dailySummaryNotify ?? this.dailySummaryNotify,
    );
  }

  Map<String, dynamic> toSupabase(String userId) => {
    'user_id': userId,
    'language': language,
    'temp_unit': tempUnit,
    'area_unit': areaUnit,
    'theme_mode': themeMode.index,
    'high_contrast': highContrast,
    'font_scale': fontSizeMultiplier,
    'large_buttons': largeButtons,
    'simplified_ui': simplifiedUI,
    'vibration': vibration,
    'notifications_enabled': notificationsEnabled,
    'agenda_notify': agendaNotify,
    'sensor_notify': sensorNotify,
    'store_notify': storeNotify,
    'daily_summary_notify': dailySummaryNotify,
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory SettingsState.fromSupabase(Map<String, dynamic> json) => SettingsState(
    language: json['language'] ?? 'ar',
    tempUnit: json['temp_unit'] ?? 'celsius',
    areaUnit: json['area_unit'] ?? 'sqm',
    themeMode: ThemeMode.values[json['theme_mode'] ?? 1],
    highContrast: json['high_contrast'] ?? false,
    fontSizeMultiplier: (json['font_scale'] as num?)?.toDouble() ?? 1.0,
    largeButtons: json['large_buttons'] ?? false,
    simplifiedUI: json['simplified_ui'] ?? false,
    vibration: json['vibration'] ?? true,
    notificationsEnabled: json['notifications_enabled'] ?? true,
    agendaNotify: json['agenda_notify'] ?? true,
    sensorNotify: json['sensor_notify'] ?? true,
    storeNotify: json['store_notify'] ?? true,
    dailySummaryNotify: json['daily_summary_notify'] ?? true,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final _supabase = Supabase.instance.client;
  static const String _localPrefix = 'agri_settings_';

  SettingsNotifier() : super(SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadLocalSettings();
    await _syncWithSupabase();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      language: prefs.getString('${_localPrefix}lang') ?? 'ar',
      tempUnit: prefs.getString('${_localPrefix}temp') ?? 'celsius',
      areaUnit: prefs.getString('${_localPrefix}area') ?? 'sqm',
      themeMode: ThemeMode.values[prefs.getInt('${_localPrefix}theme') ?? 1],
      fontSizeMultiplier: prefs.getDouble('${_localPrefix}font') ?? 1.0,
      highContrast: prefs.getBool('${_localPrefix}contrast') ?? false,
      largeButtons: prefs.getBool('${_localPrefix}large_btns') ?? false,
      simplifiedUI: prefs.getBool('${_localPrefix}simple_ui') ?? false,
      vibration: prefs.getBool('${_localPrefix}vibration') ?? true,
      notificationsEnabled: prefs.getBool('${_localPrefix}notifications') ?? true,
      agendaNotify: prefs.getBool('${_localPrefix}agenda_notify') ?? true,
      sensorNotify: prefs.getBool('${_localPrefix}sensor_notify') ?? true,
      storeNotify: prefs.getBool('${_localPrefix}store_notify') ?? true,
      dailySummaryNotify: prefs.getBool('${_localPrefix}daily_summary_notify') ?? true,
    );
  }

  Future<void> _syncWithSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase.from('user_settings').select().eq('user_id', user.id).maybeSingle();
      if (data != null) {
        state = SettingsState.fromSupabase(data);
        _saveLocal();
      }
    } catch (e) {
      print('Supabase Settings Load Error: $e');
    }
  }

  Future<void> _saveAll() async {
    _saveLocal();
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('user_settings').upsert(state.toSupabase(user.id));
    } catch (e) {
      print('Supabase Settings Save Error: $e');
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_localPrefix}lang', state.language);
    await prefs.setString('${_localPrefix}temp', state.tempUnit);
    await prefs.setString('${_localPrefix}area', state.areaUnit);
    await prefs.setInt('${_localPrefix}theme', state.themeMode.index);
    await prefs.setDouble('${_localPrefix}font', state.fontSizeMultiplier);
    await prefs.setBool('${_localPrefix}contrast', state.highContrast);
    await prefs.setBool('${_localPrefix}large_btns', state.largeButtons);
    await prefs.setBool('${_localPrefix}simple_ui', state.simplifiedUI);
    await prefs.setBool('${_localPrefix}vibration', state.vibration);
    await prefs.setBool('${_localPrefix}notifications', state.notificationsEnabled);
    await prefs.setBool('${_localPrefix}agenda_notify', state.agendaNotify);
    await prefs.setBool('${_localPrefix}sensor_notify', state.sensorNotify);
    await prefs.setBool('${_localPrefix}store_notify', state.storeNotify);
    await prefs.setBool('${_localPrefix}daily_summary_notify', state.dailySummaryNotify);
  }

  void triggerVibration() {
    if (state.vibration) {
      HapticFeedback.mediumImpact();
    }
  }

  // Setters
  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _saveAll();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveAll();
  }

  Future<void> toggleContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    await _saveAll();
  }

  Future<void> setFontSize(double value) async {
    state = state.copyWith(fontSizeMultiplier: value);
    await _saveAll();
  }

  Future<void> setLargeButtons(bool value) async {
    state = state.copyWith(largeButtons: value);
    await _saveAll();
  }

  Future<void> setSimplifiedUI(bool value) async {
    state = state.copyWith(simplifiedUI: value);
    await _saveAll();
  }

  Future<void> setVibration(bool value) async {
    state = state.copyWith(vibration: value);
    await _saveAll();
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _saveAll();
  }

  Future<void> toggleAgendaNotify(bool value) async {
    state = state.copyWith(agendaNotify: value);
    await _saveAll();
  }

  Future<void> toggleSensorNotify(bool value) async {
    state = state.copyWith(sensorNotify: value);
    await _saveAll();
  }

  Future<void> toggleStoreNotify(bool value) async {
    state = state.copyWith(storeNotify: value);
    await _saveAll();
  }

  Future<void> toggleDailySummary(bool value) async {
    state = state.copyWith(dailySummaryNotify: value);
    await _saveAll();
  }

  Future<void> setTempUnit(String unit) async {
    state = state.copyWith(tempUnit: unit);
    await _saveAll();
  }

  Future<void> setAreaUnit(String unit) async {
    state = state.copyWith(areaUnit: unit);
    await _saveAll();
  }

  // Auth actions
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('profiles').delete().eq('id', user.id);
    await _supabase.auth.signOut();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
