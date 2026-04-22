import 'package:flutter/material.dart';
import '../../../core/models/store/store_stock_ui_model.dart';
import 'stock_badge.dart';
import 'stock_meter_bar.dart';
import 'stock_reset_timer.dart';

/// Composed block centralizing all stock information for a single store item.
/// Intended to sit beneath the item art / title inside a store card.
class StoreItemStockPanel extends StatelessWidget {
  final PlayerStoreItem item;

  const StoreItemStockPanel({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final stock = item.stock;
    final avail = item.availability;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge row
        _buildBadgeRow(stock),

        // Meter (skip for unlimited / owned one-time)
        if (!stock.isUnlimited &&
            !(stock.isOneTimePurchase && item.owned) &&
            stock.maxQuantity != null &&
            stock.remainingQuantity != null) ...[
          const SizedBox(height: 6),
          StockMeterBar(
            remaining: stock.remainingQuantity!,
            max: stock.maxQuantity!,
          ),
        ],

        // Reset / expiry timer
        if (_showTimer(stock, avail)) ...[
          const SizedBox(height: 6),
          StockResetTimer(
            nextResetAt: stock.nextResetAt,
            expiresAt: stock.expiresAt ?? avail.saleEndsAt,
            preferExpiry: avail.isFlashSale,
          ),
        ],

        // Restriction note
        if (_restrictionNote(stock, avail) != null) ...[
          const SizedBox(height: 4),
          Text(
            _restrictionNote(stock, avail)!,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadgeRow(StoreStockState stock) {
    final label = _badgeLabel(stock);
    return StockBadge(
      label: label,
      isSoldOut: stock.isSoldOut,
      isUnlimited: stock.isUnlimited,
      isOwned: stock.isOneTimePurchase && item.owned,
      isUrgent: stock.hasUrgentStock,
    );
  }

  String _badgeLabel(StoreStockState stock) {
    if (stock.isSoldOut) return 'Sold Out';
    if (stock.isOneTimePurchase && item.owned) return 'Owned';
    if (stock.isUnlimited) return 'Unlimited';
    final remaining = stock.remainingQuantity;
    if (remaining != null) {
      if (remaining == 1) return '1 Left';
      if (remaining <= 5) return '$remaining Left';
    }
    if (stock.resetInterval != null) {
      switch (stock.resetInterval) {
        case 'daily':
          return 'Resets Daily';
        case 'weekly':
          return 'Weekly Item';
        case 'hourly':
          return 'Hourly Item';
        case 'seasonal':
          return 'Seasonal';
      }
    }
    if (stock.isOneTimePurchase) return 'One-Time';
    return 'Limited';
  }

  bool _showTimer(StoreStockState stock, StoreAvailabilityState avail) {
    if (stock.nextResetAt != null) return true;
    if (stock.expiresAt != null) return true;
    if (avail.saleEndsAt != null) return true;
    return false;
  }

  String? _restrictionNote(
      StoreStockState stock, StoreAvailabilityState avail) {
    if (avail.requiresPremium) return 'Premium required';
    if (stock.isOneTimePurchase && item.owned) return 'Already owned';
    if (stock.isSoldOut && stock.nextResetAt != null) return 'Check back later';
    if (avail.isFlashSale) return 'Offer ends tonight';
    return null;
  }
}
