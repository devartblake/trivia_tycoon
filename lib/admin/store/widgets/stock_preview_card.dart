import 'package:flutter/material.dart';
import '../../../../core/models/store/store_stock_ui_model.dart';
import '../../../../screens/store/widgets/stock_badge.dart';
import '../../../../screens/store/widgets/stock_meter_bar.dart';
import '../../../../screens/store/widgets/stock_reset_timer.dart';
import '../../../../screens/store/widgets/sold_out_overlay.dart';
import '../../../../screens/store/widgets/limited_offer_chip.dart';

/// Preview input parameters for admin preview mode.
class StockPreviewInput {
  final String playerTier; // free | premium | elite
  final bool isPremium;
  final int playerLevel;
  final int currentUsedQuantity;
  final bool isFlashSaleEligible;

  const StockPreviewInput({
    this.playerTier = 'free',
    this.isPremium = false,
    this.playerLevel = 1,
    this.currentUsedQuantity = 0,
    this.isFlashSaleEligible = false,
  });
}

/// Renders the same card a player would see, using draft policy values.
/// Used in admin preview mode before publishing stock changes.
class StockPreviewCard extends StatelessWidget {
  final PlayerStoreItem item;
  final StockPreviewInput previewInput;

  const StockPreviewCard({
    super.key,
    required this.item,
    required this.previewInput,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedItem = _applyPreview();
    final stock = resolvedItem.stock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview banner
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.preview_outlined,
                  size: 12, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                'Preview — ${previewInput.playerTier.toUpperCase()} player, level ${previewInput.playerLevel}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // Card
        SoldOutOverlay(
          isSoldOut: stock.isSoldOut,
          nextResetAt: stock.nextResetAt,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF64748B).withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: title + badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        resolvedItem.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StockBadge(
                      label: _badgeLabel(stock),
                      isSoldOut: stock.isSoldOut,
                      isUnlimited: stock.isUnlimited,
                      isOwned: stock.isOneTimePurchase && resolvedItem.owned,
                      isUrgent: stock.hasUrgentStock,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  resolvedItem.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Flash sale chip
                if (resolvedItem.availability.isFlashSale) ...[
                  const LimitedOfferChip(kind: LimitedOfferKind.flashSale),
                  const SizedBox(height: 8),
                ],

                // Stock meter
                if (!stock.isUnlimited &&
                    stock.maxQuantity != null &&
                    stock.remainingQuantity != null) ...[
                  StockMeterBar(
                    remaining: stock.remainingQuantity!,
                    max: stock.maxQuantity!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Timer
                if (stock.nextResetAt != null || stock.expiresAt != null)
                  StockResetTimer(
                    nextResetAt: stock.nextResetAt,
                    expiresAt: stock.expiresAt,
                    preferExpiry: resolvedItem.availability.isFlashSale,
                  ),

                const SizedBox(height: 10),

                // Price + button
                Row(
                  children: [
                    Icon(
                      resolvedItem.currency == 'diamonds'
                          ? Icons.diamond
                          : Icons.monetization_on,
                      color: resolvedItem.currency == 'diamonds'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF59E0B),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resolvedItem.isFree
                          ? 'Free'
                          : resolvedItem.price.toString(),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    _PreviewButton(item: resolvedItem),
                  ],
                ),

                // Restriction note
                if (!previewInput.isPremium &&
                    resolvedItem.availability.requiresPremium) ...[
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline,
                          color: Color(0xFF8B5CF6), size: 12),
                      SizedBox(width: 4),
                      Text('Premium required',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF8B5CF6))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Applies preview inputs to the item's stock state.
  PlayerStoreItem _applyPreview() {
    final rawRemaining = item.stock.maxQuantity != null
        ? (item.stock.maxQuantity! - previewInput.currentUsedQuantity)
            .clamp(0, item.stock.maxQuantity!)
        : item.stock.remainingQuantity;

    final adjustedStock = StoreStockState(
      policyType: item.stock.policyType,
      maxQuantity: item.stock.maxQuantity,
      usedQuantity: previewInput.currentUsedQuantity,
      remainingQuantity: rawRemaining,
      resetInterval: item.stock.resetInterval,
      lastResetAt: item.stock.lastResetAt,
      nextResetAt: item.stock.nextResetAt,
      isSoldOut: rawRemaining == 0 && !item.stock.isUnlimited,
      isUnlimited: item.stock.isUnlimited,
      isOneTimePurchase: item.stock.isOneTimePurchase,
      expiresAt: item.stock.expiresAt,
    );

    final adjustedAvail = StoreAvailabilityState(
      isVisible: item.availability.isVisible,
      isPurchasable: item.availability.isPurchasable &&
          (previewInput.isPremium || !item.availability.requiresPremium),
      requiresPremium: item.availability.requiresPremium,
      isFlashSale: item.availability.isFlashSale || previewInput.isFlashSaleEligible,
      saleEndsAt: item.availability.saleEndsAt,
    );

    return PlayerStoreItem(
      sku: item.sku,
      title: item.title,
      description: item.description,
      type: item.type,
      price: item.price,
      currency: item.currency,
      stock: adjustedStock,
      availability: adjustedAvail,
      iconPath: item.iconPath,
      thumbnailUrl: item.thumbnailUrl,
      owned: item.owned,
      isFeatured: item.isFeatured,
    );
  }

  String _badgeLabel(StoreStockState stock) {
    if (stock.isSoldOut) return 'Sold Out';
    if (stock.isOneTimePurchase) return 'One-Time';
    if (stock.isUnlimited) return 'Unlimited';
    final r = stock.remainingQuantity;
    if (r != null) return '$r Left';
    return 'Limited';
  }
}

class _PreviewButton extends StatelessWidget {
  final PlayerStoreItem item;

  const _PreviewButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final canBuy = item.canPurchase;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: canBuy
            ? const Color(0xFF6366F1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: canBuy ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }

  String _label() {
    if (item.stock.isSoldOut) return 'Sold Out';
    if (item.stock.isOneTimePurchase && item.owned) return 'Owned';
    if (!item.availability.isPurchasable) return 'Unavailable';
    if (item.availability.requiresPremium) return 'Premium Only';
    if (item.isFree) return 'Claim';
    return 'Buy';
  }
}
