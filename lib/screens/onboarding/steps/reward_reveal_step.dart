import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

/// Shows the user their starter rewards before landing in the Hub.
///
/// Displays XP earned, starter credits, and the unlocked pathway.
/// Mode-aware copy (kids/teen/adult) based on the synaptixMode stored
/// in the onboarding controller.
class RewardRevealStep extends StatefulWidget {
  final ModernOnboardingController controller;
  final VoidCallback? onContinue;

  const RewardRevealStep({
    super.key,
    required this.controller,
    this.onContinue,
  });

  @override
  State<RewardRevealStep> createState() => _RewardRevealStepState();
}

class _RewardRevealStepState extends State<RewardRevealStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _animController.forward();

    // Defer so we don't call notifyListeners during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.updateUserData({'hasSeenRewardReveal': true});
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _modeHeadline() {
    final mode = widget.controller.synaptixMode ?? 'teen';
    switch (mode) {
      case 'kids':
        return 'You unlocked your first path!';
      case 'adult':
        return 'Your Synaptix journey begins now.';
      default:
        return 'You\'ve entered the Arena.';
    }
  }

  void _continue() {
    widget.controller.updateUserData({
      'starterXP': 100,
      'starterCredits': 250,
      'starterPathway': 'cognition',
    });
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      widget.controller.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score =
        widget.controller.userData['firstChallengeScore'] as int? ?? 0;
    final total =
        widget.controller.userData['firstChallengeTotal'] as int? ?? 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 620;
        final isWide = constraints.maxWidth >= 768;
        final padding = isCompact ? 16.0 : 24.0;
        final trophySize = isCompact ? 88.0 : 120.0;
        final trophyIconSize = isCompact ? 44.0 : 60.0;
        final sectionGap = isCompact ? 24.0 : 40.0;
        final contentHeight = constraints.maxHeight > padding * 2
            ? constraints.maxHeight - (padding * 2)
            : 0.0;

        final inner = Padding(
          padding: EdgeInsets.all(padding),
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleUp,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: contentHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: trophySize,
                        height: trophySize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: isCompact ? 20 : 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: trophyIconSize,
                        ),
                      ),
                      SizedBox(height: isCompact ? 20 : 32),
                      Text(
                        _modeHeadline(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Challenge score: $score / $total',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      _RewardRow(
                        icon: Icons.bolt,
                        iconColor: Colors.amber,
                        label: 'Starter XP',
                        value: '+100 XP',
                        dense: isCompact,
                      ),
                      SizedBox(height: isCompact ? 12 : 16),
                      _RewardRow(
                        icon: Icons.monetization_on_rounded,
                        iconColor: const Color(0xFFFFD700),
                        label: 'Starter Coins',
                        value: '+250',
                        dense: isCompact,
                      ),
                      SizedBox(height: isCompact ? 12 : 16),
                      _RewardRow(
                        icon: Icons.route_rounded,
                        iconColor: Colors.teal,
                        label: 'Pathway Unlocked',
                        value: 'Cognition',
                        dense: isCompact,
                      ),
                      SizedBox(height: sectionGap),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _continue,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isCompact ? 14 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Enter Synaptix Hub',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 0 : 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        if (!isWide) return inner;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: inner,
          ),
        );
      },
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool dense;

  const _RewardRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBoxSize = dense ? 40.0 : 44.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 16 : 20,
        vertical: dense ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
