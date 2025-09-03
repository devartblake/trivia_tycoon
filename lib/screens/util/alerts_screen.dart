import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        leading: IconButton( // ✅ Back button to return to previous screen
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Navigate back
          },
        ),
      ),
      body: const Center(child: Text('Alerts Screen Placeholder')),
    );
  }
}