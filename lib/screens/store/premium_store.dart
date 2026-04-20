import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/models/store/premium_store_model.dart';
import 'package:trivia_tycoon/game/state/premium_profile_state.dart';
import 'package:trivia_tycoon/screens/store/widgets/ad_remove_options.dart';
import 'package:trivia_tycoon/screens/store/widgets/reward_center.dart';
import 'package:trivia_tycoon/screens/store/widgets/sale_info.dart';
import 'package:trivia_tycoon/screens/store/widgets/try_now_widget.dart';
import '../../game/providers/riverpod_providers.dart';

class StoreSecondaryScreen extends ConsumerStatefulWidget {
  const StoreSecondaryScreen({super.key});

  @override
  ConsumerState<StoreSecondaryScreen> createState() =>
      _StoreSecondaryScreenState();
}

class _StoreSecondaryScreenState extends ConsumerState<StoreSecondaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(premiumStoreProvider);
    final rewardsAsync = ref.watch(playerRewardsProvider);

    return storeAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: _buildAppBar(),
        body: _buildBody(
          PremiumStoreData.fallback,
          rewardData: PremiumStoreData.fallback.rewardCenter,
          enableRewardClaims: false,
        ),
      ),
      data: (data) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildBody(
            data,
            rewardData: rewardsAsync.maybeWhen(
              data: (rewardData) => rewardData,
              orElse: () => data.rewardCenter,
            ),
            enableRewardClaims: rewardsAsync.hasValue,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    PremiumStoreData data, {
    required RewardCenterData rewardData,
    required bool enableRewardClaims,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildPremiumBanner()),

        // Remove Ads
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: _buildSectionCard(
                    title: 'Remove Ads',
                    subtitle: 'Enjoy uninterrupted gameplay',
                    icon: Icons.block,
                    child: AdRemoveOptions(config: data.adFree),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3D Avatar
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSectionCard(
                    title: '3D Avatar',
                    subtitle: 'Customize your unique character',
                    icon: Icons.face_retouching_natural,
                    child: TryNowWidget(
                      modelPath: 'assets/models/cartoon_character.obj',
                      title: 'Get your own 3D Avatar',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Special Offers (only when saleInfo present)
        if (data.saleInfo != null)
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildSectionCard(
                    title: 'Special Offers',
                    subtitle: 'Limited time deals just for you',
                    icon: Icons.local_offer,
                    child: SaleInfo(
                      data: data.saleInfo!,
                      purchasePlan: data.adFree.defaultPurchasePlan,
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ),

        // Reward Center
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1100),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSectionCard(
                    title: 'Reward Center',
                    subtitle: 'Claim your daily rewards',
                    icon: Icons.card_giftcard,
                    child: RewardCenter(
                      data: rewardData,
                      enableClaims: enableRewardClaims,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final coins = ref.watch(coinBalanceProvider);
    final premiumStatus = ref.watch(premiumAccessStatusProvider).maybeWhen(
          data: (status) => status,
          orElse: () => PremiumStatus(isPremium: false, discountPercent: 0),
        );
    final isPremium = premiumStatus.isPremium;

    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/avatars/default-avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person,
                    color: Color(0xFF6366F1), size: 24),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildCurrencyItem(
                Icons.workspace_premium,
                isPremium ? '1' : '0',
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 16),
              _buildCurrencyItem(
                Icons.monetization_on,
                coins.toString(),
                const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
      toolbarHeight: 70,
    );
  }

  Widget _buildCurrencyItem(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Store',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Exclusive content & features',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Unlock premium features, exclusive content, and special offers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
            color: const Color(0xFF64748B).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF94A3B8), size: 16),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
