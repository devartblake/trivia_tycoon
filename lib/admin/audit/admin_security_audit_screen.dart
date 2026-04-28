import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../game/providers/riverpod_providers.dart';

class AdminSecurityAuditScreen extends ConsumerStatefulWidget {
  const AdminSecurityAuditScreen({super.key});

  @override
  ConsumerState<AdminSecurityAuditScreen> createState() =>
      _AdminSecurityAuditScreenState();
}

class _AdminSecurityAuditScreenState
    extends ConsumerState<AdminSecurityAuditScreen> {
  final _dateFormat = DateFormat('MMM d, y – HH:mm:ss');
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _events = [];
  int _page = 1;
  int _total = 0;
  static const int _pageSize = 50;

  String? _statusFilter;

  static const _statusOptions = [
    null,
    'UNAUTHORIZED',
    'FORBIDDEN',
    'RATE_LIMITED',
    'VALIDATION_ERROR',
    'NOT_FOUND',
    'CONFLICT',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(serviceManagerProvider).apiService;
      final response = await api.get(
        '/admin/audit/security',
        queryParameters: {
          'page': page,
          'pageSize': _pageSize,
          if (_fromController.text.trim().isNotEmpty)
            'from': _fromController.text.trim(),
          if (_toController.text.trim().isNotEmpty)
            'to': _toController.text.trim(),
          if (_statusFilter != null) 'status': _statusFilter!,
        },
      );
      final envelope = api.parsePageEnvelope<Map<String, dynamic>>(
          response, (j) => j);
      if (!mounted) return;
      setState(() {
        _events = envelope.items;
        _page = envelope.page;
        _total = envelope.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Security Audit'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _load(page: _page),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            fromController: _fromController,
            toController: _toController,
            statusFilter: _statusFilter,
            statusOptions: _statusOptions,
            isLoading: _isLoading,
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            onApply: () => _load(page: 1),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          Expanded(
            child: _events.isEmpty && !_isLoading
                ? _EmptyState(hasFilters: _hasFilters)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    itemCount: _events.length,
                    itemBuilder: (context, i) => _EventTile(
                      event: _events[i],
                      dateFormat: _dateFormat,
                    ),
                  ),
          ),
          if (_total > _pageSize)
            _PagingBar(
              page: _page,
              total: _total,
              pageSize: _pageSize,
              isLoading: _isLoading,
              onPrev: _page > 1 ? () => _load(page: _page - 1) : null,
              onNext: _page * _pageSize < _total
                  ? () => _load(page: _page + 1)
                  : null,
            ),
        ],
      ),
    );
  }

  bool get _hasFilters =>
      _fromController.text.isNotEmpty ||
      _toController.text.isNotEmpty ||
      _statusFilter != null;
}

class _FilterBar extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final String? statusFilter;
  final List<String?> statusOptions;
  final bool isLoading;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApply;

  const _FilterBar({
    required this.fromController,
    required this.toController,
    required this.statusFilter,
    required this.statusOptions,
    required this.isLoading,
    required this.onStatusChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fromController,
                  decoration: const InputDecoration(
                    labelText: 'From (ISO-8601)',
                    hintText: '2026-01-01T00:00:00Z',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    labelText: 'To (ISO-8601)',
                    hintText: '2026-12-31T23:59:59Z',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DropdownButton<String?>(
                value: statusFilter,
                hint: const Text('Error code'),
                isDense: true,
                items: statusOptions.map((s) {
                  return DropdownMenuItem<String?>(
                    value: s,
                    child: Text(s ?? 'All codes'),
                  );
                }).toList(),
                onChanged: onStatusChanged,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isLoading ? null : onApply,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final DateFormat dateFormat;

  const _EventTile({required this.event, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final code = (event['errorCode'] ??
            event['code'] ??
            event['status'] ??
            'UNKNOWN')
        .toString()
        .toUpperCase();
    final path = (event['path'] ?? event['endpoint'] ?? '-').toString();
    final rawTs = (event['occurredAtUtc'] ??
            event['timestamp'] ??
            event['createdAtUtc'] ??
            event['created_at'] ??
            '')
        .toString();
    final ts = DateTime.tryParse(rawTs)?.toLocal();
    final actor = (event['actorId'] ??
            event['userId'] ??
            event['playerId'] ??
            '-')
        .toString();

    final codeColor = _codeColor(code);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: codeColor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: codeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: codeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'actor: $actor',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (ts != null)
                Text(
                  dateFormat.format(ts),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _codeColor(String code) => switch (code) {
        'UNAUTHORIZED' => const Color(0xFFEF4444),
        'FORBIDDEN' => const Color(0xFFF97316),
        'RATE_LIMITED' => const Color(0xFFF59E0B),
        'CONFLICT' => const Color(0xFF8B5CF6),
        'VALIDATION_ERROR' => const Color(0xFF3B82F6),
        'NOT_FOUND' => const Color(0xFF6B7280),
        _ => const Color(0xFF6B7280),
      };

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EventDetailSheet(event: event),
    );
  }
}

class _EventDetailSheet extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventDetailSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final entries = event.entries.toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Event Detail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagingBar extends StatelessWidget {
  final int page;
  final int total;
  final int pageSize;
  final bool isLoading;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PagingBar({
    required this.page,
    required this.total,
    required this.pageSize,
    required this.isLoading,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: isLoading ? null : onPrev,
          ),
          Text('Page $page / $totalPages',
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isLoading ? null : onNext,
          ),
          Text('$total events total',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_outlined,
                size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No events match the current filters'
                  : 'No security events recorded',
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
