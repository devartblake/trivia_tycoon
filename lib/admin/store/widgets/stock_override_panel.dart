import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stock_override_form_model.dart';

/// Panel for applying a player-specific (or cohort-specific) stock override.
/// Every submit is written to an audit log by the backend — the UI reflects
/// this with a mandatory reason/notes field.
class StockOverridePanel extends StatefulWidget {
  final String? initialPlayerId;
  final String? initialSku;
  final Future<void> Function(StockOverrideFormModel) onSubmit;
  final List<Map<String, dynamic>> existingOverrides;
  final Future<void> Function(String overrideId)? onDeleteOverride;

  const StockOverridePanel({
    super.key,
    this.initialPlayerId,
    this.initialSku,
    required this.onSubmit,
    this.existingOverrides = const [],
    this.onDeleteOverride,
  });

  @override
  State<StockOverridePanel> createState() => _StockOverridePanelState();
}

class _StockOverridePanelState extends State<StockOverridePanel> {
  late StockOverrideFormModel _model;
  final _playerIdCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _maxQtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  static const _reasonCodes = [
    'support_compensation',
    'churn_risk_rescue',
    'qa_testing',
    'creator_grant',
    'vip_override',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _model = StockOverrideFormModel(
      playerId: widget.initialPlayerId,
      sku: widget.initialSku ?? '',
    );
    _playerIdCtrl.text = widget.initialPlayerId ?? '';
    _skuCtrl.text = widget.initialSku ?? '';
  }

  @override
  void dispose() {
    _playerIdCtrl.dispose();
    _skuCtrl.dispose();
    _maxQtyCtrl.dispose();
    _notesCtrl.dispose();
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
            _buildTargetRow(),
            const SizedBox(height: 12),
            _buildOverrideFields(),
            const SizedBox(height: 12),
            _buildActionToggles(),
            const SizedBox(height: 12),
            _buildReasonRow(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (required)',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) =>
                  setState(() => _model = _model.copyWith(notes: v)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 14),
                label: const Text('Apply Override'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
            if (widget.existingOverrides.isNotEmpty) ...[
              const Divider(height: 28),
              _buildExistingOverrides(),
            ],
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
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.manage_accounts_outlined,
              color: Color(0xFF8B5CF6), size: 20),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Override',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('All overrides are audit-logged.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _playerIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Player ID (UUID)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) =>
                setState(() => _model = _model.copyWith(playerId: v)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _skuCtrl,
            decoration: const InputDecoration(
              labelText: 'SKU',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) =>
                setState(() => _model = _model.copyWith(sku: v)),
          ),
        ),
      ],
    );
  }

  Widget _buildOverrideFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _maxQtyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Override Max Qty',
              hintText: 'Optional',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) => setState(() => _model = _model.copyWith(
                overrideMaxQuantity: int.tryParse(v),
                clearQuantity: v.isEmpty)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ExpiryField(
            value: _model.overrideExpiresAt,
            onChanged: (dt) =>
                setState(() => _model = _model.copyWith(overrideExpiresAt: dt)),
            onClear: () => setState(
                () => _model = _model.copyWith(clearExpiry: true)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionToggles() {
    return Row(
      children: [
        _ActionToggle(
          label: 'Grant Free',
          icon: Icons.redeem,
          value: _model.grantFreeItem,
          color: const Color(0xFF10B981),
          onChanged: (v) =>
              setState(() => _model = _model.copyWith(grantFreeItem: v)),
        ),
        const SizedBox(width: 16),
        _ActionToggle(
          label: 'Reset Stock',
          icon: Icons.refresh,
          value: _model.resetStockNow,
          color: const Color(0xFFEF4444),
          onChanged: (v) =>
              setState(() => _model = _model.copyWith(resetStockNow: v)),
        ),
      ],
    );
  }

  Widget _buildReasonRow() {
    return DropdownButtonFormField<String>(
      value: _model.reasonCode,
      decoration: const InputDecoration(
        labelText: 'Reason Code',
        border: OutlineInputBorder(),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: _reasonCodes
          .map((code) => DropdownMenuItem(
              value: code,
              child: Text(_formatCode(code),
                  style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (v) =>
          setState(() => _model = _model.copyWith(reasonCode: v)),
    );
  }

  Widget _buildExistingOverrides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Overrides',
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.existingOverrides.map((o) {
          final id = o['id']?.toString() ?? o['overrideId']?.toString() ?? '';
          final sku = o['sku']?.toString() ?? '?';
          final reason = o['reasonCode']?.toString() ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: const Color(0xFFF8FAFF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: const Color(0xFF64748B).withValues(alpha: 0.1))),
            child: ListTile(
              dense: true,
              title: Text(sku,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(reason.isNotEmpty ? _formatCode(reason) : id,
                  style: const TextStyle(fontSize: 11)),
              trailing: widget.onDeleteOverride != null && id.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444), size: 18),
                      onPressed: () => widget.onDeleteOverride!(id),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Future<void> _submit() async {
    if (_model.sku.isEmpty) {
      setState(() => _error = 'SKU is required.');
      return;
    }
    if (_notesCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Notes are required for audit purposes.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Override applied and logged.'),
            backgroundColor: Color(0xFF8B5CF6)));
        _maxQtyCtrl.clear();
        _notesCtrl.clear();
        setState(() {
          _model = StockOverrideFormModel(
              playerId: _model.playerId, sku: _model.sku);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Submit failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatCode(String code) =>
      code.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class _ActionToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ActionToggle(
      {required this.label,
      required this.icon,
      required this.value,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: value ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: value ? color : Colors.grey[500], size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: value ? color : Colors.grey[600],
                    fontWeight:
                        value ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _ExpiryField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;

  const _ExpiryField(
      {required this.value, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Override Expiry',
                hintText: 'Optional',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: Text(
                value != null
                    ? value!.toLocal().toString().substring(0, 10)
                    : 'Not set',
                style: TextStyle(
                    fontSize: 13,
                    color:
                        value != null ? Colors.black87 : Colors.grey[400]),
              ),
            ),
          ),
        ),
        if (value != null)
          IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: onClear),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value?.toLocal() ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(picked);
  }
}
