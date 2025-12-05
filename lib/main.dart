import 'package:coin_circle/core/router/app_router.dart';
import 'package:coin_circle/core/theme/app_theme.dart';
import 'package:coin_circle/core/config/supabase_config.dart';
import 'package:coin_circle/test_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_circle/core/providers/settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Added for localizations
import 'package:coin_circle/core/l10n/app_localizations.dart'; // Localization delegate
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:coin_circle/core/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
    
    // Initialize Push Notifications
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
    debugPrint('⚠️  Firebase not configured yet. Push notifications will not work.');
  }
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
    // Test database setup
    await testDatabaseSetup();
    
    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('🔐 User signed in, redirecting to home...');
        appRouter.go('/home');
      }
    });
  } catch (e) {
    debugPrint('❌ Error initializing Supabase: $e');
    debugPrint('⚠️  Please create a .env file with your Supabase credentials');
  }
  runApp(const ProviderScope(child: CoinCircleApp()));
}

class CoinCircleApp extends ConsumerWidget {
  const CoinCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Win Pool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      locale: settings.language == 'Hindi' ? const Locale('hi') : const Locale('en'),
      routerConfig: appRouter,
    );
  }
}
