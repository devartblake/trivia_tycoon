import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editable panel for premium visibility and bonus rules for a catalog item.
class PremiumGatingPanel extends StatefulWidget {
  final PremiumGatingConfig initial;
  final Future<void> Function(PremiumGatingConfig) onSave;

  const PremiumGatingPanel({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<PremiumGatingPanel> createState() => _PremiumGatingPanelState();
}

class _PremiumGatingPanelState extends State<PremiumGatingPanel> {
  late PremiumGatingConfig _model;
  final _multiplierCtrl = TextEditingController();
  final _ctaLabelCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = widget.initial;
    _multiplierCtrl.text = _model.premiumBonusStockMultiplier?.toString() ?? '';
    _ctaLabelCtrl.text = _model.upgradeCtaLabel ?? '';
  }

  @override
  void dispose() {
    _multiplierCtrl.dispose();
    _ctaLabelCtrl.dispose();
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Premium Gating',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Toggles
            _buildToggle(
              label: 'Requires Premium',
              subtitle: 'Only premium subscribers can purchase',
              value: _model.requiresPremium,
              onChanged: (v) =>
                  setState(() => _model = _model.copyWith(requiresPremium: v)),
            ),
            _buildToggle(
              label: 'Included in Subscription',
              subtitle: 'Premium players get this for free',
              value: _model.includedWithSubscription,
              onChanged: (v) => setState(
                  () => _model = _model.copyWith(includedWithSubscription: v)),
            ),
            _buildToggle(
              label: 'Visible to Non-Premium',
              subtitle: 'Show locked item to non-subscribers',
              value: _model.visibleToNonPremium,
              onChanged: (v) => setState(
                  () => _model = _model.copyWith(visibleToNonPremium: v)),
            ),
            const SizedBox(height: 12),

            // Multiplier
            TextFormField(
              controller: _multiplierCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              decoration: const InputDecoration(
                labelText: 'Premium Stock Multiplier',
                hintText: 'e.g. 2 for 2x daily claims',
                helperText: 'Leave empty for no multiplier',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() => _model = _model.copyWith(
                  premiumBonusStockMultiplier: double.tryParse(v),
                  clearMultiplier: v.isEmpty)),
            ),
            const SizedBox(height: 12),

            // CTA label
            TextFormField(
              controller: _ctaLabelCtrl,
              decoration: const InputDecoration(
                labelText: 'Upgrade CTA Label',
                hintText: 'e.g. "Upgrade to Premium"',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() => _model = _model.copyWith(
                  upgradeCtaLabel: v.isEmpty ? null : v)),
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
                  backgroundColor: const Color(0xFF8B5CF6),
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

  Widget _buildToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF8B5CF6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
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
            content: Text('Premium gating saved.'),
            backgroundColor: Color(0xFF8B5CF6)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Config model for a single item's premium gating rules.
class PremiumGatingConfig {
  final String sku;
  final bool requiresPremium;
  final double? premiumBonusStockMultiplier;
  final bool includedWithSubscription;
  final bool visibleToNonPremium;
  final String? upgradeCtaLabel;

  const PremiumGatingConfig({
    required this.sku,
    this.requiresPremium = false,
    this.premiumBonusStockMultiplier,
    this.includedWithSubscription = false,
    this.visibleToNonPremium = true,
    this.upgradeCtaLabel,
  });

  PremiumGatingConfig copyWith({
    String? sku,
    bool? requiresPremium,
    double? premiumBonusStockMultiplier,
    bool? includedWithSubscription,
    bool? visibleToNonPremium,
    String? upgradeCtaLabel,
    bool clearMultiplier = false,
  }) {
    return PremiumGatingConfig(
      sku: sku ?? this.sku,
      requiresPremium: requiresPremium ?? this.requiresPremium,
      premiumBonusStockMultiplier: clearMultiplier
          ? null
          : (premiumBonusStockMultiplier ?? this.premiumBonusStockMultiplier),
      includedWithSubscription:
          includedWithSubscription ?? this.includedWithSubscription,
      visibleToNonPremium: visibleToNonPremium ?? this.visibleToNonPremium,
      upgradeCtaLabel: upgradeCtaLabel ?? this.upgradeCtaLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'requiresPremium': requiresPremium,
        if (premiumBonusStockMultiplier != null)
          'premiumBonusStockMultiplier': premiumBonusStockMultiplier,
        'includedWithSubscription': includedWithSubscription,
        'visibleToNonPremium': visibleToNonPremium,
        if (upgradeCtaLabel != null) 'upgradeCtaLabel': upgradeCtaLabel,
      };
}
