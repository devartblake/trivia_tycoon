import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/providers/riverpod_providers.dart';

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  final String? userId;

  const AdminAuditLogScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = <Map<String, dynamic>>[];

  int _page = 1;
  int _pageSize = 50;
  int _total = 0;

  final _actionFilterController = TextEditingController();
  String? _entityFilter;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _actionFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get(
        '/admin/audit',
        headers: {
          if (widget.userId != null && widget.userId!.isNotEmpty)
            'x-user-id': widget.userId!,
        },
      );

      final envelope = serviceManager.apiService.parsePageEnvelope<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      setState(() {
        _entries = envelope.items;
        _page = envelope.page;
        _pageSize = envelope.pageSize;
        _total = envelope.total;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load audit logs: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEntries {
    final query = _actionFilterController.text.trim().toLowerCase();
    return _entries.where((entry) {
      final action = entry['action']?.toString().toLowerCase() ?? '';
      final entity = entry['entityType']?.toString().toLowerCase() ?? '';

      final actionMatches = query.isEmpty || action.contains(query);
      final entityMatches = _entityFilter == null || _entityFilter == entity;

      return actionMatches && entityMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId == null ? 'Audit Log' : 'User Audit Log'),
        actions: [
          IconButton(
            onPressed: _loadAuditLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _actionFilterController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Filter by action (e.g. user.update, question.delete)',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _entityFilter,
                  hint: const Text('Entity'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'user', child: Text('User mutations')),
                    DropdownMenuItem(value: 'question', child: Text('Question mutations')),
                    DropdownMenuItem(value: 'event', child: Text('Event reprocess actions')),
                  ],
                  onChanged: (value) => setState(() => _entityFilter = value),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Page $_page • Size $_pageSize • Total $_total'),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('No audit entries found.'))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final entry = rows[i];
                      final createdAtRaw = entry['createdAt']?.toString();
                      DateTime? createdAt;
                      if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
                        createdAt = DateTime.tryParse(createdAtRaw)?.toUtc();
                      }
                      final localCreatedAt = createdAt?.toLocal();

                      return ListTile(
                        leading: const Icon(Icons.history_toggle_off),
                        title: Text(entry['action']?.toString() ?? 'unknown.action'),
                        subtitle: Text(
                          'entity=${entry['entityType'] ?? '-'} • actor=${entry['actorUserId'] ?? '-'}\n'
                          'target=${entry['targetId'] ?? '-'}',
                        ),
                        trailing: Text(
                          localCreatedAt == null
                              ? '-'
                              : '${localCreatedAt.year}-${localCreatedAt.month.toString().padLeft(2, '0')}-${localCreatedAt.day.toString().padLeft(2, '0')} '
                                  '${localCreatedAt.hour.toString().padLeft(2, '0')}:${localCreatedAt.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
