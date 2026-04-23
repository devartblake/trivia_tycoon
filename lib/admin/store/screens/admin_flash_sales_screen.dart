import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_override_form_model.dart';
import '../providers/admin_store_providers.dart';
import '../widgets/flash_sale_scheduler_form.dart';

class AdminFlashSalesScreen extends ConsumerStatefulWidget {
  const AdminFlashSalesScreen({super.key});

  @override
  ConsumerState<AdminFlashSalesScreen> createState() =>
      _AdminFlashSalesScreenState();
}

class _AdminFlashSalesScreenState
    extends ConsumerState<AdminFlashSalesScreen> {
  bool _showNewForm = false;

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(adminFlashSalesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Flash Sale Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminFlashSalesProvider),
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 32),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminFlashSalesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (sales) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // New sale form toggle
            if (_showNewForm) ...[
              FlashSaleSchedulerForm(
                initial: FlashSaleFormModel(
                  title: '',
                  linkedSku: '',
                  startTime: DateTime.now().toUtc().add(const Duration(hours: 1)),
                  endTime: DateTime.now().toUtc().add(const Duration(hours: 25)),
                ),
                onSave: (model) async {
                  await ref.read(adminStoreServiceProvider).createFlashSale(model);
                  ref.invalidate(adminFlashSalesProvider);
                  setState(() => _showNewForm = false);
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => setState(() => _showNewForm = true),
                icon: const Icon(Icons.add),
                label: const Text('New Flash Sale'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Existing sales
            if (sales.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No flash sales yet.',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ...sales.asMap().entries.map((entry) {
                final sale = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FlashSaleSchedulerForm(
                    initial: sale,
                    onSave: (updated) async {
                      await ref
                          .read(adminStoreServiceProvider)
                          .updateFlashSale(updated);
                      ref.invalidate(adminFlashSalesProvider);
                    },
                    onDelete: () async {
                      if (sale.saleId == null) return;
                      await ref
                          .read(adminStoreServiceProvider)
                          .deleteFlashSale(sale.saleId!);
                      ref.invalidate(adminFlashSalesProvider);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
