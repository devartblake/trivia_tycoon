import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../game/controllers/settings_controller.dart';
import '../../core/services/notification_service.dart';
import '../../game/providers/riverpod_providers.dart';

final settingsControllerProvider = Provider<SettingsController>((ref) {
  final manager = ref.read(serviceManagerProvider);
  return SettingsController(
    audioService: manager.audioSettingsService,
    profileService: manager.playerProfileService,
    purchaseService: manager.purchaseSettingsService,
  );
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late final SettingsController settingsController;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  late List<AnimationController> _sectionControllers;

  final List<Map<String, dynamic>> _audioSettings = [];
  final List<Map<String, dynamic>> _themeSettings = [];
  final List<Map<String, dynamic>> _preferences = [];
  final List<Map<String, dynamic>> _privacy = [];

  // Notification status tracking
  bool _notificationsEnabled = false;
  bool _isCheckingNotifications = false;

  @override
  void initState() {
    super.initState();
    settingsController = ref.read(settingsControllerProvider);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _sectionControllers = List.generate(4, (index) => AnimationController(
      duration: Duration(milliseconds: 600 + (index * 100)),
      vsync: this,
    ));

    _initializeSettings();
    _startAnimations();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _isCheckingNotifications = true;
    });

    try {
      final enabled = await NotificationService().isNotificationEnabled();
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _isCheckingNotifications = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to check notification status: $e');
      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
          _isCheckingNotifications = false;
        });
      }
    }
  }

  void _initializeSettings() {
    _audioSettings.addAll([
      {
        'title': 'Enable Audio',
        'icon': Icons.volume_up_rounded,
        'valueNotifier': settingsController.audioOn,
        'toggleFunction': settingsController.toggleAudioOn,
        'type': 'toggle',
      },
      {
        'title': 'Enable Music',
        'icon': Icons.music_note_rounded,
        'valueNotifier': settingsController.musicOn,
        'toggleFunction': settingsController.toggleMusicOn,
        'type': 'toggle',
      },
      {
        'title': 'Enable Sound Effects',
        'icon': Icons.speaker_rounded,
        'valueNotifier': settingsController.soundsOn,
        'toggleFunction': settingsController.toggleSoundsOn,
        'type': 'toggle',
      },
    ]);

    _themeSettings.addAll([
      {
        'title': 'Theme Settings',
        'subtitle': 'Customize app appearance',
        'icon': Icons.palette_rounded,
        'route': '/theme-settings',
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Confetti Settings',
        'subtitle': 'Animation preferences',
        'icon': Icons.celebration_rounded,
        'route': '/confetti-settings',
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Available Songs',
        'subtitle': 'Music library',
        'icon': Icons.library_music_rounded,
        'route': '/music',
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Skill Tree Theme',
        'subtitle': 'Visual customization',
        'icon': Icons.account_tree_rounded,
        'route': '/skill-theme',
        'color': const Color(0xFF8B5CF6),
      },
    ]);

    _preferences.addAll([
      {
        'title': 'Notifications',
        'subtitle': _isCheckingNotifications
            ? 'Checking status...'
            : (_notificationsEnabled ? 'Enabled' : 'Disabled'),
        'icon': Icons.notifications_rounded,
        'color': _notificationsEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        'type': 'notification_setting',
      },
      {
        'title': 'Newsletter',
        'subtitle': 'Stay updated with news',
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF06B6D4),
      },
      {
        'title': 'Questions with Images',
        'subtitle': 'Visual question format',
        'icon': Icons.image_rounded,
        'color': const Color(0xFFF59E0B),
      },
    ]);

    _privacy.addAll([
      {
        'title': 'Help & Feedback',
        'subtitle': 'Support and suggestions',
        'icon': Icons.help_outline_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'About',
        'subtitle': 'App information',
        'icon': Icons.info_outline_rounded,
        'color': const Color(0xFF64748B),
      },
      {
        'title': 'Sign Out',
        'subtitle': 'End current session',
        'icon': Icons.logout_rounded,
        'color': const Color(0xFFEF4444),
        'isDestructive': true,
      },
    ]);
  }

  void _startAnimations() {
    _animationController!.forward();
    for (int i = 0; i < _sectionControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) _sectionControllers[i].forward();
      });
    }
  }

  Future<void> _handleNotificationTap() async {
    if (_isCheckingNotifications) return;

    if (_notificationsEnabled) {
      // Show dialog explaining how to disable notifications in system settings
      _showNotificationDisableDialog();
    } else {
      // Request permissions using the NotificationService
      setState(() {
        _isCheckingNotifications = true;
      });

      try {
        final granted = await NotificationService().requestPermissionsWithDialog(context);

        if (mounted) {
          setState(() {
            _notificationsEnabled = granted;
            _isCheckingNotifications = false;
          });

          // Refresh the preferences list to update the subtitle
          _preferences.clear();
          _initializeSettings();
        }

        if (granted) {
          _showNotificationSuccessDialog();
        }
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
        if (mounted) {
          setState(() {
            _isCheckingNotifications = false;
          });
          _showNotificationErrorDialog();
        }
      }
    }
  }

  void _showNotificationSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Notifications Enabled!'),
            ],
          ),
          content: const Text(
            'You\'ll now receive notifications about:\n'
                '• Spin wheel ready alerts\n'
                '• Mission updates\n'
                '• Daily reminders',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Great!', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationDisableDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Color(0xFF06B6D4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Notification Settings'),
            ],
          ),
          content: const Text(
            'Notifications are currently enabled. To disable them:\n\n'
                '1. Go to your device Settings\n'
                '2. Find "Apps" or "Application Manager"\n'
                '3. Select "Trivia Tycoon"\n'
                '4. Tap "Notifications"\n'
                '5. Turn off notifications',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it', style: TextStyle(color: Color(0xFF06B6D4))),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Permission Error'),
            ],
          ),
          content: const Text(
            'There was an issue setting up notifications. You can try again later or enable them manually in your device settings.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    for (final controller in _sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: _fadeAnimation != null
          ? FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildBody(),
      )
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        _buildSection('Audio Settings', _audioSettings, 0, Icons.volume_up_rounded),
        _buildSection('Appearance', _themeSettings, 1, Icons.brush_rounded),
        _buildSection('Preferences', _preferences, 2, Icons.tune_rounded),
        _buildSection('Privacy & Security', _privacy, 3, Icons.security_rounded),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, int sectionIndex, IconData sectionIcon) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[sectionIndex],
          curve: Curves.easeOutBack,
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF64748B).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(title, sectionIcon),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildSettingItem(item, index == items.length - 1),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(Map<String, dynamic> item, bool isLast) {
    if (item['type'] == 'toggle') {
      return _buildToggleItem(item, isLast);
    } else if (item['type'] == 'notification_setting') {
      return _buildNotificationItem(item, isLast);
    } else {
      return _buildNavigationItem(item, isLast);
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, bool isLast) {
    final color = _notificationsEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _isCheckingNotifications
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
              : Icon(
            _notificationsEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          _isCheckingNotifications
              ? 'Checking status...'
              : (_notificationsEnabled ? 'Enabled - tap for settings' : 'Tap to enable'),
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF64748B).withOpacity(0.8),
          ),
        ),
        trailing: Icon(
          _notificationsEnabled
              ? Icons.settings_rounded
              : Icons.arrow_forward_ios_rounded,
          color: const Color(0xFF64748B).withOpacity(0.5),
          size: 16,
        ),
        onTap: _handleNotificationTap,
      ),
    );
  }

  Widget _buildToggleItem(Map<String, dynamic> item, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item['icon'],
            color: const Color(0xFF10B981),
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: ValueListenableBuilder<bool>(
          valueListenable: item['valueNotifier'],
          builder: (context, value, _) {
            return Switch.adaptive(
              value: value,
              onChanged: (_) => item['toggleFunction'](),
              activeColor: const Color(0xFF10B981),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationItem(Map<String, dynamic> item, bool isLast) {
    final isDestructive = item['isDestructive'] ?? false;
    final color = item['color'] as Color? ?? const Color(0xFF6366F1);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item['icon'],
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
          ),
        ),
        subtitle: item['subtitle'] != null
            ? Text(
          item['subtitle'],
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF64748B).withOpacity(0.8),
          ),
        )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: const Color(0xFF64748B).withOpacity(0.5),
          size: 16,
        ),
        onTap: () {
          if (item['route'] != null) {
            context.push(item['route']);
          } else if (isDestructive) {
            _showSignOutDialog();
          }
        },
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add actual sign out logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}