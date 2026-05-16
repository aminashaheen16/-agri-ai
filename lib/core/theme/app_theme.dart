import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static Color primaryGreen = const Color(0xFF2E7D32);
  static Color darkGreen = const Color(0xFF1B5E20);
  static Color lightGreen = const Color(0xFF4CAF50);
  static Color accentGreen = const Color(0xFF66BB6A);

  // Light Theme
  static ThemeData lightTheme({bool highContrast = false}) {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      textTheme: highContrast 
        ? _makeHighContrastText(textTheme, Colors.black)
        : textTheme,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: highContrast ? Colors.white : const Color(0xFFF8F9FA),
      
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: highContrast ? Colors.white : Colors.transparent,
        foregroundColor: Colors.black,
        elevation: highContrast ? 2 : 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highContrast ? Colors.black : primaryGreen,
          foregroundColor: Colors.white,
          elevation: highContrast ? 0 : 2,
          side: highContrast ? const BorderSide(color: Colors.black, width: 3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast ? const BorderSide(color: Colors.black, width: 3) : BorderSide.none,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: highContrast ? Colors.black : Colors.black12, width: highContrast ? 3 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: highContrast ? Colors.black : primaryGreen, width: 3),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  // Real Dark Theme
  static ThemeData darkTheme({bool highContrast = false}) {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      textTheme: highContrast 
        ? _makeHighContrastText(textTheme, Colors.white)
        : textTheme,
      primaryColor: darkGreen,
      scaffoldBackgroundColor: highContrast ? Colors.black : const Color(0xFF1A1A1A),
      
      colorScheme: ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: highContrast ? Colors.black : const Color(0xFF2A2A2A),
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: highContrast ? Colors.black : const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: highContrast ? 2 : 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highContrast ? Colors.white : primaryGreen,
          foregroundColor: highContrast ? Colors.black : Colors.white,
          elevation: 2,
          side: highContrast ? const BorderSide(color: Colors.white, width: 3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: highContrast ? Colors.black : const Color(0xFF2A2A2A),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: highContrast ? Colors.white : Colors.white24, width: highContrast ? 3 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: highContrast ? Colors.white : primaryGreen, width: 3),
        ),
        filled: true,
        fillColor: highContrast ? Colors.black : const Color(0xFF2A2A2A),
      ),
    );
  }

  static TextTheme _makeHighContrastText(TextTheme base, Color color) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.displayLarge?.fontSize ?? 32) * 1.1),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.displayMedium?.fontSize ?? 28) * 1.1),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.headlineLarge?.fontSize ?? 24) * 1.1),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.headlineMedium?.fontSize ?? 20) * 1.1),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.titleLarge?.fontSize ?? 18) * 1.1),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.bodyLarge?.fontSize ?? 16) * 1.1),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.bodyMedium?.fontSize ?? 14) * 1.1),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: (base.labelLarge?.fontSize ?? 14) * 1.1),
    );
  }
}