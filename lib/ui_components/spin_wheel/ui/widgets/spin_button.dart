import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../services/spin_tracker.dart';

class SpinButton extends ConsumerStatefulWidget {
  final VoidCallback onSpin;
  final bool isSpinning;

  const SpinButton({
    super.key,
    required this.onSpin,
    this.isSpinning = false,
  });

  @override
  ConsumerState<SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends ConsumerState<SpinButton>
    with TickerProviderStateMixin {
  bool _canSpin = false;
  Duration _cooldownLeft = Duration.zero;
  Timer? _updateTimer;

  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _buttonController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkSpinEligibility();
    _startPeriodicUpdates();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkSpinEligibility();
    });
  }

  @override
  void didUpdateWidget(SpinButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _spinController.repeat();
        _pulseController.stop();
      } else {
        _spinController.stop();
        _spinController.reset();
        if (_canSpin) {
          _pulseController.repeat(reverse: true);
        }
      }
    }
  }

  Future<void> _checkSpinEligibility() async {
    final canSpin = await SpinTracker.canSpin();
    final timeLeft = await SpinTracker.timeLeft();

    if (!mounted) return;

    final wasCanSpin = _canSpin;
    setState(() {
      _canSpin = canSpin;
      _cooldownLeft = timeLeft;
    });

    // Start pulse animation when spins become available
    if (canSpin && !wasCanSpin && !widget.isSpinning) {
      _pulseController.repeat(reverse: true);
      _showSpinAvailableNotification();
    } else if (!canSpin) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _showSpinAvailableNotification() {
    if (_canSpin) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.casino, color: Colors.white),
              const SizedBox(width: 8),
              Text('Spin is now available!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSpin() async {
    if (!_canSpin || widget.isSpinning) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Button press animation
    await _buttonController.forward();
    _buttonController.reverse();

    await SpinTracker.registerSpin();
    _scheduleCooldownNotification();
    widget.onSpin();
    await _checkSpinEligibility();
  }

  void _scheduleCooldownNotification() {
    final readyTime = DateTime.now().add(SpinTracker.cooldown);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'spin_channel',
        title: '🎉 Your spin is ready!',
        body: 'Come back and spin again!',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        year: readyTime.year,
        month: readyTime.month,
        day: readyTime.day,
        hour: readyTime.hour,
        minute: readyTime.minute,
        second: 0,
        millisecond: 0,
        allowWhileIdle: true,
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    _spinController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildMainSpinButton(theme),
        const SizedBox(height: 16),
        _buildStatusIndicator(theme),
      ],
    );
  }

  Widget _buildMainSpinButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _spinAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * (_canSpin ? _pulseAnimation.value : 1.0),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _buildButtonGradient(),
              boxShadow: _buildButtonShadow(),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _canSpin && !widget.isSpinning ? _handleSpin : null,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: widget.isSpinning
                            ? _spinAnimation.value * 3.14159
                            : 0,
                        child: Icon(
                          Icons.casino,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isSpinning ? 'SPINNING' : 'SPIN',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _buildButtonGradient() {
    if (widget.isSpinning) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.purple, Colors.blue, Colors.purple],
      );
    } else if (_canSpin) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _colorAnimation.value ?? Colors.blue,
          Colors.blue.shade600,
          Colors.blue.shade800,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade500,
          Colors.grey.shade600,
        ],
      );
    }
  }

  List<BoxShadow> _buildButtonShadow() {
    if (_canSpin && !widget.isSpinning) {
      return [
        BoxShadow(
          color: Colors.blue.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.blue.withOpacity(0.2),
          blurRadius: 40,
          spreadRadius: 5,
          offset: const Offset(0, 12),
        ),
      ];
    } else if (widget.isSpinning) {
      return [
        BoxShadow(
          color: Colors.purple.withOpacity(0.4),
          blurRadius: 25,
          spreadRadius: 3,
          offset: const Offset(0, 8),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    if (widget.isSpinning) {
      return _buildSpinningIndicator(theme);
    } else if (_canSpin) {
      return _buildReadyIndicator(theme);
    } else {
      return _buildCooldownIndicator(theme);
    }
  }

  Widget _buildSpinningIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Spinning...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Ready to Spin!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Next spin: ${_formatDuration(_cooldownLeft)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'Now!';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}