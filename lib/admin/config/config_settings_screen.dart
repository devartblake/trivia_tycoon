import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/app_settings.dart';

class ConfigSettingsScreen extends ConsumerStatefulWidget {
  const ConfigSettingsScreen({super.key});

  @override
  ConsumerState<ConfigSettingsScreen> createState() => _ConfigSettingsScreenState();
}

class _ConfigSettingsScreenState extends ConsumerState<ConfigSettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isLoggingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiUrl = await AppSettings.getString('api_url') ?? '';
    final logging = await AppSettings.getBool('enable_logging') ?? false;

    setState(() {
      _apiUrlController.text = apiUrl;
      _isLoggingEnabled = logging;
    });
  }

  Future<void> _saveSettings() async {
    await AppSettings.setString('api_url', _apiUrlController.text.trim());
    await AppSettings.setBool('enable_logging', _isLoggingEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Config Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Logging'),
              subtitle: const Text('Show debug logs throughout the app'),
              value: _isLoggingEnabled,
              onChanged: (value) {
                setState(() => _isLoggingEnabled = value);
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }
}
