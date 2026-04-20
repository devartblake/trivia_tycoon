import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/store/premium_store_model.dart';

class SaleInfo extends StatefulWidget {
  final SaleInfoData data;

  const SaleInfo({super.key, required this.data});

  @override
  State<SaleInfo> createState() => _SaleInfoState();
}

class _SaleInfoState extends State<SaleInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sale badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        data.badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Pricing row
                Row(
                  children: [
                    // Image placeholder
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/cta_banner.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Text(
                                data.discount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Before ${data.originalPrice}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCD34D),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              data.salePrice,
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Benefits
                if (data.benefits.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'What you get:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: data.benefits
                              .map((b) => _buildBenefitItem(b))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _handlePurchase();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          data.buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // "LIMITED TIME" badge
          Positioned(
            top: -8,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'LIMITED TIME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(SaleBenefitItem item) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withValues(alpha: 0.4)),
          ),
          child: Icon(item.icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handlePurchase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Get ${widget.data.discount} off for just ${widget.data.salePrice}?',
            ),
            const SizedBox(height: 16),
            const Text(
              'This offer expires soon!',
              style: TextStyle(
                  color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
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
}
