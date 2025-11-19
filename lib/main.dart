import 'package:coin_circle/core/router/app_router.dart';
import 'package:coin_circle/core/theme/app_theme.dart';
import 'package:coin_circle/core/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    print('⚠️  Please create a .env file with your Supabase credentials');
  }
  
  runApp(const ProviderScope(child: CoinCircleApp()));
}

class CoinCircleApp extends StatelessWidget {
  const CoinCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coin Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}

