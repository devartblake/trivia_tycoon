import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../admin/providers/admin_auth_providers.dart';
import '../providers/admin_store_providers.dart';
import '../widgets/stock_override_panel.dart';
import '../models/stock_override_form_model.dart';

/// Hub screen for all admin store controls.
/// Requires admin access (guarded by [unifiedIsAdminProvider]).
class AdminStoreInventoryScreen extends ConsumerWidget {
  const AdminStoreInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(unifiedIsAdminProvider);

    return isAdminAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _buildDenied(context),
      data: (isAdmin) {
        if (!isAdmin) return _buildDenied(context);
        return _buildContent(context, ref);
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Store Inventory Control',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage stock, sales, rewards, and overrides',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Nav grid
                _buildNavGrid(context),
                const SizedBox(height: 24),
                // Quick override panel
                const _QuickOverrideSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGrid(BuildContext context) {
    final sections = [
      _Section(
        title: 'Stock Policies',
        subtitle: 'Edit per-SKU limits, resets, and gating',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
        route: '/admin/store/policies',
      ),
      _Section(
        title: 'Flash Sales',
        subtitle: 'Schedule time-limited sale windows',
        icon: Icons.bolt,
        color: const Color(0xFFEF4444),
        route: '/admin/store/flash-sales',
      ),
      _Section(
        title: 'Reward Limits',
        subtitle: 'Tune daily claim caps and payouts',
        icon: Icons.card_giftcard,
        color: const Color(0xFF10B981),
        route: '/admin/store/reward-limits',
      ),
      _Section(
        title: 'Analytics',
        subtitle: 'Stock metrics and conversion rates',
        icon: Icons.bar_chart,
        color: const Color(0xFF8B5CF6),
        route: '/admin/store/analytics',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: sections.length,
      itemBuilder: (_, i) => _SectionCard(section: sections[i]),
    );
  }

  Widget _buildDenied(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Inventory')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text('Admin access required.',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _SectionCard extends StatelessWidget {
  final _Section section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(section.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: section.color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(section.subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOverrideSection extends ConsumerWidget {
  const _QuickOverrideSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('User Override Inspector',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'All overrides are audit-logged. Use for support, QA, and VIP grants.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        StockOverridePanel(
          onSubmit: (model) async {
            await ref.read(adminStoreServiceProvider).createOverride(model);
            if (model.playerId != null) {
              ref.invalidate(
                  adminPlayerOverridesProvider(model.playerId!));
            }
          },
        ),
      ],
    );
  }
}
