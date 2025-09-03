import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/scan_history_item.dart';
import '../services/qr_history_service.dart';
import '../utils/qr_scan_format_utils.dart';

final selectedScanTypeProvider = StateProvider<QrContentType?>((ref) => null);

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyService = ref.read(qrHistoryServiceProvider);
    final selectedType = ref.watch(selectedScanTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Clear History"),
                  content: const Text("Are you sure you want to delete all scan history?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear")),
                  ],
                ),
              );
              if (confirm == true) {
                await historyService.clearHistory();
                ref.invalidate(qrHistoryServiceProvider);
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<ScanHistoryItem>>(
        future: historyService.getHistory(),
        builder: (context, snapshot) {
          final allHistory = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allHistory.isEmpty) {
            return const Center(child: Text("No scans yet."));
          }

          final filteredHistory = selectedType == null
              ? allHistory
              : allHistory.where((item) => item.type == selectedType.name).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text("All"),
                      selected: selectedType == null,
                      onSelected: (_) => ref.read(selectedScanTypeProvider.notifier).state = null,
                    ),
                    ...QrContentType.values.map((type) {
                      return ChoiceChip(
                        label: Text(QrFormatUtils.labelForType(type)),
                        selected: selectedType == type,
                        onSelected: (_) => ref.read(selectedScanTypeProvider.notifier).state = type,
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (_, index) {
                    final item = filteredHistory[index];
                    final timeFormatted = DateFormat.yMMMd().add_jm().format(item.timestamp);
                    final icon = QrFormatUtils.iconForType(QrFormatUtils.fromName(item.type));

                    return Dismissible(
                      key: ValueKey(item.timestamp.toIso8601String() + item.value),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Scan"),
                            content: Text("Remove this scan entry?\n\n${item.value}"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final history = await historyService.getHistory();
                          history.removeWhere((e) => e.value == item.value);
                          await historyService.cache.set(
                            QrHistoryService.storageKey,
                            history.map((e) => e.toJson()).toList(),
                          );
                          ref.invalidate(qrHistoryServiceProvider);
                        }
                        return confirm ?? false;
                      },
                      child: ListTile(
                        leading: Icon(icon, color: Colors.deepPurple),
                        title: Text(item.value),
                        subtitle: Text("Scanned on $timeFormatted"),
                        trailing: const Icon(Icons.qr_code),
                        onTap: () => _showScanPreviewDialog(context, item),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showScanPreviewDialog(BuildContext context, ScanHistoryItem item) {
    final contentType = QrFormatUtils.fromName(item.type);
    final icon = QrFormatUtils.iconForType(contentType);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Expanded(child: Text(QrFormatUtils.labelForType(contentType))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(item.value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Scanned at: ${DateFormat.yMMMd().add_jm().format(item.timestamp)}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (contentType == QrContentType.url)
            TextButton(
              child: const Text("Open URL"),
              onPressed: () async {
                final uri = Uri.tryParse(item.value);
                if (uri != null) await launchUrl(uri);
              },
            ),
          if (contentType == QrContentType.userId)
            TextButton(
              child: const Text("Copy ID"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: item.value));
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
