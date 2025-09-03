import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../services/spin_tracker.dart';

class SpinButton extends ConsumerStatefulWidget {
  final VoidCallback onSpin;

  const SpinButton({super.key, required this.onSpin});

  @override
  ConsumerState<SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends ConsumerState<SpinButton> {
  bool _canSpin = false;
  Duration _cooldownLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkSpinEligibility();
  }

  Future<void> _checkSpinEligibility() async {
    final canSpin = await SpinTracker.canSpin();
    final timeLeft = await SpinTracker.timeLeft();
    if (!mounted) return;
    setState(() {
      _canSpin = canSpin;
      _cooldownLeft = timeLeft;
    });
  }

  Future<void> _handleSpin() async {
    await SpinTracker.registerSpin();
    _scheduleCooldownNotification();
    widget.onSpin();
    _checkSpinEligibility();
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _canSpin ? _handleSpin : null,
          icon: const Icon(Icons.casino),
          label: const Text("Spin Now"),
        ),
        const SizedBox(height: 8),
        if (!_canSpin)
          Text("Next spin in: ${_formatDuration(_cooldownLeft)}",
              style: const TextStyle(color: Colors.redAccent)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
