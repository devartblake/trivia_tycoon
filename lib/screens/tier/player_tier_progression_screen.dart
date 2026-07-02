import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/tier_progression_provider.dart';
import '../../ui_components/tier/current_tier_card.dart';
import '../../ui_components/tier/tier_progress_bar.dart';
import '../../ui_components/tier/tier_requirements_card.dart';
import '../../game/providers/game_providers.dart';

/// Main screen showing player's tier progression and rewards
class PlayerTierProgressionScreen extends ConsumerWidget {
  const PlayerTierProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tier Progression'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Current Tier Status
            _SectionHeader(title: 'Your Tier Status'),
            const SizedBox(height: 12),
            _CurrentTierSection(),
            const SizedBox(height: 32),

            // Section: Progression
            _SectionHeader(title: 'Progress'),
            const SizedBox(height: 12),
            _ProgressionSection(),
            const SizedBox(height: 32),

            // Section: Next Tier
            _SectionHeader(title: 'Next Tier'),
            const SizedBox(height: 12),
            _NextTierSection(),
            const SizedBox(height: 32),

            // Section: Tier Info
            _SectionHeader(title: 'How Tiers Work'),
            const SizedBox(height: 12),
            _TierInfoCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CurrentTierSection extends ConsumerWidget {
  const _CurrentTierSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsyncValue = ref.watch(_userIdProvider);

    return userIdAsyncValue.when(
      data: (userId) {
        if (userId == null || userId.isEmpty) {
          return _ErrorWidget(
            message: 'Unable to load user profile',
          );
        }

        final progressAsyncValue = ref.watch(playerTierProgressProvider(userId));
        return progressAsyncValue.when(
          data: (progress) => CurrentTierCard(progress: progress),
          loading: () => const _LoadingWidget(),
          error: (error, stack) => _ErrorWidget(
            message: 'Failed to load tier data: $error',
          ),
        );
      },
      loading: () => const _LoadingWidget(),
      error: (error, stack) => _ErrorWidget(
        message: 'Failed to load user profile',
      ),
    );
  }
}

class _ProgressionSection extends ConsumerWidget {
  const _ProgressionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsyncValue = ref.watch(_userIdProvider);

    return userIdAsyncValue.when(
      data: (userId) {
        if (userId == null || userId.isEmpty) {
          return _ErrorWidget(
            message: 'Unable to load user profile',
          );
        }

        final progressAsyncValue = ref.watch(playerTierProgressProvider(userId));
        return progressAsyncValue.when(
          data: (progress) => TierProgressBar(progress: progress),
          loading: () => const _LoadingWidget(),
          error: (error, stack) => _ErrorWidget(
            message: 'Failed to load tier progression',
          ),
        );
      },
      loading: () => const _LoadingWidget(),
      error: (error, stack) => _ErrorWidget(
        message: 'Failed to load user profile',
      ),
    );
  }
}

class _NextTierSection extends ConsumerWidget {
  const _NextTierSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsyncValue = ref.watch(_userIdProvider);

    return userIdAsyncValue.when(
      data: (userId) {
        if (userId == null || userId.isEmpty) {
          return _ErrorWidget(
            message: 'Unable to load user profile',
          );
        }

        final progressAsyncValue = ref.watch(playerTierProgressProvider(userId));
        return progressAsyncValue.when(
          data: (progress) => TierRequirementsCard(
            nextTier: progress.nextTier,
            xpNeeded: progress.isMaxTier
                ? 0
                : progress.xpNeededForNextTier - progress.xpInCurrentTier,
          ),
          loading: () => const _LoadingWidget(),
          error: (error, stack) => _ErrorWidget(
            message: 'Failed to load tier requirements',
          ),
        );
      },
      loading: () => const _LoadingWidget(),
      error: (error, stack) => _ErrorWidget(
        message: 'Failed to load user profile',
      ),
    );
  }
}

class _TierInfoCard extends StatelessWidget {
  const _TierInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoItem(
              icon: Icons.trending_up,
              title: 'Earn XP',
              description: 'Complete quizzes and challenges to earn XP',
            ),
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.star,
              title: 'Level Up',
              description: 'Reach XP thresholds to advance to new tiers',
            ),
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.card_giftcard,
              title: 'Unlock Rewards',
              description:
                  'Each tier grants coins, gems, and exclusive badges',
            ),
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.leaderboard,
              title: 'Compete',
              description:
                  'Higher tiers unlock competitive features and rankings',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Provider to get current user ID from PlayerProfileService
final _userIdProvider = FutureProvider<String?>((ref) async {
  final profileService = ref.read(playerProfileServiceProvider);
  return await profileService.getUserId();
});

/// Loading widget
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading tier data...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error widget
class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
