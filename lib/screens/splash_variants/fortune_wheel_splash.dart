import 'dart:math';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class FortuneWheelSplash extends StatefulWidget {
  final VoidCallback onStart;

  const FortuneWheelSplash({super.key, required this.onStart});

  @override
  State<FortuneWheelSplash> createState() => _FortuneWheelSplashState();
}

class _FortuneWheelSplashState extends State<FortuneWheelSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  bool _showLogo = false;
  bool _showStartButton = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _victoryPlayer = AudioPlayer();

  final List<String> categories = [
    "🧠 Science", "📚 History", "🧮 Math", "🎭 Arts", "🌍 Geography", "🎩 Logic"
  ];

  @override
  void initState() {
    super.initState();
    final randomTurns = 5 + Random().nextInt(3); // 5–7 full spins

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _rotation = Tween<double>(
      begin: 0,
      end: 2 * pi * randomTurns + (2 * pi / categories.length) * Random().nextInt(categories.length),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc))
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          await _victoryPlayer.setAsset('assets/sounds/victory.mp3');
          await _victoryPlayer.play();

          setState(() {
            _showLogo = true;
          });
          Future.delayed(const Duration(seconds: 1), () {
            setState(() => _showStartButton = true);
          });
        }
      });

    _controller.forward();

    _audioPlayer.setAsset('assets/sounds/spin.mp3').then((_) {
      _audioPlayer.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _victoryPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wheel (Spinning)
            AnimatedBuilder(
              animation: _rotation,
              builder: (_, __) => SizedBox(
                width: 380,
                height: 380,
                child: Transform.rotate(
                  angle: _rotation.value,
                  child: CustomPaint(
                    painter: WheelPainter(categories),
                  ),
                ),
              ),
            ),

            // Start Button (immediately after wheel)
            if (_showStartButton)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: widget.onStart,
                  child: const Text("Start", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),

            const SizedBox(height: 16),

            // Shimmering Logo
            if (_showLogo)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Shimmer.fromColors(
                  baseColor: Colors.amber,
                  highlightColor: Colors.blueGrey,
                  child: const Text(
                    "Trivia Tycoon",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> categories;
  final List<Color> sliceColors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.orange,
    Colors.pinkAccent,
    Colors.green,
    Colors.indigo,
  ];

  WheelPainter(this.categories);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = 2 * pi / categories.length;
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < categories.length; i++) {
      paint.color = sliceColors[i % sliceColors.length].withOpacity(0.9);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * angle,
        angle,
        true,
        paint,
      );
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);

    for (int i = 0; i < categories.length; i++) {
      final labelAngle = (i + 0.5) * angle;
      final labelX = center.dx + cos(labelAngle) * radius * 0.60;
      final labelY = center.dy + sin(labelAngle) * radius * 0.60;

      textPainter.text = TextSpan(text: categories[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
