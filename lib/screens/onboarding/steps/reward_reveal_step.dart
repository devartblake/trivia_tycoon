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

    // Mark reward as seen
    widget.controller.updateUserData({'hasSeenRewardReveal': true});
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
    final score = widget.controller.userData['firstChallengeScore'] as int? ?? 0;
    final total =
        widget.controller.userData['firstChallengeTotal'] as int? ?? 3;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeIn,
        child: ScaleTransition(
          scale: _scaleUp,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Trophy icon
              Container(
                width: 120,
                height: 120,
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🏅', style: TextStyle(fontSize: 56)),
                ),
              ),

              const SizedBox(height: 32),

              // Headline
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

              const SizedBox(height: 40),

              // Reward cards
              _RewardRow(
                icon: Icons.bolt,
                iconColor: Colors.amber,
                label: 'Starter XP',
                value: '+100 XP',
              ),
              const SizedBox(height: 16),
              _RewardRow(
                icon: Icons.monetization_on_rounded,
                iconColor: const Color(0xFFFFD700),
                label: 'Starter Coins',
                value: '+250',
              ),
              const SizedBox(height: 16),
              _RewardRow(
                icon: Icons.route_rounded,
                iconColor: Colors.teal,
                label: 'Pathway Unlocked',
                value: 'Cognition',
              ),

              const Spacer(),

              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Enter Synaptix Hub',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RewardRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
