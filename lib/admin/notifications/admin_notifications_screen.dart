import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trivia_tycoon/admin/notifications/widgets/role_gate.dart';
import '../../core/services/notification_service.dart';
import '../../game/providers/notification_providers.dart';
import '../../game/providers/riverpod_providers.dart';
import 'channel_manager_screen.dart';
import 'widgets/notification_form.dart';
import 'widgets/history_list.dart';
import 'widgets/segmented_tabs.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _dateFormat = DateFormat('EEE, MMM d – h:mm a');
  int _tabIndex = 0;

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _channelFilterController = TextEditingController();
  String? _statusFilter;
  bool _isHistoryLoading = false;
  bool _didLoadServerHistory = false;
  List<Map<String, dynamic>> _serverHistory = <Map<String, dynamic>>[];
  bool _isServerScheduledLoading = false;
  bool _didLoadServerScheduled = false;
  List<Map<String, dynamic>> _serverScheduled = <Map<String, dynamic>>[];


  @override
  void initState() {
    super.initState();
    _loadServerHistory();
    _loadServerTemplates();
    _loadServerScheduled();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _channelFilterController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(scheduledProvider);
    ref.invalidate(permissionAllowedProvider);
    await _loadServerHistory();
    await _loadServerTemplates();
    await _loadServerScheduled();
  }

  Future<void> _loadServerHistory() async {
    setState(() => _isHistoryLoading = true);
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get(
        '/admin/notifications/history',
        queryParameters: {
          if (_fromController.text.trim().isNotEmpty) 'from': _fromController.text.trim(),
          if (_toController.text.trim().isNotEmpty) 'to': _toController.text.trim(),
          if (_channelFilterController.text.trim().isNotEmpty)
            'channelKey': _channelFilterController.text.trim(),
          if (_statusFilter != null && _statusFilter!.isNotEmpty) 'status': _statusFilter!,
        },
      );

      final items = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json)
          .items;
      if (!mounted) return;
      setState(() {
        _serverHistory = items;
        _didLoadServerHistory = true;
      });
    } catch (_) {
      // leave existing local history widget as fallback data source.
    } finally {
      if (mounted) {
        setState(() => _isHistoryLoading = false);
      }
    }
  }

  Future<void> _loadServerTemplates() async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/notifications/templates');
      final items = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json)
          .items;
      final store = ref.read(templateStoreProvider);
      for (final t in items) {
        final id = (t['id'] ?? t['templateId'] ?? '').toString();
        if (id.isEmpty) continue;
        final title = (t['title'] ?? '').toString();
        final body = (t['body'] ?? '').toString();
        final payloadRaw = t['payload'];
        Map<String, String>? payload;
        if (payloadRaw is Map) {
          payload = payloadRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        await store.saveRaw(id, title, body, payload);
      }
    } catch (_) {
      // keep local template store fallback
    }
  }


  Future<void> _loadServerScheduled() async {
    setState(() => _isServerScheduledLoading = true);
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/notifications/schedule');
      final items = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json)
          .items;
      if (!mounted) return;
      setState(() {
        _serverScheduled = items;
        _didLoadServerScheduled = true;
      });
    } catch (_) {
      // Keep local scheduled list as fallback.
    } finally {
      if (mounted) {
        setState(() => _isServerScheduledLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedAsync = ref.watch(permissionAllowedProvider);
    final scheduledAsync = ref.watch(scheduledProvider);
    final isAdminAsync = ref.watch(isAdminProvider);
    final isAdmin = isAdminAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPermissionCard(allowedAsync),
                    const SizedBox(height: 24),

                    // Segmented tabs
                    _buildSegmentedTabs(),
                    const SizedBox(height: 24),

                    // Content based on selected tab
                    _buildTabContent(isAdmin, scheduledAsync),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          tooltip: 'Channels',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const ChannelManagerSheet(),
            );
            setState(() {});
          },
        ),
        IconButton(
          tooltip: 'Request Permission',
          onPressed: () async {
            await NotificationService().requestPermission();
            _refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permission requested'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Cancel All',
          onPressed: () async {
            await NotificationService().cancelAll();
            _refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications canceled'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Send and schedule notifications',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard(AsyncValue<bool> allowedAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: allowedAsync.when(
        data: (allowed) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: allowed
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    allowed
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: allowed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allowed ? 'Permission Granted' : 'Permission Required',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allowed
                            ? 'Notifications are enabled on this device'
                            : 'Request permission to send notifications',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!allowed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await NotificationService().requestPermission();
                    _refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_active_rounded, size: 20),
                  label: const Text(
                    'Request Permission',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return SegmentedTabs(
      index: _tabIndex,
      onChanged: (i) => setState(() => _tabIndex = i),
      tabs: const ['All', 'Scheduled', 'History'],
    );
  }

  Widget _buildTabContent(bool isAdmin, AsyncValue<List<dynamic>> scheduledAsync) {
    switch (_tabIndex) {
      case 0: // All tab
        return Column(
          children: [
            _buildComposeSection(isAdmin),
            const SizedBox(height: 32),
            _buildScheduledSection(scheduledAsync),
          ],
        );
      case 1: // Scheduled tab
        return _buildScheduledSection(scheduledAsync);
      case 2: // History tab
        return _buildServerHistorySection();
      default:
        return _buildComposeSection(isAdmin);
    }
  }


  Widget _buildServerHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'From (ISO-8601)',
                  hintText: '2026-01-01T00:00:00Z',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'To (ISO-8601)',
                  hintText: '2026-01-31T23:59:59Z',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _channelFilterController,
                decoration: const InputDecoration(
                  labelText: 'Channel Key',
                  hintText: 'marketing.push',
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String?>(
              value: _statusFilter,
              hint: const Text('Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'queued', child: Text('queued')),
                DropdownMenuItem(value: 'sent', child: Text('sent')),
                DropdownMenuItem(value: 'failed', child: Text('failed')),
                DropdownMenuItem(value: 'retrying', child: Text('retrying')),
              ],
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isHistoryLoading ? null : _loadServerHistory,
              icon: const Icon(Icons.search),
              label: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isHistoryLoading) const LinearProgressIndicator(minHeight: 2),
        if (!_didLoadServerHistory)
          const HistoryList()
        else if (_serverHistory.isEmpty)
          _buildHistoryEmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _serverHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = _serverHistory[i];
                final rawStatus = (item['status'] ?? item['deliveryStatus'] ?? item['delivery_status'] ?? 'queued')
                    .toString()
                    .toLowerCase();
                final statusColor = switch (rawStatus) {
                  'sent' => const Color(0xFF10B981),
                  'failed' => const Color(0xFFEF4444),
                  'retrying' => const Color(0xFFF59E0B),
                  _ => const Color(0xFF3B82F6),
                };

                final sentAtRaw = (item['sentAt'] ?? item['sent_at'] ?? item['createdAt'] ?? item['created_at'])?.toString();
                String when = '-';
                if (sentAtRaw != null && sentAtRaw.isNotEmpty) {
                  final dt = DateTime.tryParse(sentAtRaw)?.toUtc().toLocal();
                  if (dt != null) {
                    when = _dateFormat.format(dt);
                  }
                }

                return ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(item['title']?.toString() ?? '(untitled)'),
                  subtitle: Text(
                    'channel=${item['channelKey'] ?? item['channel_key'] ?? '-'} • $when\n'
                    '${item['failureReason'] ?? item['failure_reason'] ?? item['message'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rawStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

  Widget _buildComposeSection(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Compose Notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RoleGate(
          isAllowed: isAdmin,
          child: const NotificationForm(),
        ),
      ],
    );
  }

  Widget _buildScheduledSection(AsyncValue<List<dynamic>> scheduledAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isServerScheduledLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Scheduled Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_didLoadServerScheduled ? _serverScheduled.length : (scheduledAsync.valueOrNull?.length ?? 0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_didLoadServerScheduled)
          _serverScheduled.isEmpty
              ? _buildEmptyState()
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _serverScheduled.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = _serverScheduled[i];
                      final status =
                          (item['status'] ?? item['deliveryStatus'] ?? 'queued')
                              .toString()
                              .toLowerCase();
                      final statusColor = switch (status) {
                        'sent' => const Color(0xFF10B981),
                        'failed' => const Color(0xFFEF4444),
                        'retrying' => const Color(0xFFF59E0B),
                        _ => const Color(0xFF3B82F6),
                      };

                      final atRaw = (item['scheduledAt'] ??
                              item['scheduled_at'] ??
                              item['createdAt'] ??
                              item['created_at'])
                          ?.toString();
                      String scheduledAt = '-';
                      if (atRaw != null && atRaw.isNotEmpty) {
                        final dt = DateTime.tryParse(atRaw)?.toUtc().toLocal();
                        if (dt != null) {
                          scheduledAt = _dateFormat.format(dt);
                        }
                      }

                      return ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(item['title']?.toString() ?? '(untitled)'),
                        subtitle: Text(
                          'channel=${item['channelKey'] ?? item['channel_key'] ?? '-'} • $scheduledAt',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
        else
          scheduledAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState();
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final schedule = n.schedule;
                    return _buildScheduledItem(n, schedule);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to load scheduled: $e',
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF6B7280)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No notification history found for the selected filters.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildScheduledItem(dynamic n, dynamic schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.content?.title ?? '(no title)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                schedule == null
                    ? const Text(
                  'Scheduled',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                )
                    : FutureBuilder<DateTime?>(
                  future: AwesomeNotifications().getNextDate(schedule),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Computing next run…',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      );
                    }
                    final dt = snap.data;
                    return Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dt != null ? _dateFormat.format(dt) : '–',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
            onPressed: () async {
              final id = n.content?.id;
              if (id != null) {
                await NotificationService().cancel(id);
                _refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification cancelled'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No scheduled notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the form above to schedule a notification',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
