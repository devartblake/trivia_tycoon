import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../game/providers/notification_providers.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../game/services/channel_prefs.dart';

class ChannelManagerSheet extends ConsumerStatefulWidget {
  const ChannelManagerSheet({super.key});

  @override
  ConsumerState<ChannelManagerSheet> createState() =>
      _ChannelManagerSheetState();
}

class _ChannelManagerSheetState extends ConsumerState<ChannelManagerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _keyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  NotificationImportance _importance = NotificationImportance.Default;

  /// Cache enabled states for quick rebuilds.
  final Map<String, bool> _enabled = {};
  bool _isLoadingServerChannels = false;
  bool _didLoadServerChannels = false;
  List<Map<String, dynamic>> _serverChannels = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _seedEnabledStates();
    _loadServerChannels();
  }

  Future<void> _seedEnabledStates() async {
    final channels = NotificationService().knownChannels;
    for (final c in channels) {
      final key = c.channelKey ?? '';
      if (key.isEmpty) continue;
      _enabled[key] = await ChannelPrefs.instance.getEnabled(key);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadServerChannels() async {
    setState(() => _isLoadingServerChannels = true);
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response =
          await serviceManager.apiService.get('/admin/notifications/channels');
      final items = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json)
          .items;
      if (!mounted) return;
      setState(() {
        _serverChannels = items;
        _didLoadServerChannels = true;
      });
    } catch (_) {
      // Keep local channel list as fallback in unsupported environments.
    } finally {
      if (mounted) {
        setState(() => _isLoadingServerChannels = false);
      }
    }
  }

  List<_RemoteChannelRow> get _remoteRows {
    return _serverChannels
        .map((raw) {
          final key = (raw['channelKey'] ?? raw['key'] ?? '').toString();
          final name = (raw['channelName'] ?? raw['name'] ?? key).toString();
          final enabled = raw['enabled'] == true;
          return _RemoteChannelRow(key: key, name: name, enabled: enabled);
        })
        .where((r) => r.key.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(notificationChannelsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            Text('Channel Manager',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Existing channels (enable/disable)
            Card(
              child: _isLoadingServerChannels
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    )
                  : (_didLoadServerChannels
                      ? (_remoteRows.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No server notification channels found.',
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _remoteRows.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final row = _remoteRows[i];
                                final current =
                                    _enabled[row.key] ?? row.enabled;
                                return ListTile(
                                  title: Text(row.name),
                                  subtitle: Text(row.key),
                                  trailing: Switch.adaptive(
                                    value: current,
                                    onChanged: (v) =>
                                        _toggleChannel(row.key, v),
                                  ),
                                );
                              },
                            ))
                      : channelsAsync.when(
                          data: (channels) => ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: channels.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = channels[i];
                              final key = c.channelKey ?? '';
                              final current = _enabled[key] ?? true;
                              return ListTile(
                                title: Text(c.channelName ?? key),
                                subtitle: Text(key),
                                trailing: Switch.adaptive(
                                  value: current,
                                  onChanged: (v) => _toggleChannel(key, v),
                                ),
                              );
                            },
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16),
                            child: LinearProgressIndicator(),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Failed to load channels: $e'),
                          ),
                        )),
            ),
            const SizedBox(height: 12),

            // Drafts list from AppSettings
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ChannelPrefs.instance.getDrafts(),
              builder: (context, snap) {
                final drafts = snap.data ?? [];
                if (drafts.isEmpty) return const SizedBox.shrink();
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text('Draft Channels (activate next app init)'),
                        dense: true,
                      ),
                      const Divider(height: 1),
                      ...drafts.map((d) {
                        final key = d['key'] as String? ?? '';
                        final name = d['name'] as String? ?? key;
                        final desc = d['description'] as String? ?? '';
                        final importanceStr =
                            (d['importance'] as String?)?.trim();
                        final imp = NotificationImportance.values.firstWhere(
                          (v) => v.toString().split('.').last == importanceStr,
                          orElse: () => NotificationImportance.Default,
                        );
                        return ListTile(
                          title: Text('$name • $key'),
                          subtitle: Text('$desc • Importance: ${imp.name}'),
                          trailing: IconButton(
                            tooltip: 'Remove draft',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ChannelPrefs.instance.removeDraft(key);
                              if (mounted) setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Draft removed')),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Create (register next init) channel
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text('Create New Channel (applies after next app init)',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _keyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Channel Key (snake_case)',
                          hintText: 'e.g., system_alerts',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Channel Name',
                          hintText: 'System Alerts',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Critical system alerts',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<NotificationImportance>(
                        value: _importance,
                        decoration:
                            const InputDecoration(labelText: 'Importance'),
                        items: NotificationImportance.values.map((imp) {
                          return DropdownMenuItem(
                            value: imp,
                            child: Text(imp.name),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _importance = v ?? _importance),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saveChannelDraft,
                        child: const Text('Save Channel Draft'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleChannel(String key, bool enabled) async {
    await ChannelPrefs.instance.setEnabled(key, enabled);
    setState(() => _enabled[key] = enabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Channel $key ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _saveChannelDraft() async {
    if (!_formKey.currentState!.validate()) return;
    final key = _keyCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    await ChannelPrefs.instance.addDraft(
      key: key,
      name: name,
      description: desc,
      importance: _importance,
    );

    if (mounted) {
      _keyCtrl.clear();
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() {}); // refresh drafts list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Draft saved. Will activate on next app init.')),
      );
    }
  }
}

class _RemoteChannelRow {
  final String key;
  final String name;
  final bool enabled;

  const _RemoteChannelRow({
    required this.key,
    required this.name,
    required this.enabled,
  });
}
