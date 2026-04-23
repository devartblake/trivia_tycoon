import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/store/daily_store_model.dart';
import '../../game/providers/game_providers.dart';
import '../../game/providers/store_stock_providers.dart';

class DailyItemsScreen extends ConsumerStatefulWidget {
  const DailyItemsScreen({super.key});

  @override
  ConsumerState<DailyItemsScreen> createState() => _DailyItemsScreenState();
}

class _DailyItemsScreenState extends ConsumerState<DailyItemsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  // Schedule a one-shot timer to invalidate the provider when the daily reset
  // fires. This means the new item slate loads automatically for users who
  // keep the screen open through midnight UTC.
  void _scheduleAutoRefresh(DailyStoreData data) {
    _resetTimer?.cancel();
    final remaining = data.timeUntilReset;
    if (remaining.isNegative) {
      ref.invalidate(dailyStoreProvider);
      return;
    }
    _resetTimer = Timer(remaining, () {
      if (mounted) ref.invalidate(dailyStoreProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyStoreProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(dailyAsync),
      body: FadeTransition(
        opacity: _fadeController,
        child: dailyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(e),
          data: (data) {
            _scheduleAutoRefresh(data);
            return _buildBody(data);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AsyncValue<DailyStoreData> async) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 18),
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Daily Items',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.refresh,
                color: Color(0xFF10B981), size: 20),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.invalidate(dailyStoreProvider);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(DailyStoreData data) {
    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: () async => ref.invalidate(dailyStoreProvider),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildResetBanner(data)),
          if (data.bannerMessage != null)
            SliverToBoxAdapter(child: _buildInfoBanner(data.bannerMessage!)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: data.items.isEmpty
                ? const SliverFillRemaining(child: _EmptyState())
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _DailyItemCard(item: data.items[i]),
                      childCount: data.items.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetBanner(DailyStoreData data) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restocks in',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                _ResetCountdown(nextResetAt: data.nextResetAt),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data.items.length} items',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load daily items.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(dailyStoreProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reset countdown — live ticking from the shared stockCountdownProvider
// ---------------------------------------------------------------------------

class _ResetCountdown extends ConsumerWidget {
  final DateTime nextResetAt;
  const _ResetCountdown({required this.nextResetAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stockCountdownProvider); // rebuilds every second

    final diff = nextResetAt.toUtc().difference(DateTime.now().toUtc());

    if (diff.isNegative) {
      return const Text(
        'Refreshing…',
        style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      );
    }

    final String label;
    if (diff.inDays >= 1) {
      label =
          '${diff.inDays}d ${diff.inHours.remainder(24).toString().padLeft(2, '0')}h';
    } else {
      final h = diff.inHours.remainder(24).toString().padLeft(2, '0');
      final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      label = '$h:$m:$s';
    }

    return Text(
      label,
      style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual item card
// ---------------------------------------------------------------------------

class _DailyItemCard extends StatelessWidget {
  final DailyStoreItem item;
  const _DailyItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = dailyItemColor(item.category);
    final icon = dailyItemIcon(item.category);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showPurchaseSheet(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + owned badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  if (item.owned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OWNED',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                item.title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Expanded(
                child: Text(
                  item.description,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              // Stock indicator (if limited)
              if (!item.stock.isUnlimited && !item.stock.isSoldOut)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StockBar(stock: item.stock),
                ),
              // Price / buy button
              _PriceButton(item: item, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseSheet(item: item),
    );
  }
}

class _StockBar extends StatelessWidget {
  final StoreStockState stock;
  const _StockBar({required this.stock});

  @override
  Widget build(BuildContext context) {
    if (stock.maxQuantity == null || stock.maxQuantity == 0) {
      return const SizedBox.shrink();
    }
    final pct =
        (stock.remainingQuantity ?? 0) / stock.maxQuantity!;
    final barColor = pct <= 0.1
        ? const Color(0xFFEF4444)
        : pct <= 0.3
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${stock.remainingQuantity ?? 0} left',
              style: TextStyle(fontSize: 9, color: barColor),
            ),
            Text(
              '/${stock.maxQuantity}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}

class _PriceButton extends StatelessWidget {
  final DailyStoreItem item;
  final Color color;
  const _PriceButton({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    if (item.owned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Owned',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8))),
        ),
      );
    }
    if (item.stock.isSoldOut) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Sold Out',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8))),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isCoins ? Icons.monetization_on : Icons.credit_card,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              item.isFree ? 'Free' : '${item.price}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Purchase confirmation sheet
// ---------------------------------------------------------------------------

class _PurchaseSheet extends StatelessWidget {
  final DailyStoreItem item;
  const _PurchaseSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = dailyItemColor(item.category);
    final icon = dailyItemIcon(item.category);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.description,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price',
                    style: TextStyle(color: Color(0xFF64748B))),
                Row(
                  children: [
                    Icon(
                      item.isCoins
                          ? Icons.monetization_on
                          : Icons.credit_card,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isFree ? 'Free' : '${item.price} ${item.currency}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: item.owned || item.stock.isSoldOut
                  ? null
                  : () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                item.owned
                    ? 'Already Owned'
                    : item.stock.isSoldOut
                        ? 'Sold Out'
                        : item.isFree
                            ? 'Claim Free'
                            : 'Buy Now',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_mall_directory_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No daily items today.',
              style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          const Text('Check back after the next restock.',
              style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
        ],
      ),
    );
  }
}
