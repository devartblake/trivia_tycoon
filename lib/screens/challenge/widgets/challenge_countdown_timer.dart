import 'dart:async';
import 'package:flutter/material.dart';

/// Light modern countdown timer
class ChallengeCountdownTimer extends StatefulWidget {
  final DateTime target;
  final TextStyle? style;
  final String? prefix;

  const ChallengeCountdownTimer({
    super.key,
    required this.target,
    this.style,
    this.prefix,
  });

  @override
  State<ChallengeCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<ChallengeCountdownTimer>
    with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  late Duration _remaining;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(ChallengeCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _updateRemaining();
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    _remaining = widget.target.difference(DateTime.now());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_updateRemaining);
      }
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final duration = _remaining.isNegative ? Duration.zero : _remaining;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    final text = '${widget.prefix ?? ''}$hours:$minutes:$seconds';

    return Text(
      text,
      style: widget.style ?? const TextStyle(
        color: Color(0xFF212529),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
