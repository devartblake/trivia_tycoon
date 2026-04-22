import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/store/store_stock_ui_model.dart';
import '../../../game/providers/riverpod_providers.dart';

/// Purchase / claim CTA that reacts to stock state automatically.
///
/// States derive from [item]:
/// - Buy / Claim — purchasable
/// - Owned — one-time purchase already owned
/// - Sold Out — isSoldOut
/// - Claimed — free item already used
/// - Premium Only — requiresPremium and not subscribed
/// - Unavailable — any other non-purchasable reason
class StorePurchaseButton extends ConsumerWidget {
  final PlayerStoreItem item;
  final Future<void> Function()? onPressed;
  final bool compact;

  const StorePurchaseButton({
    super.key,
    required this.item,
    this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumAccessStatusProvider).maybeWhen(
          data: (s) => s.isPremium,
          orElse: () => false,
        );

    final cfg = _resolveState(isPremium);

    return SizedBox(
      height: compact ? 32 : 40,
      child: ElevatedButton.icon(
        onPressed: cfg.enabled ? _onTap : null,
        icon: cfg.loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            : Icon(cfg.icon, size: compact ? 13 : 15),
        label: Text(
          cfg.label,
          style: TextStyle(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cfg.enabled ? cfg.color : Colors.grey.shade300,
          foregroundColor: cfg.enabled ? Colors.white : Colors.grey.shade600,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 6 : 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 8 : 12),
          ),
        ),
      ),
    );
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }

  _ButtonState _resolveState(bool isPremium) {
    final stock = item.stock;
    final avail = item.availability;

    if (stock.isOneTimePurchase && item.owned) {
      return _ButtonState(
        label: 'Owned',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF10B981),
        enabled: false,
      );
    }

    if (avail.requiresPremium && !isPremium) {
      return _ButtonState(
        label: 'Premium Only',
        icon: Icons.workspace_premium,
        color: const Color(0xFF8B5CF6),
        enabled: false,
      );
    }

    if (stock.isSoldOut) {
      return _ButtonState(
        label: 'Sold Out',
        icon: Icons.block,
        color: const Color(0xFFEF4444),
        enabled: false,
      );
    }

    if (stock.isExpired) {
      return _ButtonState(
        label: 'Expired',
        icon: Icons.timer_off_outlined,
        color: const Color(0xFF94A3B8),
        enabled: false,
      );
    }

    if (!avail.isPurchasable) {
      return _ButtonState(
        label: 'Unavailable',
        icon: Icons.do_not_disturb_outlined,
        color: const Color(0xFF94A3B8),
        enabled: false,
      );
    }

    if (item.isFree) {
      return _ButtonState(
        label: item.owned ? 'Claimed' : 'Claim',
        icon: item.owned ? Icons.done_all : Icons.card_giftcard,
        color: const Color(0xFF10B981),
        enabled: !item.owned,
      );
    }

    return _ButtonState(
      label: 'Buy',
      icon: Icons.shopping_cart_outlined,
      color: const Color(0xFF6366F1),
      enabled: true,
    );
  }
}

class _ButtonState {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool loading;

  const _ButtonState({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    this.loading = false,
  });
}
