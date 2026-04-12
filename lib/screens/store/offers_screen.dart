import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/store/store_return_url_builder.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _selectedTab = 'Limited Time';

  final List<String> _tabs = ['Limited Time', 'Daily Deals', 'Premium', 'Bundles'];

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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Featured Banner
            SliverToBoxAdapter(
              child: _buildFeaturedBanner(),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),

            // Offers Content
            SliverToBoxAdapter(
              child: _buildOffersContent(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Special Offers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () {
              // Handle notifications
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBanner() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'FLASH SALE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '80% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Premium Membership',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Limited time offer ends soon!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '23:45:12',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Left',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Handle claim offer
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Claim Offer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSelected = tab == _selectedTab;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = tab);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                        isSelected ? const Color(0xFF6366F1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                                : const Color(0xFF64748B).withValues(alpha: 0.1),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF64748B).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffersContent() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOffersList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffersList() {
    final offers = _getOffersForTab(_selectedTab);

    return Column(
      children: offers.asMap().entries.map((entry) {
        final index = entry.key;
        final offer = entry.value;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 1100 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildOfferCard(offer),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final bool hasDiscount = offer['discount'] != null;
    final bool isPopular = offer['isPopular'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPopular
            ? Border.all(color: const Color(0xFF6366F1), width: 2)
            : Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                : const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: offer['iconGradient'] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  offer['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (offer['originalPrice'] != null)
                            Text(
                              '\$${offer['originalPrice']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${offer['price']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${offer['discount']}% OFF',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '\$${offer['price']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _handleOfferClaim(offer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF64748B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                offer['buttonText'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getOffersForTab(String tab) {
    switch (tab) {
      case 'Limited Time':
        return [
          {
            'title': 'Premium Upgrade',
            'description':
            'Unlock unlimited lives, double XP, and exclusive content',
            'price': '4.99',
            'originalPrice': '24.99',
            'discount': 80,
            'icon': Icons.star,
            'iconGradient': [Color(0xFFEF4444), Color(0xFFDC2626)],
            'buttonText': 'Upgrade Now',
            'isPopular': true,
          },
          {
            'title': 'Mega Coin Pack',
            'description': '50,000 coins + 1,000 bonus coins',
            'price': '9.99',
            'originalPrice': '19.99',
            'discount': 50,
            'icon': Icons.monetization_on,
            'iconGradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
            'buttonText': 'Buy Coins',
          },
        ];
      case 'Daily Deals':
        return [
          {
            'title': 'Energy Refill Bundle',
            'description': '10 full energy refills for today only',
            'price': '2.99',
            'icon': Icons.flash_on,
            'iconGradient': [Color(0xFF10B981), Color(0xFF059669)],
            'buttonText': 'Get Energy',
          },
          {
            'title': 'Double XP Boost',
            'description': '24-hour double XP multiplier',
            'price': '1.99',
            'icon': Icons.trending_up,
            'iconGradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            'buttonText': 'Activate Boost',
          },
        ];
      case 'Premium':
        return [
          {
            'title': 'Monthly Premium',
            'description': 'All premium features for 30 days',
            'price': '9.99',
            'icon': Icons.workspace_premium,
            'iconGradient': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            'buttonText': 'Subscribe',
            'isPopular': true,
            'tier': 'premium',
            'billingPeriod': 'monthly',
          },
          {
            'title': 'Elite Season Pass',
            'description': 'Best value seasonal plan with the highest tier perks',
            'price': '39.99',
            'originalPrice': '119.88',
            'discount': 67,
            'icon': Icons.diamond,
            'iconGradient': [Color(0xFF06B6D4), Color(0xFF0891B2)],
            'buttonText': 'Best Deal',
            'tier': 'elite',
            'billingPeriod': 'seasonal',
          },
        ];
      case 'Bundles':
        return [
          {
            'title': 'Starter Pack',
            'description': '10,000 coins + 5 lives + 3 power-ups',
            'price': '4.99',
            'icon': Icons.card_giftcard,
            'iconGradient': [Color(0xFFEC4899), Color(0xFFDB2777)],
            'buttonText': 'Get Bundle',
          },
          {
            'title': 'Champion Bundle',
            'description': 'Premium + 50k coins + exclusive avatar',
            'price': '19.99',
            'originalPrice': '34.97',
            'discount': 43,
            'icon': Icons.emoji_events,
            'iconGradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
            'buttonText': 'Become Champion',
            'isPopular': true,
          },
        ];
      default:
        return [];
    }
  }

  void _handleOfferClaim(Map<String, dynamic> offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to purchase "${offer['title']}"?'),
            const SizedBox(height: 16),
            Text(
              '\$${offer['price']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
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
              _processPurchase(offer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _processPurchase(Map<String, dynamic> offer) {
    if (offer.containsKey('tier') && offer.containsKey('billingPeriod')) {
      _startSubscriptionCheckout(offer);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate purchase process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Successfully purchased ${offer['title']}!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    });
  }

  Future<void> _startSubscriptionCheckout(Map<String, dynamic> offer) async {
    final status = await ref.read(storeSystemStatusProvider.future);
    if (status['storeEnabled'] == false || status['paymentsEnabled'] == false) {
      _showSnack(
        status['message']?.toString() ?? 'Subscriptions are currently unavailable.',
        const Color(0xFFEF4444),
      );
      return;
    }

    final useStripe = await _chooseProvider(
      stripeEnabled: status['stripeEnabled'] == true,
      payPalEnabled: status['payPalEnabled'] == true,
    );
    if (useStripe == null) return;

    final playerId = await ref.read(currentUserIdProvider.future);
    final storeService = ref.read(storeServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = useStripe
          ? await storeService.createStripeSubscriptionCheckout(
              playerId: playerId,
              tier: offer['tier'] as String,
              billingPeriod: offer['billingPeriod'] as String,
              successUrl: StoreReturnUrlBuilder.subscriptionSuccess(
                provider: 'stripe',
                tier: offer['tier'] as String,
                billingPeriod: offer['billingPeriod'] as String,
              ),
              cancelUrl: StoreReturnUrlBuilder.subscriptionCancel(
                provider: 'stripe',
                tier: offer['tier'] as String,
                billingPeriod: offer['billingPeriod'] as String,
              ),
            )
          : await storeService.createPayPalSubscription(
              playerId: playerId,
              tier: offer['tier'] as String,
              billingPeriod: offer['billingPeriod'] as String,
              returnUrl: StoreReturnUrlBuilder.subscriptionSuccess(
                provider: 'paypal',
                tier: offer['tier'] as String,
                billingPeriod: offer['billingPeriod'] as String,
              ),
              cancelUrl: StoreReturnUrlBuilder.subscriptionCancel(
                provider: 'paypal',
                tier: offer['tier'] as String,
                billingPeriod: offer['billingPeriod'] as String,
              ),
            );

      if (!mounted) return;
      Navigator.of(context).pop();

      final redirectUrl =
          (useStripe ? response['checkoutUrl'] : response['approveUrl'])
              ?.toString();
      if (redirectUrl == null || redirectUrl.isEmpty) {
        _showSnack(
          'The subscription provider did not return a redirect URL.',
          const Color(0xFFEF4444),
        );
        return;
      }

      final uri = Uri.tryParse(redirectUrl);
      if (uri == null || !await canLaunchUrl(uri)) {
        _showSnack(
          'Unable to open the subscription page on this device.',
          const Color(0xFFEF4444),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showSnack(
        useStripe
            ? 'Subscription checkout opened. We will trust backend status after you return.'
            : 'PayPal approval opened. Subscription status will update after webhook confirmation.',
        const Color(0xFF10B981),
      );
      ref.invalidate(storeSystemStatusProvider);
      ref.invalidate(storeSubscriptionStatusProvider(playerId));
    } on ApiRequestException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showSnack(e.message, const Color(0xFFEF4444));
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showSnack(
        'Subscription checkout failed. Please try again.',
        const Color(0xFFEF4444),
      );
    }
  }

  Future<bool?> _chooseProvider({
    required bool stripeEnabled,
    required bool payPalEnabled,
  }) async {
    if (stripeEnabled && !payPalEnabled) return true;
    if (!stripeEnabled && payPalEnabled) return false;
    if (!stripeEnabled && !payPalEnabled) {
      _showSnack(
        'No payment providers are currently available.',
        const Color(0xFFEF4444),
      );
      return null;
    }

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose subscription provider',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _providerTile(
                label: 'Stripe',
                subtitle: 'Hosted checkout and billing portal support',
                icon: Icons.credit_card,
                color: const Color(0xFF4F46E5),
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 12),
              _providerTile(
                label: 'PayPal',
                subtitle: 'Approval flow with webhook-driven status updates',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF0EA5E9),
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
