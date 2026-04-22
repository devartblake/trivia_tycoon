import 'package:flutter/material.dart';
import 'stock_reset_timer.dart';

/// Wraps a store card with a sold-out overlay.
/// Keeps title and art visible; optionally shows reset timer if stock will return.
class SoldOutOverlay extends StatelessWidget {
  final Widget child;
  final bool isSoldOut;
  final DateTime? nextResetAt;

  const SoldOutOverlay({
    super.key,
    required this.child,
    required this.isSoldOut,
    this.nextResetAt,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSoldOut) return child;

    return Stack(
      children: [
        // Dimmed card
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      0.6, 0,
          ]),
          child: child,
        ),

        // Overlay label
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block,
                              color: Color(0xFFEF4444), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (nextResetAt != null) ...[
                        const SizedBox(height: 4),
                        StockResetTimer(nextResetAt: nextResetAt),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
