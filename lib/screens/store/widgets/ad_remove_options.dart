import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/store/premium_store_model.dart';
import 'premium_checkout_launcher.dart';

class AdRemoveOptions extends ConsumerStatefulWidget {
  final AdFreeConfig config;

  const AdRemoveOptions({super.key, required this.config});

  @override
  ConsumerState<AdRemoveOptions> createState() => _AdRemoveOptionsState();
}

class _AdRemoveOptionsState extends ConsumerState<AdRemoveOptions>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _cardControllers = List.generate(
      widget.config.plans.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 200)),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _fadeController.forward();
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.config.plans;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.block,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'REMOVE ADS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Play without interruptions!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Best-value plan (first plan, full-width)
          if (plans.isNotEmpty && _cardAnimations.isNotEmpty)
            AnimatedBuilder(
              animation: _cardAnimations[0],
              builder: (context, child) => Transform.scale(
                scale: _cardAnimations[0].value,
                child: _buildAdRemoveOption(plans[0]),
              ),
            ),

          const SizedBox(height: 16),

          // Remaining plans in a row
          if (plans.length > 1)
            Row(
              children: [
                for (int i = 1; i < plans.length; i++) ...[
                  if (i > 1) const SizedBox(width: 16),
                  Expanded(
                    child: i < _cardAnimations.length
                        ? AnimatedBuilder(
                            animation: _cardAnimations[i],
                            builder: (context, child) => Transform.scale(
                              scale: _cardAnimations[i].value,
                              child: _buildAdRemoveOption(plans[i]),
                            ),
                          )
                        : _buildAdRemoveOption(plans[i]),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 20),

          // Benefits
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'What you get with ad-free:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.config.benefits.map(
                  (b) => _buildBenefit(Icons.check_circle_outline, b),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdRemoveOption(AdRemovePlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isBestValue
              ? const Color(0xFF10B981)
              : plan.accentColor.withValues(alpha: 0.3),
          width: plan.isBestValue ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.isBestValue
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : plan.accentColor.withValues(alpha: 0.1),
            blurRadius: plan.isBestValue ? 15 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  plan.isBestValue ? const Color(0xFF10B981) : plan.accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              plan.badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: plan.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.block, color: plan.accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  plan.displayTitle,
                  style: TextStyle(
                    fontSize: plan.isBestValue ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          if (plan.displaySubtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.displaySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handlePurchase(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isBestValue
                    ? const Color(0xFF10B981)
                    : plan.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                plan.price,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(AdRemovePlan plan) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Remove Ads'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Purchase ${plan.displayTitle} for ${plan.price}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enjoy uninterrupted gameplay!',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startPremiumCheckout(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPremiumCheckout(AdRemovePlan plan) async {
    final tier = plan.tier;
    final billingPeriod = plan.billingPeriod;
    if (tier == null || billingPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This premium plan is missing checkout mapping for ${plan.id}.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    await PremiumCheckoutLauncher.launchSubscriptionCheckout(
      context: context,
      ref: ref,
      tier: tier,
      billingPeriod: billingPeriod,
      purchaseLabel: plan.displayTitle,
    );
  }
}
