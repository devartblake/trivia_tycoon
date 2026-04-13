import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';


class AdminEventQueueScreen extends ConsumerStatefulWidget {
  const AdminEventQueueScreen({super.key});

  @override
  ConsumerState<AdminEventQueueScreen> createState() => _AdminEventQueueScreenState();
}

class _AdminEventQueueScreenState extends ConsumerState<AdminEventQueueScreen> {
  List<MapEntry<dynamic, Map<String, dynamic>>> _events = [];
  Map<String, dynamic>? _queueStatus;
  bool _isLoading = true;
  bool _isUploading = false;
  DateTime? _uploadCooldownUntil;
  final Map<dynamic, DateTime> _reprocessCooldownUntil = {};
  final Map<dynamic, Map<String, dynamic>> _serverOutcomeByKey = {};
  final Set<dynamic> _selectedEvents = {};

  // Pagination
  int _currentPage = 0;
  final int _eventsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _loadEventQueue();
  }


  int _secondsRemaining(DateTime? until) {
    if (until == null) return 0;
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inSeconds + 1;
  }

  bool get _isUploadCoolingDown => _secondsRemaining(_uploadCooldownUntil) > 0;

  bool _isReprocessCoolingDown(dynamic key) {
    return _secondsRemaining(_reprocessCooldownUntil[key]) > 0;
  }

  Future<void> _loadEventQueue() async {
    setState(() => _isLoading = true);

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final eventQueue = serviceManager.eventQueueService;

      // Get status first
      final status = eventQueue.getQueueStatus();

      // Read directly from Hive box
      final box = await Hive.openBox('event_queue');

      final eventEntries = box.toMap().entries.map((e) {
        try {
          // Handle different possible types
          if (e.value is Map<String, dynamic>) {
            return MapEntry(e.key, e.value as Map<String, dynamic>);
          } else if (e.value is Map) {
            return MapEntry(e.key, Map<String, dynamic>.from(e.value as Map));
          } else {
            return null;
          }
        } catch (_) {
          return null;
        }
      }).whereType<MapEntry<dynamic, Map<String, dynamic>>>().toList();

      setState(() {
        _events = eventEntries;
        _queueStatus = status;
        _isLoading = false;
        _currentPage = 0;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load event queue: $e');
    }
  }

  Future<void> _reprocessEvent(dynamic key, Map<String, dynamic> event) async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final endpoint = event['endpoint']?.toString();
      final payloadRaw = event['payload'];

      if (endpoint == null || endpoint.isEmpty || payloadRaw is! Map) {
        _showError('Invalid queued event payload');
        return;
      }

      final payload = Map<String, dynamic>.from(payloadRaw);
      await serviceManager.apiService.post(endpoint, body: payload);

      final box = await Hive.openBox('event_queue');
      await box.delete(key);

      _showSuccess('Event reprocessed successfully');
      await _loadEventQueue();
    } catch (e) {
      _showError('Failed to reprocess event: $e');
    }
  }

  Future<void> _deleteEvent(dynamic key) async {
    try {
      final box = await Hive.openBox('event_queue');
      await box.delete(key);

      _showSuccess('Event deleted successfully');
      await _loadEventQueue();
    } catch (e) {
      _showError('Failed to delete event: $e');
    }
  }

  Future<void> _deleteSelectedEvents() async {
    if (_selectedEvents.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete ${_selectedEvents.length} events?',
      'This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      final box = await Hive.openBox('event_queue');
      final count = _selectedEvents.length;
      for (final key in _selectedEvents) {
        await box.delete(key);
      }

      setState(() => _selectedEvents.clear());
      _showSuccess('$count events deleted');
      await _loadEventQueue();
    } catch (e) {
      _showError('Failed to delete events: $e');
    }
  }

  Future<void> _clearAllEvents() async {
    final confirmed = await _showConfirmDialog(
      'Clear entire queue?',
      'This will delete all ${_events.length} events permanently.',
    );

    if (!confirmed) return;

    try {
      final serviceManager = ref.read(serviceManagerProvider);

      await serviceManager.eventQueueService.clearAll();

      setState(() => _selectedEvents.clear());
      await _loadEventQueue();

      _showSuccess('Queue cleared successfully');
    } catch (e) {
      _showError('Failed to clear queue: $e');
    }
  }

  // Step 1: View Event Details
  Future<void> _viewEventDetails(Map<String, dynamic> event) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Event Details')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(event),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: const JsonEncoder.withIndent('  ').convert(event),
              ));
              Navigator.pop(context);
              _showSuccess('Event copied to clipboard');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy JSON'),
          ),
        ],
      ),
    );
  }

  // Step 3: Export Queue to File
  Future<void> _exportQueueToFile() async {
    try {
      final box = await Hive.openBox('event_queue');
      final allEvents = box.toMap().entries.map((e) => {
        'key': e.key.toString(),
        'data': e.value,
      }).toList();

      final exportJson = const JsonEncoder.withIndent('  ').convert({
        'export_time': DateTime.now().toIso8601String(),
        'total_events': allEvents.length,
        'queue_status': _queueStatus,
        'events': allEvents,
      });

      await Clipboard.setData(ClipboardData(text: exportJson));
      _showSuccess('Queue exported to clipboard (${allEvents.length} events)');
    } catch (e) {
      _showError('Export failed: $e');
    }
  }

  Future<void> _exportToServer() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final playerProfile = serviceManager.playerProfileService;
      final playerId = await playerProfile.getPlayerName();

      final exportData = await serviceManager.eventQueueService
          .exportFailedEventsForUpload(playerId);

      final response = await serviceManager.apiService.post(
        '/admin/event-queue/upload',
        body: exportData,
      );

      final accepted = response['accepted'];
      final rejected = response['rejected'];
      final duplicates = response['duplicates'];

      _showSuccess(
        'Upload complete'
        '${accepted != null ? ' • accepted: $accepted' : ''}'
        '${rejected != null ? ', rejected: $rejected' : ''}'
        '${duplicates != null ? ', duplicates: $duplicates' : ''}',
      );
    } catch (e) {
      // Keep previous operational fallback for offline/unsupported environments.
      try {
        final serviceManager = ref.read(serviceManagerProvider);
        final playerProfile = serviceManager.playerProfileService;
        final playerId = await playerProfile.getPlayerName();
        final exportData = await serviceManager.eventQueueService
            .exportFailedEventsForUpload(playerId);
        final jsonString = jsonEncode(exportData);
        await Clipboard.setData(ClipboardData(text: jsonString));
        _showError('Server upload failed. Copied payload to clipboard instead. Error: $e');
      } catch (_) {
        _showError('Failed to export: $e');
      }
    }
  }

  Future<void> _forceSyncWithServer() async {
    final confirmed = await _showConfirmDialog(
      'Force sync with server?',
      'This will attempt to send all queued events immediately.',
    );

    if (!confirmed) return;

    try {
      final serviceManager = ref.read(serviceManagerProvider);

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      await serviceManager.analyticsService.retryQueuedEvents();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      _showSuccess('Sync completed - check queue for results');
      await _loadEventQueue();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      _showError('Sync failed: $e');
    }
  }

  Future<void> _forceExitCooldown() async {
    final confirmed = await _showConfirmDialog(
      'Force exit cooldown mode?',
      'This will reset failure counters and resume retries.',
    );

    if (!confirmed) return;

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      await serviceManager.eventQueueService.forceExitCooldown();

      _showSuccess('Cooldown mode exited');
      await _loadEventQueue();
    } catch (e) {
      _showError('Failed to exit cooldown: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Event Queue Manager',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEventQueue,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Status Card
          _buildStatusCard(theme),

          // Action Buttons
          _buildActionButtons(theme),

          // Events List with Pagination
          Expanded(
            child: _events.isEmpty
                ? _buildEmptyState()
                : _buildEventsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final isInCooldown = _queueStatus?['is_in_cooldown'] ?? false;
    final consecutiveFailures = _queueStatus?['consecutive_failures'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Queue Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow('Total Events', '${_events.length}', Colors.blue),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Status',
            isInCooldown ? 'COOLDOWN' : 'ACTIVE',
            isInCooldown ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Consecutive Failures',
            '$consecutiveFailures',
            consecutiveFailures > 3 ? Colors.red : Colors.grey,
          ),
          if (_selectedEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStatusRow(
              'Selected',
              '${_selectedEvents.length}',
              theme.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionChip(
            'Export JSON',
            Icons.download_rounded,
            Colors.blue,
            _exportQueueToFile,
          ),
          _buildActionChip(
            _isUploadCoolingDown
                ? 'Retry in ${_secondsRemaining(_uploadCooldownUntil)}s'
                : (_isUploading ? 'Uploading...' : 'Export Server'),
            Icons.upload_file_rounded,
            Colors.cyan,
            (_isUploading || _isUploadCoolingDown) ? () {} : _exportToServer,
          ),
          _buildActionChip(
            'Sync Now',
            Icons.sync_rounded,
            Colors.green,
            _forceSyncWithServer,
          ),
          if (_selectedEvents.isNotEmpty)
            _buildActionChip(
              'Delete Selected',
              Icons.delete_outline_rounded,
              Colors.orange,
              _deleteSelectedEvents,
            ),
          if (_events.isNotEmpty)
            _buildActionChip(
              'Clear All',
              Icons.clear_all_rounded,
              Colors.red,
              _clearAllEvents,
            ),
          if (_queueStatus?['is_in_cooldown'] == true)
            _buildActionChip(
              'Exit Cooldown',
              Icons.power_settings_new_rounded,
              Colors.purple,
              _forceExitCooldown,
            ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: Colors.green[300]),
          const SizedBox(height: 16),
          Text(
            'Queue is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All events have been processed',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // Step 4: Pagination for Events List
  Widget _buildEventsList(ThemeData theme) {
    final startIndex = _currentPage * _eventsPerPage;
    final endIndex = min(startIndex + _eventsPerPage, _events.length);
    final pageEvents = _events.sublist(startIndex, endIndex);
    final totalPages = (_events.length / _eventsPerPage).ceil();

    return Column(
      children: [
        // Pagination controls at top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1}-$endIndex of ${_events.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    tooltip: 'Previous page',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Page ${_currentPage + 1}/$totalPages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: endIndex < _events.length
                        ? () => setState(() => _currentPage++)
                        : null,
                    tooltip: 'Next page',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Events list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pageEvents.length,
            itemBuilder: (context, index) {
              final entry = pageEvents[index];
              final event = entry.value;
              final isSelected = _selectedEvents.contains(entry.key);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedEvents.remove(entry.key);
                      } else {
                        _selectedEvents.add(entry.key);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedEvents.add(entry.key);
                                  } else {
                                    _selectedEvents.remove(entry.key);
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['endpoint'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Retry Count: ${event['retry_count'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Step 1: View Details button
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              color: Colors.blue,
                              onPressed: () => _viewEventDetails(event),
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              color: Colors.orange,
                              onPressed: _canReprocess(entry.key, event) && !_isReprocessCoolingDown(entry.key)
                                  ? () => _reprocessEvent(entry.key, event)
                                  : null,
                              tooltip: _isReprocessCoolingDown(entry.key)
                                  ? 'Retry in ${_secondsRemaining(_reprocessCooldownUntil[entry.key])}s'
                                  : 'Reprocess failed event',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: Colors.red,
                              onPressed: () => _deleteEvent(entry.key),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildOutcomeBadge('Status', _resolveStatus(entry.key, event)),
                            if (_resolveDedupeOutcome(entry.key, event) != null)
                              _buildOutcomeBadge('Dedupe', _resolveDedupeOutcome(entry.key, event)!),
                            if (_resolveFailureReason(entry.key, event) != null)
                              _buildOutcomeBadge('Failure', _resolveFailureReason(entry.key, event)!),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Timestamp: ${event['timestamp']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (event['last_error'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Error: ${event['last_error']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  String _resolveStatus(dynamic queueKey, Map<String, dynamic> event) {
    final server = _serverOutcomeByKey[queueKey];
    return (server?['status'] ?? event['status'] ?? 'queued').toString();
  }

  String? _resolveDedupeOutcome(dynamic queueKey, Map<String, dynamic> event) {
    final server = _serverOutcomeByKey[queueKey];
    final value = server?['dedupeOutcome'] ?? event['dedupe_outcome'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _resolveFailureReason(dynamic queueKey, Map<String, dynamic> event) {
    final server = _serverOutcomeByKey[queueKey];
    final value = server?['failureReason'] ?? event['failure_reason'] ?? event['last_error'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool _canReprocess(dynamic queueKey, Map<String, dynamic> event) {
    final status = _resolveStatus(queueKey, event).toLowerCase();
    return status == 'failed' || status == 'error';
  }

  Widget _buildOutcomeBadge(String label, String value) {
    final normalized = value.toLowerCase();
    Color color;
    if (normalized == 'sent' || normalized == 'success' || normalized == 'processed') {
      color = Colors.green;
    } else if (normalized == 'queued' || normalized == 'pending' || normalized == 'retrying') {
      color = Colors.blue;
    } else if (normalized == 'duplicate' || normalized == 'deduped') {
      color = Colors.purple;
    } else if (normalized == 'failed' || normalized == 'error') {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
