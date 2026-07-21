import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/neural_bloom_indicator.dart';
import 'package:synaptix/screens/multiplayer/multiplayer_palette.dart';
import 'package:synaptix/screens/multiplayer/widgets/connection_banner.dart';
import 'package:synaptix/screens/multiplayer/widgets/room_card.dart';
import '../../game/multiplayer/providers/multiplayer_providers.dart';
import '../../game/providers/feature_flag_providers.dart';

class MultiplayerHubScreen extends ConsumerStatefulWidget {
  const MultiplayerHubScreen({super.key});

  @override
  ConsumerState<MultiplayerHubScreen> createState() =>
      _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends ConsumerState<MultiplayerHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
    
    // Clear any pending notifications when the user is actively viewing the arena
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Logic for future notification clearing
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mpState = ref.watch(multiplayerControllerProvider);
    final roomsAsync = ref.watch(roomsListProvider);
    final canPop = context.canPop();

    return SynaptixScaffold(
      appBar: GlassAppBar(
        leading: IconButton(
          onPressed: () {
            if (canPop) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: const GlowText('Arena'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight + 20)),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConnectionBanner(state: mpState),
                          const SizedBox(height: 24),
                          _buildQuickActions(context),
                          const SizedBox(height: 32),
                          _buildRoomsSection(roomsAsync),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlowText(
          'Quick Actions',
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.flash_on_rounded,
                title: 'Quick Match',
                subtitle: 'Find opponents instantly',
                gradient: const LinearGradient(
                  colors: [
                    MultiplayerPalette.accent,
                    MultiplayerPalette.danger
                  ],
                ),
                onTap: () async {
                  final ok =
                      await ref.read(multiplayerServiceProvider).quickMatch();
                  if (!mounted) return;
                  if (ok) context.push('/multiplayer/find');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.meeting_room_rounded,
                title: 'Browse Rooms',
                subtitle: 'Join existing games',
                gradient: const LinearGradient(
                  colors: [
                    MultiplayerPalette.primary,
                    MultiplayerPalette.secondary
                  ],
                ),
                onTap: () => context.push('/multiplayer/find'),
              ),
            ),
          ],
        ),
        if (ref.watch(featureFlagsProvider).socialEnabled) ...[
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.groups_rounded,
            title: 'Party',
            subtitle: 'Play with friends',
            gradient: const LinearGradient(
              colors: [MultiplayerPalette.secondary, MultiplayerPalette.accent],
            ),
            onTap: () => context.push('/party'),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return AdaptiveGlassCard(
      glowColor: gradient.colors.first,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.colors.map((c) => c.withValues(alpha: 0.3)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsSection(AsyncValue<List<Map<String, dynamic>>> roomsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const GlowText(
              'Active Rooms',
              style: TextStyle(fontSize: 20),
            ),
            IconButton(
              onPressed: () => ref.refresh(roomsListProvider),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 16),
        roomsAsync.when(
          data: (rooms) => _buildRoomsList(rooms),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ],
    );
  }

  Widget _buildRoomsList(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return AdaptiveGlassCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MultiplayerPalette.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    size: 48,
                    color: MultiplayerPalette.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Rooms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Be the first to create a room or try Quick Match!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (i * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: RoomCard.fromJson(
                json: rooms[i],
                onTap: () {
                  final id = (rooms[i]['roomId'] ?? '').toString();
                  ref.read(roomControllerProvider.notifier).joinRoom(id);
                  context.push('/multiplayer/rooms');
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuralBloomIndicator(),
            SizedBox(height: 16),
            Text('Loading rooms...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return AdaptiveGlassCard(
      child: SizedBox(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading rooms', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('$error',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(roomsListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
