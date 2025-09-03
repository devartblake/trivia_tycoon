import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trivia_tycoon/screens/splash_variants/widgets/background_parallax.dart';
import 'package:trivia_tycoon/screens/splash_variants/widgets/golden_trivia_coin.dart';
import 'package:trivia_tycoon/screens/splash_variants/widgets/ticker_tape_widget.dart';
import 'package:trivia_tycoon/screens/splash_variants/widgets/typing_trivia_logo.dart';

class MindMarketSplash extends StatefulWidget {
  final VoidCallback onStart;

  const MindMarketSplash({super.key, required this.onStart});

  @override
  State<MindMarketSplash> createState() => _MindMarketSplashState();
}

class _MindMarketSplashState extends State<MindMarketSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coinSpinController;

  @override
  void initState() {
    super.initState();
    _coinSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Optional sound effect
    //AudioPlayer().play(AssetSource('sounds/ticker_loop.mp3'));
  }

  @override
  void dispose() {
    _coinSpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: BackgroundParallax()),
          Align(
            alignment: Alignment.topCenter,
            child: const TickerTapeWidget(), // scrolling emoji ticker
          ),
          Center(child: GoldenTriviaCoin()),
          Align(
            alignment: Alignment.bottomCenter,
            child: TypingTriviaLogo(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Shimmer.fromColors(
                baseColor: Colors.black87,
                highlightColor: Colors.grey.shade800,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
