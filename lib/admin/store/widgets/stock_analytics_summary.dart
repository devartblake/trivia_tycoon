import 'package:flutter/material.dart';

/// Analytics summary panel showing key store stock metrics.
/// Accepts the raw map from GET /admin/store/analytics/summary.
class StockAnalyticsSummary extends StatelessWidget {
  final Map<String, dynamic> data;

  const StockAnalyticsSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKpiRow(),
        const SizedBox(height: 16),
        _buildTopItemsSection(),
        const SizedBox(height: 16),
        _buildResetIntervalBreakdown(),
      ],
    );
  }

  Widget _buildKpiRow() {
    final kpis = [
      _Kpi(
        label: 'Purchases',
        value: _fmt(data['totalPurchases']),
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF6366F1),
      ),
      _Kpi(
        label: 'Sold-Out Rate',
        value: '${_pct(data['soldOutRate'])}%',
        icon: Icons.block,
        color: const Color(0xFFEF4444),
      ),
      _Kpi(
        label: 'Reward Claims',
        value: _fmt(data['totalRewardClaims']),
        icon: Icons.card_giftcard,
        color: const Color(0xFF10B981),
      ),
      _Kpi(
        label: 'Flash Conversions',
        value: '${_pct(data['flashConversionRate'])}%',
        icon: Icons.bolt,
        color: const Color(0xFFF59E0B),
      ),
      _Kpi(
        label: 'Premium Upgrades',
        value: _fmt(data['premiumConversions']),
        icon: Icons.workspace_premium,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis
          .map((k) => SizedBox(width: 160, child: _KpiCard(kpi: k)))
          .toList(),
    );
  }

  Widget _buildTopItemsSection() {
    final topSelling =
        (data['topSellingItems'] as List<dynamic>?) ?? const [];
    final mostSoldOut =
        (data['mostFrequentlySoldOutItems'] as List<dynamic>?) ?? const [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: _ItemListCard(
          title: 'Top Selling',
          icon: Icons.trending_up,
          color: const Color(0xFF6366F1),
          items: topSelling,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _ItemListCard(
          title: 'Frequently Sold Out',
          icon: Icons.timer_off_outlined,
          color: const Color(0xFFEF4444),
          items: mostSoldOut,
        )),
      ],
    );
  }

  Widget _buildResetIntervalBreakdown() {
    final breakdown = data['claimsByResetInterval'];
    if (breakdown is! Map) return const SizedBox.shrink();

    final entries = Map<String, dynamic>.from(breakdown).entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold<num>(
        0, (sum, e) => sum + ((e.value as num?) ?? 0));

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.refresh, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                const Text('Claims by Reset Interval',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.map((e) {
              final count = (e.value as num?)?.toInt() ?? 0;
              final fraction = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key[0].toUpperCase() + e.key.substring(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(count.toString(),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            const Color(0xFF10B981).withValues(alpha: 0.1),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final n = (v as num).toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _pct(dynamic v) {
    if (v == null) return '—';
    return (v as num).toStringAsFixed(1);
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;

  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: kpi.color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(kpi.icon, color: kpi.color, size: 18),
          const SizedBox(height: 8),
          Text(kpi.value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kpi.color)),
          const SizedBox(height: 2),
          Text(kpi.label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ItemListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;

  const _ItemListCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('No data yet',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]))
            else
              ...items.take(5).map((item) {
                final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                final sku = (m['sku'] ?? m['id'] ?? '').toString();
                final count = m['count']?.toString() ?? '—';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(sku,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(count,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
