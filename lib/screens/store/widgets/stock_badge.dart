import 'package:flutter/material.dart';

/// Compact badge showing an item's current stock state.
/// Intended for top-right card corners, inline beside titles, or compact overlays.
class StockBadge extends StatelessWidget {
  final String label;
  final bool isUrgent;
  final bool isSoldOut;
  final bool isUnlimited;
  final bool isOwned;

  const StockBadge({
    super.key,
    required this.label,
    this.isUrgent = false,
    this.isSoldOut = false,
    this.isUnlimited = false,
    this.isOwned = false,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, color: cfg.fg, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: cfg.fg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config() {
    if (isSoldOut) {
      return _BadgeConfig(
        bg: const Color(0xFFEF4444).withValues(alpha: 0.1),
        fg: const Color(0xFFEF4444),
        border: const Color(0xFFEF4444).withValues(alpha: 0.3),
        icon: Icons.block,
      );
    }
    if (isOwned) {
      return _BadgeConfig(
        bg: const Color(0xFF10B981).withValues(alpha: 0.1),
        fg: const Color(0xFF10B981),
        border: const Color(0xFF10B981).withValues(alpha: 0.3),
        icon: Icons.check_circle_outline,
      );
    }
    if (isUnlimited) {
      return _BadgeConfig(
        bg: const Color(0xFF6366F1).withValues(alpha: 0.08),
        fg: const Color(0xFF6366F1),
        border: const Color(0xFF6366F1).withValues(alpha: 0.2),
        icon: Icons.all_inclusive,
      );
    }
    if (isUrgent) {
      return _BadgeConfig(
        bg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        fg: const Color(0xFFD97706),
        border: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        icon: Icons.local_fire_department,
      );
    }
    return _BadgeConfig(
      bg: const Color(0xFF64748B).withValues(alpha: 0.08),
      fg: const Color(0xFF475569),
      border: const Color(0xFF64748B).withValues(alpha: 0.2),
      icon: Icons.inventory_2_outlined,
    );
  }
}

class _BadgeConfig {
  final Color bg;
  final Color fg;
  final Color border;
  final IconData icon;

  const _BadgeConfig({
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
  });
}
