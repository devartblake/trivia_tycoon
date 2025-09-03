import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../models/prize_entry.dart';
import '../../services/prize_log_export_service.dart';
import '../../services/prize_log_provider.dart';

class PrizeLogScreen extends ConsumerStatefulWidget {
  const PrizeLogScreen({super.key});

  @override
  ConsumerState<PrizeLogScreen> createState() => _PrizeLogScreenState();
}

class _PrizeLogScreenState extends ConsumerState<PrizeLogScreen> {
  String exportFormat = 'json';
  String _selectedView = "all";
  final TextEditingController _badgeController = TextEditingController();
  final List<String> badgeChips = ['Diamond', 'Gold', 'Silver', 'Small'];

  @override
  void initState() {
    super.initState();
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    exportFormat = await AppSettings.getExportFormat();
    _selectedView = await AppSettings.getFilterViewRange();
    _badgeController.text = await AppSettings.getFilterBadge();

    // Apply the saved filters
    final notifier = ref.read(prizeLogProvider.notifier);
    if (_selectedView == "7" || _selectedView == "30") {
      final now = DateTime.now();
      final days = int.parse(_selectedView);
      notifier.filterByDate(now.subtract(Duration(days: days)), now);
    }
    if (_badgeController.text.isNotEmpty) {
      notifier.filterByBadge(_badgeController.text);
    }
    setState(() {});
  }

  int _calculateTotal(List<PrizeEntry> entries) {
    return entries.fold(0, (sum, e) {
      if (e.prize.contains("Diamond")) return sum + 500;
      if (e.prize.contains("Gold")) return sum + 250;
      if (e.prize.contains("Silver")) return sum + 100;
      if (e.prize.contains("Small")) return sum + 50;
      return sum + 10;
    });
  }

  String _findFrequentPrize(List<PrizeEntry> entries) {
    final freq = <String, int>{};
    for (final e in entries) {
      freq[e.prize] = (freq[e.prize] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isNotEmpty ? sorted.first.key : "None";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prizeLogProvider);
    final notifier = ref.read(prizeLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("🏆 Prize Log")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Export Format Toggle
            Row(
              children: [
                const Text("Export Format: "),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: exportFormat,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => exportFormat = value);
                      AppSettings.savePrizeLogFilters(exportFormat: value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'json', child: Text("JSON")),
                    DropdownMenuItem(value: 'csv', child: Text("CSV")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Badge Filter
            TextField(
              controller: _badgeController,
              decoration: InputDecoration(
                labelText: "Filter by Badge (Prize Name)",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    notifier.filterByBadge(_badgeController.text.trim());
                  },
                ),
              ),
              onSubmitted: (text) {
                notifier.filterByBadge(text);
                AppSettings.savePrizeLogFilters(badge: text);
              },
            ),

            const SizedBox(height: 12),

            // Chip UI
            Wrap(
              spacing: 8,
              children: badgeChips.map((badge) {
                return ChoiceChip(
                  label: Text(badge),
                  selected: _badgeController.text.toLowerCase() == badge.toLowerCase(),
                  onSelected: (selected) {
                    _badgeController.text = badge;
                    notifier.filterByBadge(badge);
                    AppSettings.savePrizeLogFilters(badge:  badge);
                    setState(() {});
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Toggle all-time / recent logs
            Row(
              children: [
                const Text("View: "),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("All-Time"),
                  selected: _selectedView == "all",
                  onSelected: (_) {
                    _selectedView = "all";
                    notifier.resetFilter();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Last 7 Days"),
                  selected: _selectedView == "7",
                  onSelected: (_) {
                    _selectedView = "7";
                    final now = DateTime.now();
                    notifier.filterByDate(now.subtract(const Duration(days: 7)), now);
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Last 30 Days"),
                  selected: _selectedView == "30",
                  onSelected: (_) {
                    _selectedView = "30";
                    final now = DateTime.now();
                    notifier.filterByDate(now.subtract(const Duration(days: 30)), now);
                    setState(() {});
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date Range Filter
            ElevatedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  notifier.filterByDate(range.start, range.end);
                }
              },
              icon: const Icon(Icons.date_range),
              label: const Text("Filter by Date Range"),
            ),

            TextButton.icon(
              onPressed: () {
                _badgeController.clear();
                AppSettings.savePrizeLogFilters(badge: '', viewRange: 'all');
                notifier.resetFilter();
              },
              icon: const Icon(Icons.clear),
              label: const Text("Clear Filters"),
            ),

            const SizedBox(height: 12),

            // Export / Import Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final entries = state.value ?? [];
                      final file = exportFormat == "csv"
                          ? await PrizeLogExportService.exportToCsv(entries)
                          : await PrizeLogExportService.exportToFile(entries);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Exported to ${file.path}")),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Export"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await PrizeLogExportService.importFromFile();
                      await notifier.build(); // Refresh log
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Log imported successfully")),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text("Import"),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Log List
            Expanded(
              child: state.when(
                data: (logs) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: logs.isEmpty
                      ? const Center(child: Text("No prizes yet!"))
                      : Column(
                    children: [
                      // ✅ ← THIS IS THE RIGHT PLACE
                      if (logs.isNotEmpty) ...[
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text("🎯 Total Rewards: \$${_calculateTotal(logs)}"),
                            subtitle: Text("🔥 Most Frequent Prize: ${_findFrequentPrize(logs)}"),
                          ),
                        ),
                      ],
                      Expanded(
                        child: ListView.separated(
                          key: ValueKey(logs.hashCode),
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (_, i) => ListTile(
                            leading: const Icon(Icons.card_giftcard),
                            title: Text(logs[i].prize),
                            subtitle: Text(DateFormat.yMMMd().add_jm().format(logs[i].timestamp)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),

            // Export types
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final entries = state.value ?? [];
                      final file = exportFormat == "csv"
                          ? await PrizeLogExportService.exportToCsv(entries)
                          : await PrizeLogExportService.exportToFile(entries);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Exported to ${file.path}")),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Export"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await PrizeLogExportService.importFromFile();
                      await notifier.build();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Log imported successfully")),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text("Import"),
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
    );
  }
}
