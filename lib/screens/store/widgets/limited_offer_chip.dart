import 'package:flutter/material.dart';

enum LimitedOfferKind { flashSale, weekendOffer, seasonal, limitedBundle }

/// Chip that calls out rotating inventory, seasonal promotions, and flash offers.
/// Separate from [StockBadge] — distinguishes promotion type from stock count.
class LimitedOfferChip extends StatelessWidget {
  final LimitedOfferKind kind;
  final String? customLabel;

  const LimitedOfferChip({
    super.key,
    required this.kind,
    this.customLabel,
  });

  factory LimitedOfferChip.fromLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('flash')) return const LimitedOfferChip(kind: LimitedOfferKind.flashSale);
    if (lower.contains('weekend')) return const LimitedOfferChip(kind: LimitedOfferKind.weekendOffer);
    if (lower.contains('season')) return const LimitedOfferChip(kind: LimitedOfferKind.seasonal);
    return const LimitedOfferChip(kind: LimitedOfferKind.limitedBundle);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cfg.gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cfg.gradient.first.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, color: Colors.white, size: 10),
          const SizedBox(width: 4),
          Text(
            customLabel ?? cfg.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _ChipConfig _config() {
    switch (kind) {
      case LimitedOfferKind.flashSale:
        return _ChipConfig(
          label: 'Flash Sale',
          icon: Icons.bolt,
          gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        );
      case LimitedOfferKind.weekendOffer:
        return _ChipConfig(
          label: 'Weekend Offer',
          icon: Icons.weekend,
          gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        );
      case LimitedOfferKind.seasonal:
        return _ChipConfig(
          label: 'Seasonal',
          icon: Icons.auto_awesome,
          gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        );
      case LimitedOfferKind.limitedBundle:
        return _ChipConfig(
          label: 'Limited Bundle',
          icon: Icons.local_offer,
          gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        );
    }
  }
}

class _ChipConfig {
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _ChipConfig({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}
