import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../models/spin_system_models.dart';
import '../../services/prize_log_export_service.dart';
import '../../services/prize_log_provider.dart';

class PrizeLogScreen extends ConsumerStatefulWidget {
  const PrizeLogScreen({super.key});

  @override
  ConsumerState<PrizeLogScreen> createState() => _PrizeLogScreenState();
}

class _PrizeLogScreenState extends ConsumerState<PrizeLogScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _exportFormat = 'json';
  String _selectedView = "all";
  final TextEditingController _badgeController = TextEditingController();
  final List<String> _badgeChips = ['Diamond', 'Gold', 'Silver', 'Small'];

  bool _isLoading = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFilterState();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadFilterState() async {
    setState(() => _isLoading = true);

    try {
      _exportFormat = await AppSettings.getExportFormat();
      _selectedView = await AppSettings.getFilterViewRange();
      _badgeController.text = await AppSettings.getFilterBadge();

      // Apply saved filters
      final notifier = ref.read(prizeLogProvider.notifier);
      if (_selectedView == "7" || _selectedView == "30") {
        final now = DateTime.now();
        final days = int.parse(_selectedView);
        notifier.filterByDate(now.subtract(Duration(days: days)), now);
      }
      if (_badgeController.text.isNotEmpty) {
        notifier.filterByBadge(_badgeController.text);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load filter settings');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    if (entries.isEmpty) return "None";

    final freq = <String, int>{};
    for (final e in entries) {
      freq[e.prize] = (freq[e.prize] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final entries = ref.read(prizeLogProvider).value ?? [];
      final file = _exportFormat == "csv"
          ? await PrizeLogExportService.exportToCsv(entries)
          : await PrizeLogExportService.exportToFile(entries);

      _showSuccessSnackBar("Exported to ${file.path}");
    } catch (e) {
      _showErrorSnackBar("Export failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await PrizeLogExportService.importFromFile();
      await ref.read(prizeLogProvider.notifier).build();
      _showSuccessSnackBar("Log imported successfully");
    } catch (e) {
      _showErrorSnackBar("Import failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prizeLogProvider);
    final notifier = ref.read(prizeLogProvider.notifier);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Prize Log",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Filters section
              if (_showFilters)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.filter_alt, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text(
                              'Filters & Export',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Export format
                        Row(
                          children: [
                            const Text("Export Format: "),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _exportFormat,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _exportFormat = value);
                                      AppSettings.savePrizeLogFilters(exportFormat: value);
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'json', child: Text("JSON")),
                                    DropdownMenuItem(value: 'csv', child: Text("CSV")),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Badge filter
                        TextField(
                          controller: _badgeController,
                          decoration: InputDecoration(
                            labelText: "Filter by Prize Name",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _badgeController.clear();
                                notifier.resetFilter();
                                AppSettings.savePrizeLogFilters(badge: '', viewRange: 'all');
                              },
                            ),
                          ),
                          onSubmitted: (text) {
                            notifier.filterByBadge(text);
                            AppSettings.savePrizeLogFilters(badge: text);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Badge chips
                        Wrap(
                          spacing: 8,
                          children: _badgeChips.map((badge) {
                            final isSelected = _badgeController.text.toLowerCase() == badge.toLowerCase();
                            return FilterChip(
                              label: Text(badge),
                              selected: isSelected,
                              onSelected: (selected) {
                                _badgeController.text = selected ? badge : '';
                                notifier.filterByBadge(selected ? badge : '');
                                AppSettings.savePrizeLogFilters(badge: selected ? badge : '');
                                setState(() {});
                              },
                              selectedColor: Colors.amber.withOpacity(0.2),
                              checkmarkColor: Colors.amber,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Time filter chips
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text("All-Time"),
                              selected: _selectedView == "all",
                              onSelected: (_) {
                                setState(() => _selectedView = "all");
                                notifier.resetFilter();
                                AppSettings.savePrizeLogFilters(viewRange: 'all');
                              },
                            ),
                            FilterChip(
                              label: const Text("Last 7 Days"),
                              selected: _selectedView == "7",
                              onSelected: (_) {
                                setState(() => _selectedView = "7");
                                final now = DateTime.now();
                                notifier.filterByDate(now.subtract(const Duration(days: 7)), now);
                                AppSettings.savePrizeLogFilters(viewRange: '7');
                              },
                            ),
                            FilterChip(
                              label: const Text("Last 30 Days"),
                              selected: _selectedView == "30",
                              onSelected: (_) {
                                setState(() => _selectedView = "30");
                                final now = DateTime.now();
                                notifier.filterByDate(now.subtract(const Duration(days: 30)), now);
                                AppSettings.savePrizeLogFilters(viewRange: '30');
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : () async {
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
                                label: const Text("Date Range"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : () {
                                  _badgeController.clear();
                                  setState(() => _selectedView = "all");
                                  AppSettings.savePrizeLogFilters(badge: '', viewRange: 'all');
                                  notifier.resetFilter();
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text("Clear All"),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Export/Import buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _handleExport,
                                icon: _isLoading
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.download),
                                label: const Text("Export"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _handleImport,
                                icon: const Icon(Icons.upload),
                                label: const Text("Import"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Stats section
              SliverToBoxAdapter(
                child: state.when(
                  data: (logs) => logs.isNotEmpty
                      ? Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatsCard(
                            title: 'Total Value',
                            value: '\${_calculateTotal(logs)}',
                            icon: Icons.monetization_on,
                            color: Colors.green,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatsCard(
                            title: 'Total Prizes',
                            value: '${logs.length}',
                            icon: Icons.card_giftcard,
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatsCard(
                            title: 'Most Common',
                            value: _findFrequentPrize(logs).split(' ').first,
                            icon: Icons.trending_up,
                            color: Colors.purple,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Prize list
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E2E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: state.when(
                    data: (logs) => logs.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No prizes yet!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start spinning the wheel to earn rewards",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                        : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.history, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                'Prize History (${logs.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _PrizeListItem(
                            entry: logs[i],
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    loading: () => Container(
                      padding: const EdgeInsets.all(40),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error loading prizes",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A3E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeListItem extends StatelessWidget {
  final PrizeEntry entry;
  final bool isDark;

  const _PrizeListItem({
    required this.entry,
    required this.isDark,
  });

  Color _getPrizeColor() {
    if (entry.prize.contains("Diamond")) return Colors.purple;
    if (entry.prize.contains("Gold")) return Colors.amber;
    if (entry.prize.contains("Silver")) return Colors.grey;
    return Colors.blue;
  }

  IconData _getPrizeIcon() {
    if (entry.prize.contains("Diamond")) return Icons.diamond;
    if (entry.prize.contains("Gold")) return Icons.stars;
    if (entry.prize.contains("Silver")) return Icons.star;
    return Icons.card_giftcard;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPrizeColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A3E)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPrizeIcon(),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.prize,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().add_jm().format(entry.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('MMM d').format(entry.timestamp),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}