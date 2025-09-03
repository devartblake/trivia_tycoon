import 'package:flutter/material.dart';

class GameTimer extends StatefulWidget {
  final int duration;
  final VoidCallback onTimeUp;

  const GameTimer({super.key, required this.duration, required this.onTimeUp});

  @override
  _GameTimerState createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int remainingTime;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.duration;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..addListener(() {
      setState(() {
        remainingTime = widget.duration - _controller.value.toInt();
      });
    });

    _controller.forward().whenComplete(() {
      widget.onTimeUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            value: 1 - _controller.value,
            strokeWidth: 6,
            color: Colors.red,
          ),
        ),
        Text(
          remainingTime.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
