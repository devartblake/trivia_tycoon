import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stock_policy_form_model.dart';
import 'stock_interval_selector.dart';

/// Inline editor for a single reward's claim limits and payout settings.
class RewardLimitEditor extends StatefulWidget {
  final RewardLimitFormModel initial;
  final Future<void> Function(RewardLimitFormModel) onSave;

  const RewardLimitEditor({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<RewardLimitEditor> createState() => _RewardLimitEditorState();
}

class _RewardLimitEditorState extends State<RewardLimitEditor> {
  late RewardLimitFormModel _model;
  final _maxClaimsCtrl = TextEditingController();
  final _payoutCtrl = TextEditingController();
  final _streakCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = widget.initial;
    _maxClaimsCtrl.text = _model.maxClaimsPerInterval.toString();
    _payoutCtrl.text = _model.coinPayout.toString();
    _streakCtrl.text = _model.requiredStreak?.toString() ?? '';
  }

  @override
  void dispose() {
    _maxClaimsCtrl.dispose();
    _payoutCtrl.dispose();
    _streakCtrl.dispose();
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_giftcard,
                      color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _model.rewardId,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _model.isActive
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            _model.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                                fontSize: 11,
                                color: _model.isActive
                                    ? const Color(0xFF10B981)
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _model.isActive,
                  onChanged: (v) =>
                      setState(() => _model = _model.copyWith(isActive: v)),
                  activeColor: const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Claims + Payout row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxClaimsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Max Claims',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _model = _model.copyWith(
                        maxClaimsPerInterval:
                            int.tryParse(v) ?? _model.maxClaimsPerInterval)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _payoutCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Coin Payout',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _model =
                        _model.copyWith(coinPayout: int.tryParse(v) ?? 0)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            StockIntervalSelector(
              value: _model.interval,
              onChanged: (v) =>
                  setState(() => _model = _model.copyWith(interval: v ?? 'daily')),
            ),
            const SizedBox(height: 16),

            // Toggles + streak
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _model.requiresAd,
                        onChanged: (v) => setState(
                            () => _model = _model.copyWith(requiresAd: v)),
                        activeColor: const Color(0xFF6366F1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      const Text('Requires Ad', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _streakCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Streak Required',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _model = _model.copyWith(
                        requiredStreak: int.tryParse(v),
                        clearStreak: v.isEmpty)),
                  ),
                ),
              ],
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
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 14),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reward limit saved.'),
            backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
