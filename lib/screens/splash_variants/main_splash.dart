import 'dart:async';
import 'package:flutter/material.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({
    super.key,
    this.duration = const Duration(seconds: 2),
    required this.onDone,
    this.title = 'Trivia Tycoon', // safe default, no asset dependency
    this.logoAsset, // optional: e.g., 'assets/images/logo.png'
  });

  final Duration duration;
  final VoidCallback onDone;
  final String title;
  final String? logoAsset;

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.duration, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simple, safe UI that won’t crash if an asset is missing
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.logoAsset != null)
              Image.asset(
                widget.logoAsset!,
                width: 120,
                height: 120,
                errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 80, color: Colors.white),
              )
            else
              const Icon(Icons.videogame_asset, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
