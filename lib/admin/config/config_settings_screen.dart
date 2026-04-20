import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';

import '../../core/services/settings/app_settings.dart';
import '../../game/providers/riverpod_providers.dart';

class ConfigSettingsScreen extends ConsumerStatefulWidget {
  const ConfigSettingsScreen({super.key});

  @override
  ConsumerState<ConfigSettingsScreen> createState() =>
      _ConfigSettingsScreenState();
}

class _ConfigSettingsScreenState extends ConsumerState<ConfigSettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isLoggingEnabled = false;
  bool _isSaving = false;
  bool _isLoadingRemote = false;
  String? _remoteSyncStatus;

  String _lastSyncedApiUrl = '';
  bool _lastSyncedLogging = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingRemote = true);

    // Start with local fallback values first.
    final localApiUrl = await AppSettings.getString('api_url') ?? '';
    final localLogging = await AppSettings.getBool('enable_logging') ?? false;

    setState(() {
      _apiUrlController.text = localApiUrl;
      _isLoggingEnabled = localLogging;
      _lastSyncedApiUrl = localApiUrl;
      _lastSyncedLogging = localLogging;
    });

    // Then attempt to hydrate from backend admin config.
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/config');
      final remoteApiUrl =
          (response['apiUrl'] ?? response['api_url'] ?? localApiUrl).toString();
      final remoteLogging = (response['enableLogging'] ??
              response['enable_logging'] ??
              localLogging) ==
          true;

      if (!mounted) return;
      setState(() {
        _apiUrlController.text = remoteApiUrl;
        _isLoggingEnabled = remoteLogging;
        _lastSyncedApiUrl = remoteApiUrl;
        _lastSyncedLogging = remoteLogging;
        _remoteSyncStatus = 'Loaded remote config successfully.';
      });

      await AppSettings.setString('api_url', remoteApiUrl);
      await AppSettings.setBool('enable_logging', remoteLogging);
    } on ApiRequestException catch (e) {
      final errorCode = e.errorCode != null ? ' [${e.errorCode}]' : '';
      if (mounted) {
        setState(() {
          _remoteSyncStatus =
              'Remote config unavailable$errorCode: ${e.message}. Using local fallback.';
        });
      }
    } catch (_) {
      // keep local fallback silently for unsupported/offline environments.
      if (mounted) {
        setState(() {
          _remoteSyncStatus =
              'Remote config unavailable. Using local fallback.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRemote = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final optimisticApiUrl = _apiUrlController.text.trim();
    final optimisticLogging = _isLoggingEnabled;

    setState(() => _isSaving = true);

    // Optimistic local persistence.
    await AppSettings.setString('api_url', optimisticApiUrl);
    await AppSettings.setBool('enable_logging', optimisticLogging);

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      await serviceManager.apiService.patch(
        '/admin/config',
        body: {
          'apiUrl': optimisticApiUrl,
          'enableLogging': optimisticLogging,
        },
      );

      _lastSyncedApiUrl = optimisticApiUrl;
      _lastSyncedLogging = optimisticLogging;

      if (!mounted) return;
      setState(() => _remoteSyncStatus = 'Config synced to backend.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Configuration synced with server.'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on ApiRequestException catch (e) {
      // Rollback local values when backend update fails.
      _apiUrlController.text = _lastSyncedApiUrl;
      _isLoggingEnabled = _lastSyncedLogging;
      await AppSettings.setString('api_url', _lastSyncedApiUrl);
      await AppSettings.setBool('enable_logging', _lastSyncedLogging);

      if (!mounted) return;
      final errorCode = e.errorCode != null ? ' [${e.errorCode}]' : '';
      setState(() =>
          _remoteSyncStatus = 'Config sync failed$errorCode: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to sync config. Reverted changes$errorCode: ${e.message}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _apiUrlController.text = _lastSyncedApiUrl;
      _isLoggingEnabled = _lastSyncedLogging;
      await AppSettings.setString('api_url', _lastSyncedApiUrl);
      await AppSettings.setBool('enable_logging', _lastSyncedLogging);

      if (!mounted) return;
      setState(() => _remoteSyncStatus = 'Config sync failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync config. Reverted changes: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Configuration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLoadingRemote)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_remoteSyncStatus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  _remoteSyncStatus!,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure your application preferences',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API URL Card
          _buildSettingCard(
            title: 'API Configuration',
            icon: Icons.cloud_outlined,
            iconColor: const Color(0xFF3B82F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API URL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiUrlController,
                  decoration: InputDecoration(
                    hintText: 'https://api.example.com',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Logging Settings Card
          _buildSettingCard(
            title: 'Debug Options',
            icon: Icons.bug_report_outlined,
            iconColor: const Color(0xFFF59E0B),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Enable Logging',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                subtitle: const Text(
                  'Show debug logs throughout the app',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                value: _isLoggingEnabled,
                onChanged: (value) {
                  setState(() => _isLoggingEnabled = value);
                },
                activeColor: const Color(0xFF10B981),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : _saveSettings,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Save Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }
}
