import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TriviaLoadingScreen extends StatefulWidget {
  final VoidCallback onCountdownComplete;

  const TriviaLoadingScreen({super.key, required this.onCountdownComplete});

  @override
  State<TriviaLoadingScreen> createState() => _TriviaLoadingScreenState();
}

class _TriviaLoadingScreenState extends State<TriviaLoadingScreen> {
  static const int totalSeconds = 10;
  int remainingSeconds = totalSeconds;
  late Timer _timer;
  bool isReady = false;

  final List<String> triviaFacts = [
    "Did you know? Honey never spoils.",
    "Fun Fact: The Eiffel Tower can grow in summer.",
    "Trivia: Bananas are berries, but strawberries aren't!",
    "Fact: Octopuses have three hearts.",
    "Guess what? A bolt of lightning is five times hotter than the sun."
  ];

  int currentFactIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _rotateFacts();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        setState(() {
          isReady = true;
        });
        _timer.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  void _rotateFacts() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !isReady) {
        setState(() {
          currentFactIndex = (currentFactIndex + 1) % triviaFacts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _buildShimmerCard(String title) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildCountdownCircle() {
    return Positioned(
      top: 40,
      left: 20,
      child: isReady
          ? ElevatedButton(
        onPressed: widget.onCountdownComplete,
        child: const Text("Continue"),
      )
          : Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: (totalSeconds - remainingSeconds) / totalSeconds,
              strokeWidth: 4,
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
              backgroundColor: Colors.grey,
            ),
          ),
          Text(
            remainingSeconds.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildShimmerCard("🧠 Science"),
              _buildShimmerCard("📚 History"),
              _buildShimmerCard("🎭 Arts"),
              _buildShimmerCard("🎩 Logic"),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  triviaFacts[currentFactIndex],
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
          _buildCountdownCircle(),
        ],
      ),
    );
  }
}