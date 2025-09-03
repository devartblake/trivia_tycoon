import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/confetti_performance.dart';
import '../utils/confetti_log_manager.dart';

final confettiPerformanceProvider = Provider<ConfettiPerformance>((ref) {
  return ConfettiPerformance();
});

class ConfettiDebugOverlay extends ConsumerWidget {
  const ConfettiDebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(confettiPerformanceProvider);

    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "FPS: ${tracker.fps.toStringAsFixed(1)}",
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              "Memory: ${tracker.memoryUsage.toStringAsFixed(2)} MB",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                String logData =
                    "FPS: ${tracker.fps}, Memory: ${tracker.memoryUsage} MB\n";
                await ConfettiLogManager.exportLog(logData);
              },
              child: const Text('Export Logs'),
            ),
          ],
        ),
      ),
    );
  }
}
