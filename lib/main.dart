import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agri_ai/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'features/auth/splash_screen.dart';
import 'core/providers/settings_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load Environment Variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }
  
  // Initialize Notifications
  try {
    await NotificationService.initialize(flutterLocalNotificationsPlugin);
  } catch (e) {
    debugPrint('Notification Service Error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: AgriAIApp(),
    ),
  );
}

class AgriAIApp extends ConsumerWidget {
  const AgriAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Agri.AI',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.lightTheme(highContrast: settings.highContrast).copyWith(
        textTheme: _buildResponsiveTextTheme(
          AppTheme.lightTheme(highContrast: settings.highContrast).textTheme, 
          settings.fontSizeMultiplier
        ),
      ),
      darkTheme: AppTheme.darkTheme(highContrast: settings.highContrast).copyWith(
        textTheme: _buildResponsiveTextTheme(
          AppTheme.darkTheme(highContrast: settings.highContrast).textTheme, 
          settings.fontSizeMultiplier
        ),
      ),
      themeMode: settings.themeMode,
      
      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      locale: Locale(settings.language),
      
      // Home
      home: const SplashScreen(),
    );
  }

  TextTheme _buildResponsiveTextTheme(TextTheme base, double multiplier) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 32) * multiplier),
      displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 28) * multiplier),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 24) * multiplier),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 20) * multiplier),
      titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 18) * multiplier),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16) * multiplier),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14) * multiplier),
      labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14) * multiplier),
    );
  }
}