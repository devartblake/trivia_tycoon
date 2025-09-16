import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClassQuizScreen extends StatelessWidget {
  final String classLevel;

  const ClassQuizScreen({
    super.key,
    required this.classLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class $classLevel Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Class $classLevel Quiz',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Educational content coming in Phase 2',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}