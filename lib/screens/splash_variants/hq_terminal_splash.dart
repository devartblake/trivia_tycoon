import 'package:flutter/material.dart';

class HqTerminalSplash extends StatefulWidget {
  final VoidCallback onStart;

  const HqTerminalSplash({super.key, required this.onStart});

  @override
  State<HqTerminalSplash> createState() => _HqTerminalSplashState();
}

class _HqTerminalSplashState extends State<HqTerminalSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), widget.onStart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("[BOOTING TRIVIA MAINFRAME]",
                style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier')),
            SizedBox(height: 8),
            Text("[CALIBRATING CURIOSITY ENGINE...]",
                style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier')),
            SizedBox(height: 8),
            Text("[STATUS: READY]",
                style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier')),
          ],
        ),
      ),
    );
  }
}
