import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AdRemoveOptions extends StatefulWidget {
  const AdRemoveOptions({super.key});

  @override
  State<AdRemoveOptions> createState() => _AdRemoveOptionsState();
}

class _AdRemoveOptionsState extends State<AdRemoveOptions>
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

    // Initialize card animations
    _cardControllers = List.generate(
      3,
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

    // Start animations
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header section
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
                      child: const Icon(
                        Icons.block,
                        color: Colors.white,
                        size: 24,
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Best value option (365 days)
          AnimatedBuilder(
            animation: _cardAnimations[0],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[0].value,
                child: _buildAdRemoveOption(
                  '365 DAYS',
                  '\$5.99',
                  'assets/images/cta_banner.png',
                  true,
                  'Best Value - Save 70%',
                  const Color(0xFF10B981),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Row for 28 Days and 7 Days
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _cardAnimations[1],
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _cardAnimations[1].value,
                      child: _buildAdRemoveOption(
                        '28 DAYS',
                        '\$3.99',
                        'assets/images/cta_banner.png',
                        false,
                        'Popular Choice',
                        const Color(0xFF6366F1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedBuilder(
                  animation: _cardAnimations[2],
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _cardAnimations[2].value,
                      child: _buildAdRemoveOption(
                        '7 DAYS',
                        '\$1.99',
                        'assets/images/cta_banner.png',
                        false,
                        'Trial Period',
                        const Color(0xFF8B5CF6),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Benefits section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
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
                _buildBenefit(Icons.play_arrow, 'Uninterrupted gameplay'),
                _buildBenefit(Icons.speed, 'Faster loading times'),
                _buildBenefit(Icons.battery_charging_full, 'Less battery usage'),
                _buildBenefit(Icons.star, 'Premium experience'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdRemoveOption(
      String duration,
      String price,
      String imagePath,
      bool isBestValue,
      String badge,
      Color accentColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestValue ? const Color(0xFF10B981) : accentColor.withValues(alpha: 0.3),
          width: isBestValue ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isBestValue
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : accentColor.withValues(alpha: 0.1),
            blurRadius: isBestValue ? 15 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Badge
              if (isBestValue || badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBestValue ? const Color(0xFF10B981) : accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Content row
              Row(
                children: [
                  // Image/Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.block,
                            color: accentColor,
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Duration text
                  Expanded(
                    child: Text(
                      duration,
                      style: TextStyle(
                        fontSize: isBestValue ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Price button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePurchase(duration, price),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBestValue ? const Color(0xFF10B981) : accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SAVE 70%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
          Icon(
            icon,
            color: const Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(String duration, String price) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
            Text('Purchase $duration ad-free experience for $price?'),
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
                        fontWeight: FontWeight.w600,
                      ),
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
              _redirectToStoreOffers(duration);
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

  void _redirectToStoreOffers(String duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$duration ad-free is now handled from Special Offers so checkout goes through the backend.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    context.push('/offers');
  }
}
