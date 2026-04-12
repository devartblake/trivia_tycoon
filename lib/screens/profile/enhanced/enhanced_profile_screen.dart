import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/presence/rich_presence_service.dart';
import '../../../game/models/user_presence_models.dart';
import '../../../game/providers/multi_profile_providers.dart';
import '../../../game/providers/profile_providers.dart';
import '../../../ui_components/depth_card_3d/core/depth_card_3d.dart';
import '../../../ui_components/depth_card_3d/models/depth_card_config.dart';
import '../../../ui_components/depth_card_3d/models/depth_card_slots.dart';
import '../../../ui_components/depth_card_3d/models/depth_card_theme.dart';
import '../../../ui_components/presence/rich_presence_indicator.dart';
import 'sections/profile_header_section.dart';
import 'sections/profile_stats_section.dart';
import 'sections/arcade_summary_section.dart';
import 'sections/missions_preview_section.dart';
import 'sections/daily_bonus_section.dart';
import 'sections/profile_actions_section.dart';
import 'sheets/edit_profile_bottom_sheet.dart';
import 'widgets/game_stats_widget.dart';
import 'widgets/profile_header.dart';
import 'mutual_friends_screen.dart';
import '../../../arcade/leaderboards/local_arcade_leaderboard_screen.dart';
import '../../../arcade/missions/arcade_missions_screen.dart';
import '../../../arcade/ui/screens/daily_bonus_screen.dart';

enum EnhancedProfileAction {
  message,
  challenge,
  block,
}

/// Enhanced Profile Screen with arcade integration, missions, and daily bonus
///
/// Features:
/// - Component extraction for maintainability
/// - Arcade best runs and local leaderboard preview
/// - Mission progress (daily/weekly/season)
/// - Daily bonus status and streak
/// - Title system
/// - Modern Material 3 design with glassmorphism
class EnhancedProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String currentUserId;
  final bool isOwnProfile;

  const EnhancedProfileScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    this.isOwnProfile = false,
  });

  @override
  ConsumerState<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  final RichPresenceService _presenceService = RichPresenceService();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Mock user data - Replace with actual data providers
  final Map<String, dynamic> _userData = {
    'displayName': 'Alex Johnson',
    'username': '@alexj',
    'title': 'Pattern Sprinter', // Title system
    'bio': 'Trivia enthusiast | Quiz champion | Always up for a challenge 🎯',
    'joinDate': DateTime(2023, 1, 15),
    'friendCount': 127,
    'mutualFriends': 12,
    'level': 42,
    'currentXP': 3420,
    'maxXP': 5000,
    'totalPoints': 15420,
    'achievements': 23,
    'rank': 17,
    'tier': 4,
    'favoriteSubject': 'Science',
  };

  // Arcade data
  final Map<String, dynamic> _arcadeData = {
    'quickMathBest': 1850,
    'quickMathRank': 3,
    'patternSprintBest': 2340,
    'patternSprintRank': 7,
    'lastRun': {
      'game': 'Quick Math Rush',
      'score': 1650,
      'time': '2 hours ago',
    },
  };

  // Missions data
  final Map<String, dynamic> _missionsData = {
    'dailyProgress': 3,
    'dailyTotal': 5,
    'weeklyProgress': 8,
    'weeklyTotal': 15,
    'seasonProgress': 45,
    'seasonTotal': 100,
  };

  // Daily bonus data
  final Map<String, dynamic> _dailyBonusData = {
    'currentStreak': 12,
    'longestStreak': 45,
    'nextReward': 'Premium Avatar Pack',
    'canClaim': true,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _loadBackendProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendProfileData() async {
    final backendService = ref.read(backendProfileSocialServiceProvider);

    try {
      final summary = await backendService.getCareerSummary(widget.userId);
      if (!mounted) return;

      setState(() {
        _mergeCareerSummary(summary);
      });
    } catch (_) {
      // Keep the local fallback values when backend summary is unavailable.
    }

    if (!widget.isOwnProfile) {
      return;
    }

    try {
      final loadout = await backendService.getLoadout();
      if (!mounted) return;

      setState(() {
        _mergeLoadout(loadout);
      });
    } catch (_) {
      // Local profile data stays authoritative until backend preferences load.
    }
  }

  void _mergeCareerSummary(Map<String, dynamic> summary) {
    final stats = _asMap(summary['stats']);
    final progress = _asMap(summary['progress']);
    final achievements = _asMap(summary['achievements']);

    _userData.addAll({
      if (_readInt(summary, ['level'], fallbackMap: progress) != null)
        'level': _readInt(summary, ['level'], fallbackMap: progress),
      if (_readInt(summary, ['totalPoints', 'points'], fallbackMap: stats) != null)
        'totalPoints':
            _readInt(summary, ['totalPoints', 'points'], fallbackMap: stats),
      if (_readInt(summary, ['friendCount', 'friends'], fallbackMap: stats) != null)
        'friendCount':
            _readInt(summary, ['friendCount', 'friends'], fallbackMap: stats),
      if (_readInt(summary, ['rank'], fallbackMap: stats) != null)
        'rank': _readInt(summary, ['rank'], fallbackMap: stats),
      if (_readInt(summary, ['achievementCount'], fallbackMap: achievements) != null)
        'achievements':
            _readInt(summary, ['achievementCount'], fallbackMap: achievements),
    });
  }

  void _mergeLoadout(Map<String, dynamic> loadout) {
    final payload = _asMap(loadout['loadout']).isNotEmpty
        ? _asMap(loadout['loadout'])
        : loadout;

    _userData.addAll({
      if (_readString(payload, const ['displayName', 'name']) != null)
        'displayName': _readString(payload, const ['displayName', 'name']),
      if (_readString(payload, const ['username', 'handle']) != null)
        'username':
            '@${_normalizeHandle(_readString(payload, const ['username', 'handle'])!)}',
      if (_readString(payload, const ['bio']) != null)
        'bio': _readString(payload, const ['bio']),
      if (_readString(payload, const ['favoriteSubject']) != null)
        'favoriteSubject': _readString(payload, const ['favoriteSubject']),
    });
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, dynamic>{};
  }

  int? _readInt(
    Map<String, dynamic> source,
    List<String> keys, {
    Map<String, dynamic>? fallbackMap,
  }) {
    for (final key in keys) {
      final value = source[key] ?? fallbackMap?[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String? _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _normalizeHandle(String value) {
    return value.startsWith('@') ? value.substring(1) : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildModernAppBar(context, innerBoxIsScrolled),
          ],
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Profile Header with Title
              SliverToBoxAdapter(
                child: ProfileHeaderSection(
                  userData: _userData,
                  isOwnProfile: widget.isOwnProfile,
                  onEditProfile: _navigateToEditProfile,
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Rich Presence Card
              SliverToBoxAdapter(child: _buildPresenceCard()),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Stats Cards
              SliverToBoxAdapter(
                child: ProfileStatsSection(
                  userData: _userData,
                  onFriendsTap: _showMutualFriends,
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // XP Progress Bar
              SliverToBoxAdapter(child: _buildXPProgressCard()),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Quick Actions (Message/Challenge)
              if (!widget.isOwnProfile)
                SliverToBoxAdapter(
                  child: ProfileActionsSection(
                    onMessage: () => _handleMenuAction('message'),
                    onChallenge: () => _handleMenuAction('challenge'),
                  ),
                ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Arcade Summary
              SliverToBoxAdapter(
                child: ArcadeSummarySection(
                  arcadeData: _arcadeData,
                  onViewAllScores: _navigateToArcadeScores,
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Missions Preview
              SliverToBoxAdapter(
                child: MissionsPreviewSection(
                  missionsData: _missionsData,
                  onViewMissions: _navigateToMissions,
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Daily Bonus Status
              if (widget.isOwnProfile)
                SliverToBoxAdapter(
                  child: DailyBonusSection(
                    bonusData: _dailyBonusData,
                    onClaimBonus: _claimDailyBonus,
                  ),
                ),

              SliverToBoxAdapter(child: const SizedBox(height: 20)),

              // Tabs
              SliverToBoxAdapter(child: _buildTabBar()),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(),
                    _buildActivityTab(),
                    _buildAchievementsTab(),
                    _buildCollectionTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // DepthCard3D Background
            Center (
              child: DepthCard3D(
                config: DepthCardConfig(
                  width: double.infinity,
                  height: 400,
                  text: '', // Required parameter - empty since we're using custom overlay
                  modelAssetPath: 'assets/models/flutter_dash.obj', // Your 3D model path
                  backgroundImage: const AssetImage('assets/images/backgrounds/bg7.jpg'), // Optional background
                  backgroundOpacity: 0.3,
                  backgroundBlur: 2.0,
                  backgroundFit: BoxFit.cover,
                  theme: const DepthCardTheme(
                    name: 'Profile',
                    shadowColor: Color(0xFF6366F1),
                    textColor: Colors.white,
                    elevation: 16,
                    overlayColor: Color(0xFF6366F1),
                    glowEnabled: true,
                  ),
                  parallaxDepth: 0.5,
                  borderRadius: 0, // No border radius for app bar
                  show3DText: false, // We'll use our own overlay text
                  slots: DepthCardSlots.empty, // Empty slots, we'll add our own overlay
                  backgroundFilterQuality: FilterQuality.none,
                ),
              ),
            ),

            // Gradient Overlay for better readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),

            // Optional: Profile info overlay at bottom of app bar
            if (!innerBoxIsScrolled)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          // Name and username
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userData['displayName'] ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _userData['username'] ?? '@user',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Level badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Lv ${_userData['level']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
              ),
          ],
        ),
      ),
      leading: _buildGlassButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (widget.isOwnProfile)
          _buildGlassButton(
            icon: Icons.edit_rounded,
            onPressed: _navigateToEditProfile,
          )
        else
          _buildGlassButton(
            icon: Icons.more_vert_rounded,
            onPressed: () => _showOptionsMenu(context),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceCard() {
    return StreamBuilder<UserPresence?>(
      stream: _presenceService.watchUserPresence(widget.userId),
      builder: (context, snapshot) {
        final presence = snapshot.data;
        if (presence == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.15),
                const Color(0xFF3B82F6).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: RichPresenceIndicator(
            presence: presence,
            showDetailedInfo: true,
          ),
        );
      },
    );
  }

  Widget _buildXPProgressCard() {
    final progress = (_userData['currentXP'] / _userData['maxXP']).clamp(0.0, 1.0);
    final xpNeeded = _userData['maxXP'] - _userData['currentXP'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Level Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_userData['currentXP']} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${_userData['level']} → ${_userData['level'] + 1}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$xpNeeded XP to go',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Performance'),
          Tab(text: 'Activity'),
          Tab(text: 'Milestones'),
          Tab(text: 'Collection'),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Matches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._generateRecentMatches().map((match) => _buildMatchCard(match)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final isWin = match['result'] == 'win';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWin
              ? [
            const Color(0xFF10B981).withValues(alpha: 0.15),
            const Color(0xFF3B82F6).withValues(alpha: 0.1),
          ]
              : [
            const Color(0xFFEF4444).withValues(alpha: 0.15),
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWin
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFEF4444).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWin
                    ? [const Color(0xFF10B981), const Color(0xFF3B82F6)]
                    : [const Color(0xFFEF4444), const Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWin ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match['category'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match['score']} points',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            match['time'],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: _generateRecentActivities().length,
      itemBuilder: (context, index) {
        final activity = _generateRecentActivities()[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity['icon'],
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _generateAchievements().length,
      itemBuilder: (context, index) {
        final achievement = _generateAchievements()[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'];

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
            colors: [
              const Color(0xFFFBBF24).withValues(alpha: 0.2),
              const Color(0xFFF59E0B).withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFFBBF24).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                )
                    : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement['icon'],
                size: 28,
                color: Colors.white.withValues(alpha: isUnlocked ? 1 : 0.3),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              achievement['name'],
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: Colors.white.withValues(alpha: isUnlocked ? 1 : 0.4),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${achievement['progress']}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avatar Collection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCollectionSection('Installed Packages', _generateInstalledAvatars()),
          const SizedBox(height: 20),
          _buildCollectionSection('Built-in Avatars', _generateBuiltInAvatars()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollectionSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildCollectionItem(item);
          },
        ),
      ],
    );
  }

  Widget _buildCollectionItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item['icon'],
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 6),
          Text(
            item['name'],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToEditProfile() async {
    // Use the state provider for synchronous access
    final profile = ref.read(activeProfileStateProvider);

    if (profile != null) {
      // Show the edit profile bottom sheet
      final result = await EditProfileBottomSheet.show(context, profile);

      // If changes were saved, the providers automatically update via profileManagerProvider
      if (result == true && mounted) {
        // Profile was updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      // Fallback: Try to load from the async provider
      try {
        final multiProfileService = ref.read(multiProfileServiceProvider);
        final loadedProfile = await multiProfileService.getActiveProfile();

        if (loadedProfile != null && mounted) {
          final result = await EditProfileBottomSheet.show(context, loadedProfile);

          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('Profile updated successfully!'),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active profile found'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading profile: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _navigateToArcadeScores() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LocalArcadeLeaderboardScreen()),
    );
  }

  void _navigateToMissions() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ArcadeMissionsScreen()),
    );
  }

  void _claimDailyBonus() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DailyBonusScreen()),
    );
  }

  void _showMutualFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MutualFriendsScreen(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              icon: Icons.message_rounded,
              title: 'Send Message',
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction('message');
              },
            ),
            _buildOptionTile(
              icon: Icons.sports_esports_rounded,
              title: 'Challenge to Quiz',
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction('challenge');
              },
            ),
            const Divider(color: Colors.white24),
            _buildOptionTile(
              icon: Icons.block_rounded,
              title: 'Block',
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction('block');
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(achievement['icon'], color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement['description'],
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (achievement['unlocked'])
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked: ${achievement['unlockedDate']}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${achievement['progress']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement['progress'] / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: $action'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Mock data generators
  List<Map<String, dynamic>> _generateRecentMatches() {
    return [
      {'category': 'Science', 'score': 850, 'result': 'win', 'time': '2h ago'},
      {'category': 'History', 'score': 720, 'result': 'win', 'time': '5h ago'},
      {'category': 'Sports', 'score': 640, 'result': 'loss', 'time': '1d ago'},
      {'category': 'Movies', 'score': 910, 'result': 'win', 'time': '1d ago'},
    ];
  }

  List<Map<String, dynamic>> _generateRecentActivities() {
    return [
      {
        'icon': Icons.emoji_events,
        'title': 'Earned "Quiz Master" achievement',
        'time': '2 hours ago'
      },
      {
        'icon': Icons.people,
        'title': 'Added 3 new friends',
        'time': '5 hours ago'
      },
      {'icon': Icons.star, 'title': 'Reached Level 42', 'time': '1 day ago'},
      {
        'icon': Icons.sports_esports,
        'title': 'Won 5 games in a row',
        'time': '1 day ago'
      },
      {
        'icon': Icons.group,
        'title': 'Joined "Trivia Champions" group',
        'time': '2 days ago'
      },
    ];
  }

  List<Map<String, dynamic>> _generateAchievements() {
    return [
      {
        'name': 'First Win',
        'icon': Icons.star,
        'unlocked': true,
        'description': 'Win your first game',
        'unlockedDate': '15 Jan 2024'
      },
      {
        'name': 'Speed Demon',
        'icon': Icons.flash_on,
        'unlocked': true,
        'description': 'Answer 10 questions in under 30 seconds',
        'unlockedDate': '20 Jan 2024'
      },
      {
        'name': 'Brain Box',
        'icon': Icons.psychology,
        'unlocked': true,
        'description': 'Get 100% in a quiz',
        'unlockedDate': '3 Feb 2024'
      },
      {
        'name': 'Social',
        'icon': Icons.people,
        'unlocked': true,
        'description': 'Add 50 friends',
        'unlockedDate': '10 Feb 2024'
      },
      {
        'name': 'Streak',
        'icon': Icons.local_fire_department,
        'unlocked': false,
        'description': '30-day streak',
        'progress': 70
      },
      {
        'name': 'Champion',
        'icon': Icons.emoji_events,
        'unlocked': false,
        'description': 'Win 100 games',
        'progress': 45
      },
      {
        'name': 'Master',
        'icon': Icons.rocket,
        'unlocked': false,
        'description': 'Master all categories',
        'progress': 60
      },
      {
        'name': 'Team Player',
        'icon': Icons.group,
        'unlocked': false,
        'description': 'Play 50 team games',
        'progress': 30
      },
      {
        'name': 'Night Owl',
        'icon': Icons.nightlight,
        'unlocked': false,
        'description': 'Play after midnight 10x',
        'progress': 80
      },
    ];
  }

  List<Map<String, dynamic>> _generateInstalledAvatars() {
    return [
      {'name': 'Robot', 'icon': Icons.smart_toy},
      {'name': 'Animal', 'icon': Icons.pets},
      {'name': 'Sci-Fi', 'icon': Icons.rocket_launch},
      {'name': 'Fantasy', 'icon': Icons.auto_awesome},
    ];
  }

  List<Map<String, dynamic>> _generateBuiltInAvatars() {
    return [
      {'name': 'School', 'icon': Icons.school},
      {'name': 'Sports', 'icon': Icons.sports_basketball},
      {'name': 'Music', 'icon': Icons.music_note},
      {'name': 'Art', 'icon': Icons.palette},
      {'name': 'Science', 'icon': Icons.science},
      {'name': 'Gaming', 'icon': Icons.videogame_asset},
      {'name': 'Nature', 'icon': Icons.park},
      {'name': 'Food', 'icon': Icons.restaurant},
    ];
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
