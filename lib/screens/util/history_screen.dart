import 'package:flutter/material.dart';

/// Generic history screen placeholder.
/// Not currently wired into the router (QuizHistoryScreen handles /history);
/// kept as an extension point for future history variants.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('No history available yet.')),
    );
  }
}