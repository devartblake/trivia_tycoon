import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_policy_form_model.dart';
import '../providers/admin_store_providers.dart';
import '../widgets/stock_policy_editor_card.dart';

class AdminStockPolicyScreen extends ConsumerStatefulWidget {
  const AdminStockPolicyScreen({super.key});

  @override
  ConsumerState<AdminStockPolicyScreen> createState() =>
      _AdminStockPolicyScreenState();
}

class _AdminStockPolicyScreenState
    extends ConsumerState<AdminStockPolicyScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(adminStorePoliciesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Stock Policy Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminStorePoliciesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: policiesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(e.toString()),
              data: (policies) {
                final filtered = _filter(policies);
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No policies found.',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => StockPolicyEditorCard(
                    initial: filtered[i],
                    onSave: (updated) async {
                      await ref
                          .read(adminStoreServiceProvider)
                          .updatePolicy(updated);
                      ref.invalidate(adminStorePoliciesProvider);
                    },
                    onReset: () async {
                      await ref
                          .read(adminStoreServiceProvider)
                          .resetPolicyStock(filtered[i].sku);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by SKU or item name…',
          prefixIcon: const Icon(Icons.search, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 32),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminStorePoliciesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<StockPolicyFormModel> _filter(List<StockPolicyFormModel> all) {
    if (_search.isEmpty) return all;
    return all
        .where((p) =>
            p.sku.toLowerCase().contains(_search) ||
            p.itemTitle.toLowerCase().contains(_search))
        .toList();
  }
}
