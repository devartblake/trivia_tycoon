import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/leaderboard/widgets/live_countdown_timer_widget.dart';
import 'package:trivia_tycoon/ui_components/mission/mission_panel.dart';
import 'package:trivia_tycoon/ui_components/seasonal/seasonal_events_widget.dart';
import '../../game/models/seasonal_competition_model.dart';
import '../../game/providers/riverpod_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  int playerXP = 1200; // Mocked value; replace with actual user XP
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutBack,
    ));
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _handleXPAdded(int xp) {
    setState(() => playerXP += xp);
  }

  void _handleTierTapped(int tierIndex) {
    // Handle tier tap - could show tier details, rewards, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tier ${tierIndex + 1} details'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _fadeAnimation != null && _slideAnimation != null
                ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: _slideAnimation!,
                child: Column(
                  children: [
                    _buildTierHeader(),
                    const SizedBox(height: 24),
                    MissionPanel(
                      playerXP: playerXP,
                      onXPAdded: _handleXPAdded,
                    ),
                    const SizedBox(height: 24),
                    const SeasonalEventsWidget(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            )
                : Column(
              children: [
                _buildTierHeader(),
                const SizedBox(height: 24),
                MissionPanel(
                  playerXP: playerXP,
                  onXPAdded: _handleXPAdded,
                ),
                const SizedBox(height: 24),
                const SeasonalEventsWidget(),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F23),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          splashRadius: 24,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F0F23),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierHeader() {
    return Column(
      children: [
        // Tier Progression Widget with Provider Integration
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer(
            builder: (context, ref, child) {
              final currentTierAsync = ref.watch(currentTierIdProvider);
              return currentTierAsync.when(
                data: (currentTier) => TierProgressionWidget(
                  currentTier: currentTier,
                  totalTiers: 10,
                  onTierTap: _handleTierTapped,
                ),
                loading: () => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFF7C3AED),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                error: (err, stack) => Container(
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      'Error loading tiers: $err',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Original tier info card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF5A4FCF),
                Color(0xFF4834D4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 32,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display current tier name from provider
                        Consumer(
                          builder: (context, ref, child) {
                            final currentTierAsync = ref.watch(currentTierProvider);
                            return currentTierAsync.when(
                              data: (tier) => Text(
                                tier?.name.toUpperCase() ?? "APPRENTICE I",
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              loading: () => const Text(
                                "LOADING...",
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              error: (err, stack) => const Text(
                                "APPRENTICE I",
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                "50",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                "Safe zone",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildEnhancedTimerSection()
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        context.go('/ranking');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "See ranking",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget buildEnhancedTimerSection() {
    return Consumer(
      builder: (context, ref, child) {
        final seasonEndAsync = ref.watch(seasonEndTimeProvider);

        return seasonEndAsync.when(
          data: (endTime) => LiveCountdownTimer(
            endTime: endTime,
            timeStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            labelStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            onTimeExpired: () {
              // Handle season end
              final seasonService = ref.read(seasonalCompetitionServiceProvider);
              seasonService.endSeason().then((result) {
                if (result.hasTiebreakers) {
                  // Show tiebreaker notification
                  _showTiebreakerDialog(context, result.tiebreakers);
                }
                // Refresh leaderboard
                ref.invalidate(seasonLeaderboardProvider);
              });
            },
          ),
          loading: () => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Loading season...",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "--:--",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          error: (err, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Season error",
                style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              ),
              const Text(
                "Error",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTiebreakerDialog(BuildContext context, List<List<SeasonPlayer>> tiebreakers) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tiebreaker Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Multiple players are tied for the final promotion spots.'),
            const SizedBox(height: 16),
            const Text('A tiebreaker quiz has been scheduled. You have 2 hours to participate or you will be automatically eliminated.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to tiebreaker quiz
            },
            child: const Text('Join Tiebreaker'),
          ),
        ],
      ),
    );
  }
}

// Tier Progression Widget (inline implementation)
class TierProgressionWidget extends StatefulWidget {
  final int currentTier;
  final int totalTiers;
  final Function(int)? onTierTap;

  const TierProgressionWidget({
    super.key,
    required this.currentTier,
    this.totalTiers = 10,
    this.onTierTap,
  });

  @override
  State<TierProgressionWidget> createState() => _TierProgressionWidgetState();
}

class _TierProgressionWidgetState extends State<TierProgressionWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _pulseAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.totalTiers,
          (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    // Remove pulse animations - no longer needed
    _pulseAnimations = [];
  }

  void _startAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _animationControllers[i].forward();
          // Remove pulse animation logic
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(widget.totalTiers, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTierItem(index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTierItem(int index) {
    final isCurrentTier = index == widget.currentTier;
    final isUnlocked = index <= widget.currentTier;

    return GestureDetector(
      onTap: () {
        if (isUnlocked && widget.onTierTap != null) {
          widget.onTierTap!(index);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: _buildTierIcon(index, isCurrentTier, isUnlocked),
          );
        },
      ),
    );
  }

  Widget _buildTierIcon(int index, bool isCurrentTier, bool isUnlocked) {
    // Only current tier gets larger size
    final size = isCurrentTier ? 70.0 : 50.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getTierGradient(index, isCurrentTier, isUnlocked),
        border: Border.all(
          color: isCurrentTier
              ? Colors.white
              : isUnlocked
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: isCurrentTier ? 3 : 2,
        ),
        boxShadow: isCurrentTier
            ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ]
            : isUnlocked
            ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _getTierIcon(index, isCurrentTier, isUnlocked),
            size: isCurrentTier ? 24 : 20, // Reduced icon sizes
            color: Colors.white,
          ),
          if (!isUnlocked)
            Icon(
              Icons.lock,
              size: 16, // Reduced lock icon size
              color: Colors.white.withOpacity(0.7),
            ),
          if (isCurrentTier)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18, // Reduced star badge size
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(
                  Icons.star,
                  size: 10, // Reduced star icon size
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  LinearGradient _getTierGradient(int index, bool isCurrentTier, bool isUnlocked) {
    if (isCurrentTier) {
      // Gold gradient only for current tier
      return const LinearGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFA500),
          Color(0xFFFF8C00),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isUnlocked) {
      // Purple gradient for other unlocked tiers
      return LinearGradient(
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.8),
          const Color(0xFF7C3AED).withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Gray gradient for locked tiers
      return LinearGradient(
        colors: [
          Colors.grey.withOpacity(0.3),
          Colors.grey.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  IconData _getTierIcon(int index, bool isCurrentTier, bool isUnlocked) {
    if (isCurrentTier) {
      return Icons.emoji_events;
    } else if (isUnlocked) {
      return _getTierIconByIndex(index);
    } else {
      return Icons.shield_outlined;
    }
  }

  IconData _getTierIconByIndex(int index) {
    final icons = [
      Icons.emoji_events,
      Icons.star_border,
      Icons.star,
      Icons.shield,
      Icons.diamond,
      Icons.workspace_premium,
      Icons.military_tech,
      Icons.emoji_events_outlined,
      Icons.workspace_premium_outlined,
      Icons.monetization_on_outlined,
    ];
    return icons[index % icons.length];
  }
}
