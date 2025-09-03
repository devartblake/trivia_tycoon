import 'package:flutter/material.dart';

class VaultSplash extends StatefulWidget {
  final VoidCallback onStart;

  const VaultSplash({super.key, required this.onStart});

  @override
  State<VaultSplash> createState() => _VaultSplashState();
}

class _VaultSplashState extends State<VaultSplash> {
@override
void initState() {
  super.initState();
  Future.delayed(const Duration(seconds: 3), widget.onStart);
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.amber, size: 100),
            const SizedBox(height: 16),
            const Text(
              'Unlocking Knowledge...',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}