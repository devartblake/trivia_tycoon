import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/mission_card_widget.dart';
import '../../game/providers/xp_provider.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../core/services/notification_service.dart';

class MissionPanel extends ConsumerStatefulWidget {
  final int playerXP;
  final Function(int xpGained) onXPAdded;

  const MissionPanel({
    super.key,
    required this.playerXP,
    required this.onXPAdded,
  });

  @override
  ConsumerState<MissionPanel> createState() => _MissionPanelState();
}

class _MissionPanelState extends ConsumerState<MissionPanel>
    with TickerProviderStateMixin {
  AnimationController? _headerAnimationController;
  Animation<double>? _headerSlideAnimation;
  bool _isSwapping = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController!,
      curve: Curves.easeOutBack,
    ));
    _headerAnimationController!.forward();
  }

  @override
  void dispose() {
    _headerAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _handleSwap(String missionId) async {
    if (_isSwapping) return;

    setState(() {
      _isSwapping = true;
    });

    try {
      final missionActions = ref.read(missionActionsProvider);
      await missionActions.swapMission(missionId);

      if (mounted) {
        _showSuccessSnackBar("Mission swapped successfully!");

        // Send notification for successful swap
        await _notificationService.showBasicNotification(
          title: 'Mission Swapped! 🔄',
          body: 'New mission assigned! Check your updated mission list.',
          payload: {
            'mission_id': missionId,
            'type': 'swap_success',
            'screen': 'missions',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Failed to swap mission: ${e.toString()}");

        // Send notification for swap failure
        await _notificationService.showBasicNotification(
          title: 'Swap Failed ❌',
          body: 'Unable to swap mission. Please try again later.',
          payload: {
            'mission_id': missionId,
            'type': 'swap_error',
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwapping = false;
        });
      }
    }
  }

  void _handleCompleteMission(String missionId, int reward) {
    incrementXP(ref, reward);

    final missions = ref.read(liveMissionsProvider);
    final mission = missions.firstWhere((m) => m['id'] == missionId);
    final total = mission['total'] as int;
    final currentProgress = mission['progress'] as int;

    if (currentProgress < total) {
      ref.read(missionActionsProvider).updateProgress(missionId, total - currentProgress);
    }

    _showRewardSnackBar(reward);

    // Send mission completion notification
    _notificationService.showMissionNotification(
      title: '🎉 Mission Complete!',
      body: '${mission['title']} - You earned $reward XP!',
      reward: reward,
      payload: {
        'mission_id': missionId,
        'reward': reward.toString(),
        'type': 'completion',
        'screen': 'missions',
      },
    );
  }

  void _navigateToMissionScreen() {
    context.push('/missions');
  }

  void _showRewardSnackBar(int reward) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "+$reward XP gained!",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentXP = ref.watch(playerXPProvider);
    final missionsAsync = ref.watch(liveMissionsProvider);

    // Add null safety check for missionsAsync
    final missions = missionsAsync ?? [];

    // Early return if missions are still loading
    if (missions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200, // Fixed height to prevent layout issues
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E).withOpacity(0.8),
              const Color(0xFF16213E).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.8),
            const Color(0xFF16213E).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Key change: prevent unbounded height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - fixed size
            _buildHeader(currentXP),

            // Flexible spacer to push content to bottom
            const SizedBox(height: 16),

            // Mission cards - fixed height
            _buildMissionsList(missions),

            const SizedBox(height: 16),

            // Navigation button - fixed size
            _buildNavigationButton(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int currentXP) {
    return _headerAnimationController != null && _headerSlideAnimation != null
        ? AnimatedBuilder(
      animation: _headerAnimationController!,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_headerSlideAnimation!.value, 0),
          child: _headerContent(currentXP),
        );
      },
    )
        : _headerContent(currentXP);
  }

  Widget _buildHeaderContent(int currentXP) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.8),
            const Color(0xFF5A4FCF).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.track_changes,
                  color: Colors.amber,
                  size: 24,
                ),
                if (_isSwapping)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevent unbounded height
              children: [
                const Text(
                  "🎯 Active Missions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSwapping ? "Swapping mission..." : "Complete missions to earn XP",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "$currentXP XP",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList(List<Map<String, dynamic>> missions) {
    // Add safety check
    if (missions.isEmpty) {
      return SizedBox(
        height: 260,
        child: const Center(
          child: Text(
            'No missions available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 260, // Fixed height to prevent layout issues
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: missions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final mission = missions[index];
          final missionId = mission['id'] as String;
          final isCompleted = mission['progress'] >= mission['total'];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: GestureDetector(
                    onDoubleTap: isCompleted
                        ? () => _handleCompleteMission(missionId, mission['reward'])
                        : null,
                    child: MissionCardWithSwapButton(
                      title: mission['title'],
                      progress: mission['progress'],
                      total: mission['total'],
                      reward: mission['reward'],
                      icon: mission['icon'],
                      badge: mission['badge'],
                      onSwap: () => _handleSwap(missionId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNavigationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToMissionScreen,
        icon: const Icon(Icons.assignment, size: 20),
        label: const Text(
          'View All Missions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF6C5CE7).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _headerContent(int currentXP) {
    return _buildHeaderContent(currentXP);
  }
}