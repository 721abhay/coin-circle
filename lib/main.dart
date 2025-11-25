import 'package:coin_circle/core/router/app_router.dart';
import 'package:coin_circle/core/theme/app_theme.dart';
import 'package:coin_circle/core/config/supabase_config.dart';
import 'package:coin_circle/test_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_circle/core/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
    
    // Test database setup
    await testDatabaseSetup();
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    print('⚠️  Please create a .env file with your Supabase credentials');
  }
  
  runApp(const ProviderScope(child: CoinCircleApp()));
}



class CoinCircleApp extends ConsumerWidget {
  const CoinCircleApp({super.key});

import 'package:coin_circle/core/router/app_router.dart';
import 'package:coin_circle/core/theme/app_theme.dart';
import 'package:coin_circle/core/config/supabase_config.dart';
import 'package:coin_circle/test_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_circle/core/providers/settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Added for localizations
import 'package:coin_circle/l10n/app_localizations.dart'; // Assuming this path for AppLocalizationsDelegate

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
    
    // Test database setup
    await testDatabaseSetup();
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    print('⚠️  Please create a .env file with your Supabase credentials');
  }
  
  runApp(const ProviderScope(child: CoinCircleApp()));
}



class CoinCircleApp extends ConsumerWidget {
  const CoinCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp.router(
      title: 'Coin Circle',
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
