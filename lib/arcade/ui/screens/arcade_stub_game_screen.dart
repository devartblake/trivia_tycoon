import 'package:flutter/material.dart';

class ArcadeStubGameScreen extends StatelessWidget {
  const ArcadeStubGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Arcade Game (Stub)')),
      body: const Center(
        child: Text(
          'Game implementation goes here.\n\nNext step: Pattern Sprint first.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
