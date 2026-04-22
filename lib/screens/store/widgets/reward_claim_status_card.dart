import 'package:flutter/material.dart';
import '../../../core/models/store/store_stock_ui_model.dart';
import 'stock_reset_timer.dart';
import 'store_purchase_button.dart';

/// Specialised card for free-claim / ad-reward / streak-reward flows.
///
/// Displays reward title, current and remaining claim count, next reset time,
/// and a claim button that respects stock state.
class RewardClaimStatusCard extends StatelessWidget {
  final PlayerStoreItem item;

  /// Number of times the player has claimed today.
  final int claimedCount;

  /// Maximum claims allowed per reset interval.
  final int maxClaims;

  final Future<void> Function()? onClaim;

  const RewardClaimStatusCard({
    super.key,
    required this.item,
    required this.claimedCount,
    required this.maxClaims,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (maxClaims - claimedCount).clamp(0, maxClaims);
    final isExhausted = remaining == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExhausted
              ? const Color(0xFF64748B).withValues(alpha: 0.1)
              : const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isExhausted
                ? Colors.transparent
                : const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isExhausted
                      ? const Color(0xFF64748B).withValues(alpha: 0.08)
                      : const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 18,
                  color: isExhausted
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isExhausted
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      item.description,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Claim count row
          Row(
            children: [
              _ClaimDot(filled: claimedCount >= 1, isExhausted: isExhausted),
              for (int i = 1; i < maxClaims; i++) ...[
                const SizedBox(width: 4),
                _ClaimDot(
                    filled: i < claimedCount, isExhausted: isExhausted),
              ],
              const SizedBox(width: 8),
              Text(
                '$remaining claim${remaining == 1 ? '' : 's'} remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: isExhausted
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Reset timer + claim button
          Row(
            children: [
              if (item.stock.nextResetAt != null) ...[
                Expanded(
                  child: StockResetTimer(
                    nextResetAt: item.stock.nextResetAt,
                    expiresAt: item.stock.expiresAt,
                  ),
                ),
              ] else
                const Spacer(),
              StorePurchaseButton(
                item: isExhausted
                    ? PlayerStoreItem(
                        sku: item.sku,
                        title: item.title,
                        description: item.description,
                        type: item.type,
                        price: 0,
                        currency: 'free',
                        owned: true, // forces "Claimed" state
                        stock: item.stock,
                        availability: item.availability,
                      )
                    : item,
                onPressed: isExhausted ? null : onClaim,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClaimDot extends StatelessWidget {
  final bool filled;
  final bool isExhausted;

  const _ClaimDot({required this.filled, required this.isExhausted});

  @override
  Widget build(BuildContext context) {
    final color = isExhausted
        ? const Color(0xFF94A3B8)
        : filled
            ? const Color(0xFF6366F1)
            : const Color(0xFFE2E8F0);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: filled
              ? Colors.transparent
              : const Color(0xFF94A3B8).withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
