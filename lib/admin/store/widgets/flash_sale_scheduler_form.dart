import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stock_override_form_model.dart';

/// Form for creating or editing a flash sale window.
/// Shows conflict warning when end time is before start time.
class FlashSaleSchedulerForm extends StatefulWidget {
  final FlashSaleFormModel initial;
  final Future<void> Function(FlashSaleFormModel) onSave;
  final Future<void> Function()? onDelete;

  const FlashSaleSchedulerForm({
    super.key,
    required this.initial,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<FlashSaleSchedulerForm> createState() => _FlashSaleSchedulerFormState();
}

class _FlashSaleSchedulerFormState extends State<FlashSaleSchedulerForm> {
  late FlashSaleFormModel _model;
  final _titleCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _discountPctCtrl = TextEditingController();
  final _discountAmtCtrl = TextEditingController();
  final _cohortCtrl = TextEditingController();
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = widget.initial;
    _titleCtrl.text = _model.title;
    _skuCtrl.text = _model.linkedSku;
    _capCtrl.text = _model.purchaseCapPerUser.toString();
    _discountPctCtrl.text = _model.discountPercent?.toString() ?? '';
    _discountAmtCtrl.text = _model.discountAmount?.toString() ?? '';
    _cohortCtrl.text = _model.eligibleCohort ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _skuCtrl.dispose();
    _capCtrl.dispose();
    _discountPctCtrl.dispose();
    _discountAmtCtrl.dispose();
    _cohortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 24),

            // Title + SKU
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Sale Title',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) =>
                  setState(() => _model = _model.copyWith(title: v)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _skuCtrl,
              decoration: const InputDecoration(
                labelText: 'Linked SKU',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) =>
                  setState(() => _model = _model.copyWith(linkedSku: v)),
            ),
            const SizedBox(height: 16),

            // Time window
            _buildTimeRow(),
            if (_model.hasConflict)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Color(0xFFF59E0B), size: 14),
                    SizedBox(width: 6),
                    Text('End time is before start time.',
                        style: TextStyle(
                            color: Color(0xFFF59E0B), fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Cap + discount row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Cap Per User',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _model = _model.copyWith(
                        purchaseCapPerUser:
                            int.tryParse(v) ?? _model.purchaseCapPerUser)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _discountPctCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _model = _model.copyWith(
                        discountPercent: double.tryParse(v),
                        clearDiscountPercent: v.isEmpty)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _discountAmtCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Discount Coins',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _model = _model.copyWith(
                        discountAmount: int.tryParse(v),
                        clearDiscountAmount: v.isEmpty)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cohortCtrl,
              decoration: const InputDecoration(
                labelText: 'Eligible Cohort (optional)',
                hintText: 'e.g. vip, churn_risk',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() => _model = _model.copyWith(
                  eligibleCohort: v.isEmpty ? null : v,
                  clearCohort: v.isEmpty)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _model.isActive,
                  onChanged: (v) =>
                      setState(() => _model = _model.copyWith(isActive: v)),
                  activeColor: const Color(0xFF6366F1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                const Text('Active', style: TextStyle(fontSize: 13)),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12)),
            ],
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isNew = _model.saleId == null;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bolt, color: Color(0xFFEF4444), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          isNew ? 'New Flash Sale' : 'Edit Flash Sale',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(child: _TimePickerField(
          label: 'Start Time',
          value: _model.startTime,
          onChanged: (dt) =>
              setState(() => _model = _model.copyWith(startTime: dt)),
        )),
        const SizedBox(width: 12),
        Expanded(child: _TimePickerField(
          label: 'End Time',
          value: _model.endTime,
          onChanged: (dt) =>
              setState(() => _model = _model.copyWith(endTime: dt)),
        )),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onDelete != null && _model.saleId != null)
          OutlinedButton.icon(
            onPressed: _deleting ? null : _confirmDelete,
            icon: _deleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline, size: 14),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: (_saving || _model.hasConflict) ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 14),
          label: const Text('Save Sale'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_model.title.isEmpty || _model.linkedSku.isEmpty) {
      setState(() => _error = 'Title and SKU are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Flash sale saved.'),
            backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Flash Sale?'),
        content: Text('Delete "${_model.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete!();
    } catch (e) {
      if (mounted) setState(() => _error = 'Delete failed: $e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _TimePickerField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value.toLocal().toString().substring(0, 16),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value.toLocal(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value.toLocal()),
    );
    if (time == null) return;
    onChanged(DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }
}
