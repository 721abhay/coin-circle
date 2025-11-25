import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'en': {
      'settings': 'Settings',
      'account': 'Account',
      'personal_information': 'Personal Information',
      'password_security': 'Password & Security',
      'verification_status': 'Verification Status',
      'linked_accounts': 'Linked Accounts',
      'app_settings': 'App Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'data_saver': 'Data Saver',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'email_updates': 'Email Updates',
      'privacy_security': 'Privacy & Security',
      'profile_visibility': 'Profile Visibility',
      'privacy_policy': 'Privacy Policy',
      'show_online_status': 'Show Online Status',
      'who_can_invite_me': 'Who Can Invite Me',
      'terms_of_service': 'Terms of Service',
      'support_help': 'Support & Help',
      'help_center': 'Help Center',
      'report_problem': 'Report a Problem',
      'faqs': 'FAQs',
      'account_management': 'Account Management',
      'log_out': 'Log Out',
      'version': 'Version',
      'select_language': 'Select Language',
      'english': 'English',
      'hindi': 'हिंदी (Hindi)',
      'enter_pin': 'Enter PIN',
      'enter_pin_prompt': 'Enter your 4-digit PIN to continue',
      'verify': 'Verify',
      'logout': 'Logout',
      'pin_incorrect': 'Incorrect PIN. Please try again.',
      'pin_required': 'Please enter 4-digit PIN',
      'privacy_and_data': 'Privacy & Data',
      'data_sharing': 'Data Sharing',
      'share_analytics': 'Share Analytics',
      'share_analytics_desc': 'Help us improve with anonymous data',
      'public_profile': 'Public Profile',
      'public_profile_desc': 'Allow others to find you',
      'show_balance': 'Show Balance',
      'show_balance_desc': 'Display wallet balance on home screen',
      'your_data_rights': 'Your Data Rights (GDPR/CCPA)',
      'download_my_data': 'Download My Data',
      'download_my_data_desc': 'Get a copy of all your activity',
      'delete_account': 'Delete Account',
      'delete_account_desc': 'Permanently remove all data',
      'delete_account_confirm': 'Delete Account?',
      'delete_account_content': 'This action is irreversible. All your data, pools, and wallet balance will be permanently deleted.',
      'cancel': 'Cancel',
      'delete_forever': 'Delete Forever',
    },
    'hi': {
      'settings': 'सेटिंग्स',
      'account': 'खाता',
      'personal_information': 'व्यक्तिगत जानकारी',
      'password_security': 'पासवर्ड और सुरक्षा',
      'verification_status': 'सत्यापन स्थिति',
      'linked_accounts': 'जुड़े खाते',
      'app_settings': 'ऐप सेटिंग्स',
      'dark_mode': 'डार्क मोड',
      'language': 'भाषा',
      'data_saver': 'डेटा सेवर',
      'notifications': 'सूचनाएँ',
      'push_notifications': 'पुश सूचनाएँ',
      'email_updates': 'ईमेल अपडेट',
      'privacy_security': 'गोपनीयता और सुरक्षा',
      'profile_visibility': 'प्रोफ़ाइल दृश्यता',
      'privacy_policy': 'गोपनीयता नीति',
      'show_online_status': 'ऑनलाइन स्थिति दिखाएँ',
      'who_can_invite_me': 'कौन मुझे आमंत्रित कर सकता है',
      'terms_of_service': 'सेवा की शर्तें',
      'support_help': 'समर्थन और मदद',
      'help_center': 'हेल्प सेंटर',
      'report_problem': 'समस्या रिपोर्ट करें',
      'faqs': 'अक्सर पूछे जाने वाले प्रश्न',
      'account_management': 'खाता प्रबंधन',
      'log_out': 'लॉग आउट',
      'version': 'संस्करण',
      'select_language': 'भाषा चुनें',
      'english': 'English',
      'hindi': 'हिंदी (Hindi)',
      'enter_pin': 'पिन दर्ज करें',
      'enter_pin_prompt': 'जारी रखने के लिए अपना 4-अंकीय पिन दर्ज करें',
      'verify': 'सत्यापित करें',
      'logout': 'लॉगआउट',
      'pin_incorrect': 'गलत पिन। कृपया फिर से प्रयास करें।',
      'pin_required': 'कृपया 4-अंकीय पिन दर्ज करें',
      'privacy_and_data': 'गोपनीयता और डेटा',
      'data_sharing': 'डेटा साझा करना',
      'share_analytics': 'एनालिटिक्स साझा करें',
      'share_analytics_desc': 'गुमनाम डेटा के साथ हमें सुधारने में मदद करें',
      'public_profile': 'सार्वजनिक प्रोफ़ाइल',
      'public_profile_desc': 'दूसरों को आपको खोजने दें',
      'show_balance': 'बैलेंस दिखाएँ',
      'show_balance_desc': 'होम स्क्रीन पर वॉलेट बैलेंस दिखाएँ',
      'your_data_rights': 'आपके डेटा अधिकार (GDPR/CCPA)',
      'download_my_data': 'मेरे डेटा को डाउनलोड करें',
      'download_my_data_desc': 'आपकी सभी गतिविधियों की एक कॉपी प्राप्त करें',
      'delete_account': 'खाता हटाएँ',
      'delete_account_desc': 'सभी डेटा को स्थायी रूप से हटाएँ',
      'delete_account_confirm': 'खाता हटाएँ?',
      'delete_account_content': 'यह कार्रवाई अपरिवर्तनीय है। आपका सभी डेटा, पूल और वॉलेट बैलेंस स्थायी रूप से हटा दिया जाएगा।',
      'cancel': 'रद्द करें',
      'delete_forever': 'सदा के लिए हटाएँ',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
