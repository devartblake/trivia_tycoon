import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui_components/qr_code/services/qr_history_service.dart';

class AdminScanSyncCard extends ConsumerStatefulWidget {
  final String userId;

  const AdminScanSyncCard({super.key, required this.userId});

  @override
  ConsumerState<AdminScanSyncCard> createState() => _AdminScanSyncCardState();
}

class _AdminScanSyncCardState extends ConsumerState<AdminScanSyncCard> {
  int? _retentionDays = 7;
  bool _isLoading = false;

  Future<void> _syncNow() async {
    setState(() => _isLoading = true);
    try {
      await QrHistoryService.instance.syncToBackend(
        userId: widget.userId,
        retentionDays: _retentionDays,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Scan history synced successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Sync failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📡 Sync QR Scan Data", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text("👤 User ID: ${widget.userId}"),
            const SizedBox(height: 8),
            const Text("Retention Period:"),
            Wrap(
              spacing: 12,
              children: [7, 14, 30].map((days) {
                return ChoiceChip(
                  label: Text("$days days"),
                  selected: _retentionDays == days,
                  onSelected: (_) => setState(() => _retentionDays = days),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: Text(_isLoading ? "Syncing..." : "Sync Now"),
              onPressed: _isLoading ? null : _syncNow,
            ),
          ],
        ),
      ),
    );
  }
}
