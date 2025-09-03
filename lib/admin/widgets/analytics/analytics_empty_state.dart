import 'package:flutter/material.dart';

class AnalyticsEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const AnalyticsEmptyState({
    super.key,
    this.message = "No data available for this period",
    this.icon = Icons.insights_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
