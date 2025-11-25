import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool darkMode;
  final String language;
  final bool dataSaver;
  final bool showOnlineStatus;
  final bool pushNotifications;
  final bool emailNotifications;

  SettingsState({
    this.darkMode = false,
    this.language = 'English',
    this.dataSaver = false,
    this.showOnlineStatus = true,
    this.pushNotifications = true,
    this.emailNotifications = true,
  });

  SettingsState copyWith({
    bool? darkMode,
    String? language,
    bool? dataSaver,
    bool? showOnlineStatus,
    bool? pushNotifications,
    bool? emailNotifications,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      dataSaver: dataSaver ?? this.dataSaver,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      darkMode: prefs.getBool('dark_mode') ?? false,
      language: prefs.getString('language') ?? 'English',
      dataSaver: prefs.getBool('data_saver') ?? false,
      showOnlineStatus: prefs.getBool('show_online_status') ?? true,
      pushNotifications: prefs.getBool('push_notifications') ?? true,
      emailNotifications: prefs.getBool('email_notifications') ?? true,
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    state = state.copyWith(language: value);
  }

  Future<void> toggleDataSaver(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_saver', value);
    state = state.copyWith(dataSaver: value);
  }

  Future<void> toggleShowOnlineStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_online_status', value);
    state = state.copyWith(showOnlineStatus: value);
  }

  Future<void> togglePushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    state = state.copyWith(pushNotifications: value);
  }

  Future<void> toggleEmailNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', value);
    state = state.copyWith(emailNotifications: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
