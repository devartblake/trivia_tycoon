import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stock_policy_form_model.dart';
import 'stock_interval_selector.dart';

/// Editable card for configuring the default stock policy of a catalog SKU.
/// Calls [onSave] with the updated model; calls [onReset] to immediately
/// reset live stock for this SKU (destructive — shows confirmation).
class StockPolicyEditorCard extends StatefulWidget {
  final StockPolicyFormModel initial;
  final Future<void> Function(StockPolicyFormModel) onSave;
  final Future<void> Function()? onReset;

  const StockPolicyEditorCard({
    super.key,
    required this.initial,
    required this.onSave,
    this.onReset,
  });

  @override
  State<StockPolicyEditorCard> createState() => _StockPolicyEditorCardState();
}

class _StockPolicyEditorCardState extends State<StockPolicyEditorCard> {
  late StockPolicyFormModel _model;
  final _maxQtyController = TextEditingController();
  final _minLevelController = TextEditingController();
  bool _saving = false;
  bool _resetting = false;
  String? _error;

  static const _policyTypes = [
    'unlimited',
    'per_user',
    'one_time_purchase',
    'time_limited',
    'event_limited',
  ];

  @override
  void initState() {
    super.initState();
    _model = widget.initial;
    _maxQtyController.text = _model.maxQuantity?.toString() ?? '';
    _minLevelController.text = _model.minimumLevel?.toString() ?? '';
  }

  @override
  void dispose() {
    _maxQtyController.dispose();
    _minLevelController.dispose();
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
            _buildPolicyTypeSelector(),
            const SizedBox(height: 16),
            _buildQuantityRow(),
            const SizedBox(height: 16),
            StockIntervalSelector(
              value: _model.resetInterval,
              onChanged: (v) =>
                  setState(() => _model = _model.copyWith(resetInterval: v, clearResetInterval: v == null)),
            ),
            const SizedBox(height: 16),
            _buildExpiryRow(),
            const SizedBox(height: 16),
            _buildToggles(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_outlined,
              color: Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _model.itemTitle.isNotEmpty ? _model.itemTitle : _model.sku,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'SKU: ${_model.sku}  ·  ${_model.itemType}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stock Policy',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _policyTypes.map((type) {
            final selected = _model.policyType == type;
            return ChoiceChip(
              label: Text(_formatPolicyType(type)),
              selected: selected,
              onSelected: (_) => setState(() => _model = _model.copyWith(
                    policyType: type,
                    isUnlimited: type == 'unlimited',
                    isOneTimePurchase: type == 'one_time_purchase',
                  )),
              selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? const Color(0xFF6366F1) : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantityRow() {
    if (_model.isUnlimited) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _maxQtyController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Max Quantity',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) => setState(() => _model = _model.copyWith(
                maxQuantity: int.tryParse(v), clearMaxQuantity: v.isEmpty)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _minLevelController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Min Level (optional)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) => setState(() => _model = _model.copyWith(
                minimumLevel: int.tryParse(v),
                clearMinimumLevel: v.isEmpty)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Expiry: ${_model.expiresAt != null ? _model.expiresAt!.toLocal().toString().substring(0, 16) : 'None'}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        TextButton.icon(
          onPressed: _pickExpiry,
          icon: const Icon(Icons.calendar_today, size: 14),
          label: const Text('Set'),
        ),
        if (_model.expiresAt != null)
          TextButton(
            onPressed: () =>
                setState(() => _model = _model.copyWith(clearExpiresAt: true)),
            child: const Text('Clear'),
          ),
      ],
    );
  }

  Widget _buildToggles() {
    return Wrap(
      spacing: 24,
      runSpacing: 4,
      children: [
        _Toggle(
          label: 'Visible',
          value: _model.isVisible,
          onChanged: (v) =>
              setState(() => _model = _model.copyWith(isVisible: v)),
        ),
        _Toggle(
          label: 'Purchasable',
          value: _model.isPurchasable,
          onChanged: (v) =>
              setState(() => _model = _model.copyWith(isPurchasable: v)),
        ),
        _Toggle(
          label: 'Premium Only',
          value: _model.requiresPremium,
          onChanged: (v) =>
              setState(() => _model = _model.copyWith(requiresPremium: v)),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onReset != null)
          OutlinedButton.icon(
            onPressed: _resetting ? null : _confirmReset,
            icon: _resetting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 14),
            label: const Text('Reset Stock'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 14),
          label: const Text('Save Policy'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.expiresAt?.toLocal() ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _model = _model.copyWith(
          expiresAt: DateTime(picked.year, picked.month, picked.day,
              23, 59, 59)));
    }
  }

  Future<void> _save() async {
    final err = _model.validate();
    if (err != null) {
      setState(() => _error = err);
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
            content: Text('Policy saved.'),
            backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Stock Now?'),
        content: Text(
            'This will immediately reset live stock counts for "${_model.sku}". This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _resetting = true);
    try {
      await widget.onReset!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Stock reset.'),
            backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Reset failed: $e');
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  String _formatPolicyType(String type) {
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
