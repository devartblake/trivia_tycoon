import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/segmented_selection_hub.dart';
import 'package:synaptix/core/design_system/demographic_asset_wrapper.dart';
import 'package:synaptix/core/design_system/holographic_dialog.dart';
import 'package:synaptix/core/design_system/neon_button.dart';
import 'package:synaptix/core/services/presence/rich_presence_service.dart';
import 'package:synaptix/game/models/user_presence_models.dart';
import 'package:synaptix/game/providers/multi_profile_providers.dart';
import 'package:synaptix/game/providers/profile_providers.dart';
import 'package:synaptix/ui_components/presence/rich_presence_indicator.dart';
import 'package:synaptix/screens/profile/enhanced/sections/profile_header_section.dart';
import 'package:synaptix/screens/profile/enhanced/sections/profile_stats_section.dart';
import 'package:synaptix/screens/profile/enhanced/sections/arcade_summary_section.dart';
import 'package:synaptix/screens/profile/enhanced/sections/missions_preview_section.dart';
import 'package:synaptix/screens/profile/enhanced/sections/daily_bonus_section.dart';
import 'package:synaptix/screens/profile/enhanced/sections/profile_actions_section.dart';
import 'package:synaptix/screens/profile/enhanced/sheets/edit_profile_bottom_sheet.dart';
import 'package:synaptix/screens/profile/enhanced/widgets/crypto_holdings_card.dart';

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
  ConsumerState<EnhancedProfileScreen> createState() =>
      _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  final RichPresenceService _presenceService = RichPresenceService();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, dynamic> _userData = {
    'displayName': 'Alex Johnson',
    'username': '@alexj',
    'title': 'Pattern Sprinter',
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

  final Map<String, dynamic> _arcadeData = {
    'quickMathBest': 1850,
    'quickMathRank': 3,
    'patternSprintBest': 2340,
    'patternSprintRank': 7,
    'lastRun': {
      'game': 'Quick Math Rush',
      'score': 1650,
      'time': '2 hours ago'
    },
  };

  final Map<String, dynamic> _missionsData = {
    'dailyProgress': 3,
    'dailyTotal': 5,
    'weeklyProgress': 8,
    'weeklyTotal': 15,
    'seasonProgress': 45,
    'seasonTotal': 100,
  };

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
    _tabController.addListener(() => setState(() {}));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
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
      if (mounted) {
        setState(() {
          _mergeCareerSummary(summary);
        });
      }
    } catch (_) {}
    if (!widget.isOwnProfile) return;
    try {
      final loadout = await backendService.getLoadout();
      if (mounted) {
        setState(() {
          _mergeLoadout(loadout);
        });
      }
    } catch (_) {}
  }

  void _mergeCareerSummary(Map<String, dynamic> summary) {
    final stats = _asMap(summary['stats']);
    final progress = _asMap(summary['progress']);
    _userData.addAll({
      if (_readInt(summary, ['level'], fallbackMap: progress) != null)
        'level': _readInt(summary, ['level'], fallbackMap: progress),
      if (_readInt(summary, ['totalPoints', 'points'], fallbackMap: stats) !=
          null)
        'totalPoints':
            _readInt(summary, ['totalPoints', 'points'], fallbackMap: stats),
      if (_readInt(summary, ['friendCount', 'friends'], fallbackMap: stats) !=
          null)
        'friendCount':
            _readInt(summary, ['friendCount', 'friends'], fallbackMap: stats),
      if (_readInt(summary, ['rank'], fallbackMap: stats) != null)
        'rank': _readInt(summary, ['rank'], fallbackMap: stats),
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
        'username': '@${_readString(payload, const [
              'username',
              'handle'
            ])!.replaceAll('@', '')}',
      if (_readString(payload, const ['bio']) != null)
        'bio': _readString(payload, const ['bio']),
    });
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? value.map((k, v) => MapEntry(k.toString(), v)) : {};
  int? _readInt(Map<String, dynamic> s, List<String> ks,
      {Map<String, dynamic>? fallbackMap}) {
    for (final k in ks) {
      final v = s[k] ?? fallbackMap?[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  String? _readString(Map<String, dynamic> s, List<String> ks) {
    for (final k in ks) {
      final v = s[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'surface_journey',
      child: SynaptixScaffold(
        appBar: GlassAppBar(
          title: const GlowText('Journey'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
                icon: Icon(
                    widget.isOwnProfile
                        ? Icons.edit_rounded
                        : Icons.more_vert_rounded,
                    color: Colors.white),
                onPressed: () => widget.isOwnProfile
                    ? _navigateToEditProfile()
                    : _showOptionsMenu(context)),
            const SizedBox(width: 8),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                  child: SizedBox(height: kToolbarHeight + 20)),
              SliverToBoxAdapter(
                  child: Stack(children: [
                ProfileHeaderSection(
                    userData: _userData,
                    isOwnProfile: widget.isOwnProfile,
                    onEditProfile: _navigateToEditProfile),
                const Positioned(
                    right: 20,
                    top: 0,
                    child: DemographicAssetWrapper(
                        kidsAsset: 'assets/images/avatars/kids_mascot.png',
                        teenAsset: 'assets/images/avatars/teen_avatar.png',
                        adultAsset:
                            'assets/images/avatars/adult_professional.png',
                        width: 80,
                        height: 80)),
              ])),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildPresenceCard()),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: ProfileStatsSection(
                      userData: _userData, onFriendsTap: _showMutualFriends)),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildXPProgressCard()),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: CryptoHoldingsCard(
                      userId: widget.userId,
                      isOwnProfile: widget.isOwnProfile)),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              if (!widget.isOwnProfile)
                SliverToBoxAdapter(
                    child: ProfileActionsSection(
                        onMessage: () => _handleMenuAction('message'),
                        onChallenge: () => _handleMenuAction('challenge'))),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: ArcadeSummarySection(
                      arcadeData: _arcadeData,
                      onViewAllScores: _navigateToArcadeScores)),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: MissionsPreviewSection(
                      missionsData: _missionsData,
                      onViewMissions: _navigateToMissions)),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              if (widget.isOwnProfile)
                SliverToBoxAdapter(
                    child: DailyBonusSection(
                        bonusData: _dailyBonusData,
                        onClaimBonus: _claimDailyBonus)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SegmentedSelectionHub(
                          items: const ['Stats', 'Activity', 'Badges', 'Vault'],
                          selectedIndex: _tabController.index,
                          onItemSelected: (i) => _tabController.animateTo(i)))),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverFillRemaining(
                  child: TabBarView(controller: _tabController, children: [
                _buildStatsTab(),
                _buildActivityTab(),
                _buildAchievementsTab(),
                _buildCollectionTab()
              ])),
            ],
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
        return AdaptiveGlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            glowColor: const Color(0xFF10B981),
            child: RichPresenceIndicator(
                presence: presence, showDetailedInfo: true));
      },
    );
  }

  Widget _buildXPProgressCard() {
    final progress =
        (_userData['currentXP'] / _userData['maxXP']).clamp(0.0, 1.0);
    return AdaptiveGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            const GlowText('Level Progress', style: TextStyle(fontSize: 16)),
          ]),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF40E0D0), Color(0xFF00CED1)]),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${_userData['currentXP']} XP',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(children: [
              Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1))),
              FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                      height: 12,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                        Color(0xFF40E0D0),
                        Color(0xFF00CED1)
                      ])))),
            ])),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Level ${_userData['level']} → ${_userData['level'] + 1}',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text('${_userData['maxXP'] - _userData['currentXP']} XP to go',
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const GlowText('Recent Matches', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          ..._generateRecentMatches().map((match) => _buildMatchCard(match)),
          const SizedBox(height: 20),
        ]));
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final isWin = match['result'] == 'win';
    return AdaptiveGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      glowColor: isWin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isWin
                        ? [const Color(0xFF10B981), const Color(0xFF3B82F6)]
                        : [const Color(0xFFEF4444), const Color(0xFFF59E0B)]),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                isWin ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 24)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(match['category'],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${match['score']} points',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ])),
        Text(match['time'],
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildActivityTab() => ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: _generateRecentActivities().length,
      itemBuilder: (c, i) =>
          _buildActivityCard(_generateRecentActivities()[i]));
  Widget _buildActivityCard(Map<String, dynamic> activity) => AdaptiveGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(activity['icon'], size: 20, color: Colors.white)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(activity['title'],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(activity['time'],
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ])),
      ]));

  Widget _buildAchievementsTab() => GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
      itemCount: _generateAchievements().length,
      itemBuilder: (c, i) => _buildAchievementCard(_generateAchievements()[i]));
  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final unlocked = achievement['unlocked'];
    return AdaptiveGlassCard(
        glowColor: unlocked ? const Color(0xFFFBBF24) : null,
        onTap: () => _showAchievementDetails(achievement),
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: unlocked
                      ? const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)])
                      : LinearGradient(colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.08)
                        ]),
                  shape: BoxShape.circle),
              child: Icon(achievement['icon'],
                  size: 28,
                  color: Colors.white.withValues(alpha: unlocked ? 1 : 0.3))),
          const SizedBox(height: 10),
          Text(achievement['name'],
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: unlocked ? 1 : 0.4)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (!unlocked) ...[
            const SizedBox(height: 6),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${achievement['progress']}%',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.5))))
          ],
        ]));
  }

  Widget _buildCollectionTab() => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const GlowText('Collection', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        _buildCollectionSection(
            'Installed Packages', _generateInstalledAvatars()),
        const SizedBox(height: 20),
        _buildCollectionSection('Built-in Avatars', _generateBuiltInAvatars()),
        const SizedBox(height: 20)
      ]));
  Widget _buildCollectionSection(
          String title, List<Map<String, dynamic>> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemCount: items.length,
            itemBuilder: (c, i) => _buildCollectionItem(items[i]))
      ]);
  Widget _buildCollectionItem(Map<String, dynamic> item) => AdaptiveGlassCard(
      padding: EdgeInsets.zero,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(item['icon'], color: Colors.white, size: 32),
        const SizedBox(height: 6),
        Text(item['name'],
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis)
      ]));

  void _navigateToEditProfile() async {
    final profile = ref.read(activeProfileStateProvider);
    if (profile != null) {
      final result = await EditProfileBottomSheet.show(context, profile);
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Profile updated!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981)));
      }
    }
  }

  void _navigateToArcadeScores() => context.push('/arcade/local-leaderboards');
  void _navigateToMissions() => context.push('/arcade/missions');
  void _claimDailyBonus() => context.push('/arcade/daily-bonus');
  void _showMutualFriends() =>
      context.push('/profile/mutual-friends/${widget.userId}',
          extra: widget.currentUserId);

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A24),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildOptionTile(
                  icon: Icons.message_rounded,
                  title: 'Send Message',
                  onTap: () {
                    Navigator.pop(c);
                    _handleMenuAction('message');
                  }),
              _buildOptionTile(
                  icon: Icons.sports_esports_rounded,
                  title: 'Challenge',
                  onTap: () {
                    Navigator.pop(c);
                    _handleMenuAction('challenge');
                  }),
              const Divider(color: Colors.white24),
              _buildOptionTile(
                  icon: Icons.block_rounded,
                  title: 'Block',
                  onTap: () {
                    Navigator.pop(c);
                    _handleMenuAction('block');
                  },
                  isDestructive: true),
            ])));
  }

  Widget _buildOptionTile(
          {required IconData icon,
          required String title,
          required VoidCallback onTap,
          bool isDestructive = false}) =>
      ListTile(
          leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white),
          title: Text(title,
              style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.white,
                  fontWeight: FontWeight.w600)),
          onTap: onTap);

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    HolographicDialog.show(
        context: context,
        glowColor: achievement['unlocked'] ? const Color(0xFFFBBF24) : null,
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(achievement['icon'],
                            color: Colors.white, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: GlowText(achievement['name'],
                            style: const TextStyle(fontSize: 18))),
                  ]),
                  const SizedBox(height: 16),
                  Text(achievement['description'],
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  if (achievement['unlocked'])
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.3))),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text('Unlocked: ${achievement['unlockedDate']}',
                              style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13))
                        ]))
                  else
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Progress',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text('${achievement['progress']}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))
                              ]),
                          const SizedBox(height: 8),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                  value: achievement['progress'] / 100,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF6366F1)),
                                  minHeight: 6)),
                        ]),
                  const SizedBox(height: 24),
                  NeonButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE')),
                ])));
  }

  void _handleMenuAction(String action) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action: $action'),
          behavior: SnackBarBehavior.floating));

  List<Map<String, dynamic>> _generateRecentMatches() => [
        {
          'category': 'Science',
          'score': 850,
          'result': 'win',
          'time': '2h ago'
        },
        {
          'category': 'History',
          'score': 720,
          'result': 'win',
          'time': '5h ago'
        },
        {
          'category': 'Sports',
          'score': 640,
          'result': 'loss',
          'time': '1d ago'
        },
        {'category': 'Movies', 'score': 910, 'result': 'win', 'time': '1d ago'},
      ];
  List<Map<String, dynamic>> _generateRecentActivities() => [
        {
          'icon': Icons.emoji_events,
          'title': 'Earned "Quiz Master"',
          'time': '2h ago'
        },
        {'icon': Icons.people, 'title': 'Added 3 friends', 'time': '5h ago'},
        {'icon': Icons.star, 'title': 'Reached Lv 42', 'time': '1d ago'},
      ];
  List<Map<String, dynamic>> _generateAchievements() => [
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
          'description': '10 questions in < 30s',
          'unlockedDate': '20 Jan 2024'
        },
        {
          'name': 'Streak',
          'icon': Icons.local_fire_department,
          'unlocked': false,
          'description': '30-day streak',
          'progress': 70
        },
      ];
  List<Map<String, dynamic>> _generateInstalledAvatars() => [
        {'name': 'Robot', 'icon': Icons.smart_toy},
        {'name': 'Animal', 'icon': Icons.pets}
      ];
  List<Map<String, dynamic>> _generateBuiltInAvatars() => [
        {'name': 'School', 'icon': Icons.school},
        {'name': 'Sports', 'icon': Icons.sports_basketball}
      ];
}
