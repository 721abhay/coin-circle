import 'package:flutter/material.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _screenReaderOptimized = false;
  bool _reduceAnimations = false;
  bool _simplifiedMode = false;
  String _language = 'English';

  final List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Arabic',
    'Chinese',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Visual',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Text Size'),
                  subtitle: Slider(
                    value: _textScale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(_textScale * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _textScale = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Small', style: TextStyle(fontSize: 12 * 0.8)),
                      Text('Normal', style: TextStyle(fontSize: 12 * 1.0)),
                      Text('Large', style: TextStyle(fontSize: 12 * 1.5)),
                      Text('XL', style: TextStyle(fontSize: 12 * 2.0)),
                    ],
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('High Contrast Mode'),
                  subtitle: const Text('Increase contrast for better visibility'),
                  value: _highContrast,
                  onChanged: (value) {
                    setState(() {
                      _highContrast = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Reduce Animations'),
                  subtitle: const Text('Minimize motion and transitions'),
                  value: _reduceAnimations,
                  onChanged: (value) {
                    setState(() {
                      _reduceAnimations = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Screen Reader',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Screen Reader Optimization'),
                  subtitle: const Text('Optimize for TalkBack/VoiceOver'),
                  value: _screenReaderOptimized,
                  onChanged: (value) {
                    setState(() {
                      _screenReaderOptimized = value;
                    });
                  },
                ),
                ListTile(
                  title: const Text('Screen Reader Tutorial'),
                  subtitle: const Text('Learn how to use the app with screen readers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to tutorial
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Language & Region',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showLanguagePicker();
                  },
                ),
                SwitchListTile(
                  title: const Text('Right-to-Left Layout'),
                  subtitle: const Text('For Arabic, Hebrew, etc.'),
                  value: false,
                  onChanged: (value) {
                    // Implement RTL
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Simplified Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Simplified Mode'),
                  subtitle: const Text('Larger buttons, simpler navigation'),
                  value: _simplifiedMode,
                  onChanged: (value) {
                    setState(() {
                      _simplifiedMode = value;
                    });
                  },
                ),
                if (_simplifiedMode)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Simplified mode provides a cleaner interface with larger touch targets',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Offline Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Offline Mode'),
                  subtitle: const Text('View cached data when offline'),
                  value: true,
                  onChanged: (value) {
                    // Implement offline mode
                  },
                ),
                ListTile(
                  title: const Text('Download Data for Offline Use'),
                  subtitle: const Text('Download pools and transactions'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    // Download data
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _language,
                onChanged: (value) {
                  setState(() {
                    _language = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
