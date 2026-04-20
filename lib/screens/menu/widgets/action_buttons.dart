import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Modern action buttons widget with grid/horizontal scroll layout
class ActionButtons extends StatelessWidget {
  final String ageGroup;
  final int unreadNotifications;
  final int pendingInvites;
  final bool dailyRewardsAvailable;
  final bool isDesktop;

  const ActionButtons({
    super.key,
    required this.ageGroup,
    this.unreadNotifications = 0,
    this.pendingInvites = 0,
    this.dailyRewardsAvailable = false,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getActions();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildActionsList(actions),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          if (!isDesktop)
            Row(
              children: [
                Icon(
                  Icons.swipe_left_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Scroll',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionsList(List<Map<String, dynamic>> actions) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _ActionCard(
              action: actions[index],
              animationDelay: index * 80,
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return _ActionItem(
            action: actions[index],
            animationDelay: index * 80,
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getActions() {
    final gradients = _getGradients();

    return [
      {
        'label': 'Hub',
        'icon': Icons.hub_rounded,
        'gradient': gradients[0],
        'route': '/game',
        'description': 'Synaptix Hub',
        'badge': null,
      },
      {
        'label': 'Invite',
        'icon': Icons.person_add_rounded,
        'gradient': gradients[0],
        'route': '/invite',
        'description': 'Invite friends to play',
        'badge': pendingInvites > 0 ? pendingInvites : null,
      },
      {
        'label': 'Rewards',
        'icon': Icons.star_rounded,
        'gradient': gradients[1],
        'route': '/rewards',
        'description': 'Daily rewards & bonuses',
        'badge': dailyRewardsAvailable ? 1 : null,
      },
      {
        'label': 'Labs',
        'icon': Icons.science_rounded,
        'gradient': gradients[5],
        'route': '/arcade',
        'description': 'Games & challenges',
        'badge': null,
      },
      {
        'label': 'Arena',
        'icon': Icons.emoji_events_rounded,
        'gradient': gradients[3],
        'route': '/leaderboard',
        'description': 'Rankings & tiers',
        'badge': null,
      },
      {
        'label': 'Challenges',
        'icon': Icons.emoji_events_rounded,
        'gradient': gradients[7],
        'route': '/challenges',
        'description': 'Weekly challenges',
        'badge': null,
      },
      {
        'label': 'Store',
        'icon': Icons.shopping_bag_rounded,
        'gradient': gradients[4],
        'route': '/store-hub',
        'description': 'Power-ups & boosters',
        'badge': null,
      },
      {
        'label': 'Settings',
        'icon': Icons.settings_rounded,
        'gradient': gradients[6],
        'route': '/settings',
        'description': 'Game preferences',
        'badge': unreadNotifications > 0 ? unreadNotifications : null,
      },
    ];
  }

  List<LinearGradient> _getGradients() {
    return [
      const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF64748B), Color(0xFF475569)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF84CC16), Color(0xFF65A30D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
  }
}

/// Action card for desktop grid view
class _ActionCard extends StatefulWidget {
  final Map<String, dynamic> action;
  final int animationDelay;

  const _ActionCard({
    required this.action,
    required this.animationDelay,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final gradient = widget.action['gradient'] as LinearGradient;
    final icon = widget.action['icon'] as IconData;
    final label = widget.action['label'] as String;
    final route = widget.action['route'] as String;
    final badge = widget.action['badge'] as int?;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(route);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null && badge > 0) _buildBadge(badge),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Positioned(
      right: 10,
      top: 10,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Action item for mobile horizontal scroll
class _ActionItem extends StatefulWidget {
  final Map<String, dynamic> action;
  final int animationDelay;

  const _ActionItem({
    required this.action,
    required this.animationDelay,
  });

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(20, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildItem(context),
    );
  }

  Widget _buildItem(BuildContext context) {
    final gradient = widget.action['gradient'] as LinearGradient;
    final icon = widget.action['icon'] as IconData;
    final label = widget.action['label'] as String;
    final route = widget.action['route'] as String;
    final badge = widget.action['badge'] as int?;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
