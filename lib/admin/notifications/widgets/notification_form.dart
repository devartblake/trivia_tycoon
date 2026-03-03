import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../game/providers/notification_providers.dart';
import '../../../game/providers/notification_template_store.dart';
import '../../../game/providers/riverpod_providers.dart';

class NotificationForm extends ConsumerStatefulWidget {
  const NotificationForm({super.key});

  @override
  ConsumerState<NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends ConsumerState<NotificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _payloadCtrl = TextEditingController(text: '{"type":"admin","source":"panel"}');
  final _idCtrl = TextEditingController(text: '1001');
  final _templateIdCtrl = TextEditingController();

  String _channelKey = NotificationService.adminBasicChannel;
  DateTime? _scheduleAt;
  bool _repeats = false;
  int? _weeklyWeekday;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _payloadCtrl.dispose();
    _idCtrl.dispose();
    _templateIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 2))),
    );
    if (time == null) return;
    setState(() {
      _scheduleAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String? _validateJson(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      json.decode(value);
      return null;
    } catch (_) {
      return 'Invalid JSON';
    }
  }

  Map<String, String>? _parsePayload() {
    final raw = _payloadCtrl.text.trim();
    if (raw.isEmpty) return null;
    final decoded = json.decode(raw);
    if (decoded is Map) {
      return decoded.map<String, String>((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  Future<void> _handleSendNow() async {
    if (!_formKey.currentState!.validate()) return;
    final id = int.tryParse(_idCtrl.text.trim()) ??
        (DateTime.now().millisecondsSinceEpoch % 100000);
    final actions = ref.read(notificationAdminActionsProvider.notifier);
    await actions.sendNow(
      id: id,
      channelKey: _channelKey,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      payload: _parsePayload(),
    );
    if (mounted) {
      final err = ref.read(notificationAdminActionsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err == null ? 'Notification sent immediately!' : 'Error: $err'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: err == null ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a schedule time'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }
    final id = int.tryParse(_idCtrl.text.trim()) ??
        (DateTime.now().millisecondsSinceEpoch % 100000);
    final actions = ref.read(notificationAdminActionsProvider.notifier);
    await actions.scheduleAt(
      id: id,
      channelKey: _channelKey,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      scheduledAt: _scheduleAt!,
      payload: _parsePayload(),
      repeats: _repeats,
    );
    if (mounted) {
      final err = ref.read(notificationAdminActionsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err == null ? 'Notification scheduled!' : 'Error: $err'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: err == null ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      if (err == null) {
        // Clear form on success
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _scheduleAt = null;
          _repeats = false;
        });
      }
    }
  }

  Future<void> _saveTemplate() async {
    final store = ref.read(templateStoreProvider);
    final id = _templateIdCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template ID required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final payload = _parsePayload();
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      await serviceManager.apiService.post(
        '/admin/notifications/templates',
        body: {
          'id': id,
          'title': _titleCtrl.text.trim(),
          'body': _bodyCtrl.text.trim(),
          if (payload != null) 'payload': payload,
        },
      );
    } catch (_) {
      // keep local template flow as fallback when backend templates endpoint is unavailable.
    }

    await store.saveRaw(id, _titleCtrl.text.trim(), _bodyCtrl.text.trim(), payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template saved successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _loadTemplate(NotificationTemplate t) {
    setState(() {
      _titleCtrl.text = t.title;
      _bodyCtrl.text = t.body;
      _payloadCtrl.text = jsonEncode(t.payload ?? {});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "${t.id}" loaded'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(notificationChannelsProvider);
    final actionsState = ref.watch(notificationAdminActionsProvider);
    final templatesAsync = ref.watch(templatesProvider);

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
      padding: const EdgeInsets.all(24),
      child: AbsorbPointer(
        absorbing: actionsState.isLoading,
        child: Opacity(
          opacity: actionsState.isLoading ? 0.6 : 1,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Templates Section
                _buildTemplatesSection(templatesAsync),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),

                // ID and Channel Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _idCtrl,
                        label: 'ID',
                        hint: '1001',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildChannelDropdown(channelsAsync),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                _buildTextField(
                  controller: _titleCtrl,
                  label: 'Title *',
                  hint: 'System update at 2 PM',
                  icon: Icons.title,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Body
                _buildTextField(
                  controller: _bodyCtrl,
                  label: 'Body *',
                  hint: 'We will perform maintenance...',
                  icon: Icons.description,
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Payload
                _buildTextField(
                  controller: _payloadCtrl,
                  label: 'Payload (JSON, optional)',
                  hint: '{"type":"admin"}',
                  icon: Icons.code,
                  maxLines: 3,
                  validator: _validateJson,
                ),
                const SizedBox(height: 16),

                // Schedule Section
                _buildScheduleSection(),
                const SizedBox(height: 16),

                // Repeat Options
                _buildRepeatOptions(),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(actionsState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesSection(AsyncValue<List<NotificationTemplate>> templatesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.dashboard_customize,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Templates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            // Show loading indicator next to title
            templatesAsync.maybeWhen(
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Template Dropdown
        templatesAsync.when(
          data: (list) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonFormField<NotificationTemplate>(
              value: null,
              hint: const Text(
                'Load Template',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.folder_outlined, color: Color(0xFF8B5CF6), size: 20),
              ),
              items: [
                const DropdownMenuItem<NotificationTemplate>(
                  value: null,
                  child: Text(
                    'Select a template...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
                ),
                ...list.map((t) => DropdownMenuItem<NotificationTemplate>(
                  value: t,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.id,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              onChanged: (t) => t == null ? null : _loadTemplate(t),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
              isExpanded: true,
            ),
          ),
          loading: () => Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading templates...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading templates: $e',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Template ID and Save Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _templateIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Template ID',
                  hintText: 'my-template',
                  prefixIcon: const Icon(
                    Icons.label_outline,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _saveTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save, size: 18),
              label: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6366F1)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignLabelWithHint: maxLines > 1,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildChannelDropdown(AsyncValue<List<dynamic>> channelsAsync) {
    return channelsAsync.when(
      data: (channels) {
        // Build channel items
        final items = channels
            .map((c) => DropdownMenuItem<String>(
          value: c.channelKey,
          child: Text(
            c.channelName ?? c.channelKey!,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ))
            .toList();

        // Ensure admin channels present
        for (final key in [
          NotificationService.adminBasicChannel,
          NotificationService.adminPromosChannel
        ]) {
          if (!items.any((e) => e.value == key)) {
            items.add(DropdownMenuItem<String>(
              value: key,
              child: Text(key, style: const TextStyle(fontSize: 14)),
            ));
          }
        }

        final hasCurrentChannel = items.any((e) => e.value == _channelKey);
        final selectedChannel = hasCurrentChannel
            ? _channelKey
            : (items.isNotEmpty ? items.first.value! : _channelKey);

        if (!hasCurrentChannel && items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _channelKey = selectedChannel);
          });
        }

        return DropdownButtonFormField<String>(
          value: selectedChannel,
          decoration: InputDecoration(
            labelText: 'Channel',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.isNotEmpty
              ? items
              : [
            DropdownMenuItem(
              value: _channelKey,
              child: Text(_channelKey, style: const TextStyle(fontSize: 14)),
            ),
          ],
          onChanged: (v) => setState(() => _channelKey = v ?? _channelKey),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading channels: $e', style: const TextStyle(color: Color(0xFFEF4444))),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              if (_scheduleAt != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => setState(() => _scheduleAt = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _scheduleAt == null
                    ? const Text(
                  'No schedule set',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                )
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatScheduleDate(_scheduleAt!),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _pickSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.event, size: 18),
                label: const Text('Pick Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatOptions() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Repeat Options',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _repeats,
                onChanged: (v) => setState(() => _repeats = v ?? false),
                activeColor: const Color(0xFF3B82F6),
              ),
              const Text(
                'Repeat daily at this time',
                style: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<int?>(
              value: _weeklyWeekday,
              hint: const Text('Weekly (select weekday)', style: TextStyle(fontSize: 13)),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: null, child: Text('No weekly repeat')),
                ...List.generate(7, (i) {
                  final val = i + 1;
                  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                  return DropdownMenuItem(
                    value: val,
                    child: Text(days[i], style: const TextStyle(fontSize: 13)),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _weeklyWeekday = v),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AsyncValue<void> actionsState) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: actionsState.isLoading ? null : _handleSendNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: actionsState.isLoading
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.send_rounded, size: 20),
            label: const Text('Send Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: actionsState.isLoading ? null : _handleSchedule,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: actionsState.isLoading
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
                : const Icon(Icons.schedule_send, size: 20),
            label: const Text('Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  String _formatScheduleDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}