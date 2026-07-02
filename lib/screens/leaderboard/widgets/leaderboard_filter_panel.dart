import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaderboardFilterPanel extends StatefulWidget {
  final int? selectedTier;
  final DateTimeRange? dateRange;
  final String? searchQuery;
  final VoidCallback onClearFilters;
  final Function(int?)? onTierChanged;
  final Function(DateTimeRange?)? onDateRangeChanged;
  final Function(String?)? onSearchChanged;

  const LeaderboardFilterPanel({
    super.key,
    this.selectedTier,
    this.dateRange,
    this.searchQuery,
    required this.onClearFilters,
    this.onTierChanged,
    this.onDateRangeChanged,
    this.onSearchChanged,
  });

  @override
  State<LeaderboardFilterPanel> createState() => _LeaderboardFilterPanelState();
}

class _LeaderboardFilterPanelState extends State<LeaderboardFilterPanel> {
  late int? _selectedTier;
  late DateTimeRange? _dateRange;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.selectedTier;
    _dateRange = widget.dateRange;
    _searchController = TextEditingController(text: widget.searchQuery ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
      widget.onDateRangeChanged?.call(range);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.tune, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTier = null;
                      _dateRange = null;
                      _searchController.clear();
                    });
                    widget.onClearFilters();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Player',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: widget.onSearchChanged,
            ),
            const SizedBox(height: 16),

            if (isMobile)
              Column(
                children: [
                  // Tier selector (mobile)
                  _buildTierSelector(),
                  const SizedBox(height: 16),
                  // Date range (mobile)
                  _buildDateRangeSelector(),
                ],
              )
            else
              Row(
                children: [
                  // Tier selector (desktop)
                  Expanded(
                    flex: 2,
                    child: _buildTierSelector(),
                  ),
                  const SizedBox(width: 16),
                  // Date range (desktop)
                  Expanded(
                    flex: 3,
                    child: _buildDateRangeSelector(),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Active filters display
            if (_selectedTier != null || _dateRange != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedTier != null)
                    Chip(
                      label: Text('Tier $_selectedTier'),
                      onDeleted: () {
                        setState(() => _selectedTier = null);
                        widget.onTierChanged?.call(null);
                      },
                      avatar: const Icon(Icons.emoji_events, size: 18),
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                      ),
                      onDeleted: () {
                        setState(() => _dateRange = null);
                        widget.onDateRangeChanged?.call(null);
                      },
                      avatar: const Icon(Icons.calendar_today, size: 18),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tier',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: _selectedTier,
          decoration: InputDecoration(
            hintText: 'All Tiers',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All Tiers'),
            ),
            ...List.generate(10, (i) {
              final tier = i + 1;
              return DropdownMenuItem<int?>(
                value: tier,
                child: Text('Tier $tier'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedTier = value);
            widget.onTierChanged?.call(value);
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dateRange == null
                        ? 'Select date range'
                        : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                    style: _dateRange == null
                        ? TextStyle(color: Colors.grey[600])
                        : null,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
