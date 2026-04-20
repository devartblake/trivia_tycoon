import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/ui_components/power_ups/power_up_inventory_widget.dart';
import '../../core/services/api_service.dart';
import '../../core/services/store/store_return_url_builder.dart';
import '../../core/services/settings/app_settings.dart';
import '../../game/models/store_item_model.dart';
import 'widgets/currency_display_bar.dart';
import 'widgets/store_category_tab.dart';
import 'widgets/store_item_card.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  late AnimationController _refreshController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
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
    _refreshController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    HapticFeedback.lightImpact();
    _refreshController.forward().then((_) {
      _refreshController.reset();
      setState(() {
        _selectedCategory = 'All';
      });
      ref.invalidate(storeItemsProvider);
      ref.invalidate(storeSystemStatusProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(storeItemsProvider);
    final systemStatus = ref.watch(storeSystemStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: asyncItems.when(
          data: (items) =>
              _buildStoreContent(items, systemStatus.valueOrNull ?? const {}),
          loading: () => _buildLoadingState(),
          error: (err, _) => _buildErrorState(err),
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
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Game Store',
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
          child: AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshController.value * 2 * 3.14159,
                child: IconButton(
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
                      Icons.refresh,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  onPressed: _handleRefresh,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreContent(
      List<StoreItemModel> items, Map<String, dynamic> status) {
    final categories = <String>[
      'All',
      ...{for (var item in items) item.category}
    ];
    final storeItems = items
        .where((item) =>
            _selectedCategory == 'All' || item.category == _selectedCategory)
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Currency Display
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: const CurrencyDisplayBar(),
                  ),
                ),
              );
            },
          ),
        ),

        // Power-ups Inventory
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: const PowerUpInventoryWidget(),
                  ),
                ),
              );
            },
          ),
        ),

        if (status.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildSystemStatusBanner(status),
            ),
          ),

        // Category Tabs
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: StoreCategoryTab(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = value);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Store Items Header
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategory == 'All'
                                  ? 'All Items'
                                  : _selectedCategory,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${storeItems.length} items available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: 16,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Special Deals',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Store Items Grid
        if (storeItems.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = storeItems[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1000 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value,
                          child: StoreItemCard(
                            item: item,
                            name: item.name,
                            description: item.description,
                            iconPath: item.iconPath,
                            price:
                                item.displayPriceLabel ?? item.price.toString(),
                            onBuy: () => _handlePurchase(item),
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: storeItems.length,
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading store items...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting the best deals for you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load store items: $error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(storeItemsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF6366F1),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No items in $_selectedCategory',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category or check back later for new items.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() => _selectedCategory = 'All');
            },
            child: const Text(
              'View All Items',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusBanner(Map<String, dynamic> status) {
    final storeEnabled = status['storeEnabled'] != false;
    final paymentsEnabled = status['paymentsEnabled'] != false;
    final stripeEnabled = status['stripeEnabled'] == true;
    final payPalEnabled = status['payPalEnabled'] == true;
    final message =
        status['message']?.toString() ?? 'Store availability is being loaded.';

    final accent = !storeEnabled || !paymentsEnabled
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0F766E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                !storeEnabled || !paymentsEnabled
                    ? Icons.info_outline
                    : Icons.verified_outlined,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                label: storeEnabled ? 'Store Live' : 'Store Offline',
                active: storeEnabled,
              ),
              _buildStatusChip(
                label: stripeEnabled ? 'Stripe Ready' : 'Stripe Off',
                active: stripeEnabled,
              ),
              _buildStatusChip(
                label: payPalEnabled ? 'PayPal Ready' : 'PayPal Off',
                active: payPalEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({required String label, required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF166534) : const Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _handlePurchase(StoreItemModel item) async {
    HapticFeedback.mediumImpact();

    if (item.requiresExternalCheckout || item.currency.toLowerCase() == 'usd') {
      await _handleExternalPurchase(item);
      return;
    }

    final coins = ref.read(coinBalanceProvider);
    if (coins >= item.price) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        ref.read(coinNotifierProvider).deduct(item.price);
        await AppSettings.addPurchasedItem(item.id);

        if (!mounted) return;
        Navigator.of(context).pop();

        _showSnack(
          "Successfully purchased ${item.name}!",
          const Color(0xFF10B981),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();

        _showSnack(
          'Purchase failed. Please try again.',
          const Color(0xFFEF4444),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child:
                    Text("Not enough coins! Visit the coin store to get more."),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Get Coins',
            textColor: Colors.white,
            onPressed: () {
              context.push('/store-hub');
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleExternalPurchase(StoreItemModel item) async {
    if (item.sku == null || item.sku!.isEmpty) {
      _showSnack(
        'This item is not wired to a backend SKU yet.',
        const Color(0xFFEF4444),
      );
      return;
    }

    final status = await ref.read(storeSystemStatusProvider.future);
    if (status['storeEnabled'] == false || status['paymentsEnabled'] == false) {
      _showSnack(
        status['message']?.toString() ?? 'Payments are currently unavailable.',
        const Color(0xFFEF4444),
      );
      return;
    }

    final useStripe = await _choosePaymentProvider(
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
          ? await storeService.createStripeCheckoutSession(
              playerId: playerId,
              sku: item.sku!,
              successUrl: StoreReturnUrlBuilder.checkoutSuccess(
                provider: 'stripe',
                sku: item.sku!,
                quantity: 1,
              ),
              cancelUrl: StoreReturnUrlBuilder.checkoutCancel(
                provider: 'stripe',
                sku: item.sku!,
              ),
            )
          : await storeService.createPayPalOrder(
              playerId: playerId,
              sku: item.sku!,
              returnUrl: StoreReturnUrlBuilder.checkoutSuccess(
                provider: 'paypal',
                sku: item.sku!,
                quantity: 1,
              ),
              cancelUrl: StoreReturnUrlBuilder.checkoutCancel(
                provider: 'paypal',
                sku: item.sku!,
              ),
            );

      if (!mounted) return;
      Navigator.of(context).pop();

      final redirectUrl =
          (useStripe ? response['checkoutUrl'] : response['approveUrl'])
              ?.toString();
      if (redirectUrl == null || redirectUrl.isEmpty) {
        _showSnack(
          'The payment provider did not return a redirect URL.',
          const Color(0xFFEF4444),
        );
        return;
      }

      final uri = Uri.tryParse(redirectUrl);
      if (uri == null || !await canLaunchUrl(uri)) {
        _showSnack(
          'Unable to open the checkout page on this device.',
          const Color(0xFFEF4444),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showSnack(
        useStripe
            ? 'Stripe checkout opened. Inventory will update after backend confirmation.'
            : 'PayPal approval opened. One-time capture still needs a return flow after approval.',
        const Color(0xFF0F766E),
      );
    } on ApiRequestException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showSnack(e.message, const Color(0xFFEF4444));
      ref.invalidate(storeSystemStatusProvider);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showSnack(
        'Checkout failed. Please try again.',
        const Color(0xFFEF4444),
      );
    }
  }

  Future<bool?> _choosePaymentProvider({
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
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose payment method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stripe is the smoother one-time purchase path today. PayPal order creation is wired too, but capture still needs a return handler.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _buildProviderTile(
                  label: 'Stripe',
                  subtitle: 'Hosted checkout with webhook-based completion',
                  icon: Icons.credit_card,
                  color: const Color(0xFF4F46E5),
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 12),
                _buildProviderTile(
                  label: 'PayPal',
                  subtitle:
                      'Approval flow available; capture return step still pending',
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviderTile({
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
                      height: 1.35,
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
