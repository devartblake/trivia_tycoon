import 'dart:async';
import 'package:flutter/material.dart';

class LiveCountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? timeStyle;
  final TextStyle? labelStyle;
  final VoidCallback? onTimeExpired;

  const LiveCountdownTimer({
    super.key,
    required this.endTime,
    this.timeStyle,
    this.labelStyle,
    this.onTimeExpired,
  });

  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);

    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });

    if (_timeRemaining.inSeconds <= 0) {
      _timer?.cancel();
      widget.onTimeExpired?.call();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return '${duration.inDays}d ${hours.toString().padLeft(2, '0')}h';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining.inSeconds <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Season ended",
            style: widget.labelStyle ?? const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            "Calculating results...",
            style: widget.timeStyle ?? const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Season ends in",
          style: widget.labelStyle ?? const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          _formatDuration(_timeRemaining),
          style: widget.timeStyle ?? const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
