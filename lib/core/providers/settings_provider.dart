import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String language; // 'ar' or 'en'
  final String tempUnit; // 'C' or 'F'
  final String areaUnit; // 'm2' or 'acre'
  final ThemeMode themeMode;
  final bool highContrast;
  final double fontSizeMultiplier;

  SettingsState({
    this.language = 'ar',
    this.tempUnit = 'C',
    this.areaUnit = 'm2',
    this.themeMode = ThemeMode.light,
    this.highContrast = false,
    this.fontSizeMultiplier = 1.0,
  });

  SettingsState copyWith({
    String? language,
    String? tempUnit,
    String? areaUnit,
    ThemeMode? themeMode,
    bool? highContrast,
    double? fontSizeMultiplier,
  }) {
    return SettingsState(
      language: language ?? this.language,
      tempUnit: tempUnit ?? this.tempUnit,
      areaUnit: areaUnit ?? this.areaUnit,
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState());

  void setLanguage(String lang) => state = state.copyWith(language: lang);
  void setTempUnit(String unit) => state = state.copyWith(tempUnit: unit);
  void setAreaUnit(String unit) => state = state.copyWith(areaUnit: unit);
  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
  void toggleTheme(bool isDark) => state = state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
  void toggleContrast(bool value) => state = state.copyWith(highContrast: value);
  void setFontSize(double value) => state = state.copyWith(fontSizeMultiplier: value);
  
  double convertTemp(double celsius) {
    if (state.tempUnit == 'F') {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
