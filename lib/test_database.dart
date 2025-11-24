import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick test to check if database is set up
/// Run this to verify Supabase connection and tables
Future<void> testDatabaseSetup() async {
  print('🔍 Testing Supabase connection...');
  
  try {
    final client = Supabase.instance.client;
    
    // Test 1: Check connection
    print('✅ Supabase client initialized');
    
    // Test 2: Try to query profiles table
    try {
      final profiles = await client.from('profiles').select().limit(1);
      print('✅ Profiles table exists');
    } catch (e) {
      print('❌ Profiles table MISSING or error: $e');
    }
    
    // Test 3: Try to query wallets table
    try {
      final wallets = await client.from('wallets').select().limit(1);
      print('✅ Wallets table exists');
    } catch (e) {
      print('❌ Wallets table MISSING or error: $e');
    }
    
    // Test 4: Check auth
    final user = client.auth.currentUser;
    if (user != null) {
      print('✅ User logged in: ${user.email}');
    } else {
      print('ℹ️ No user logged in');
    }
    
    print('\n📋 SUMMARY:');
    print('If you see ❌ above, you MUST run the SQL scripts in Supabase!');
    print('Go to: https://supabase.com → Your Project → SQL Editor');
    
  } catch (e) {
    print('❌ CRITICAL ERROR: $e');
    print('Check your .env file and Supabase credentials');
  }
}
