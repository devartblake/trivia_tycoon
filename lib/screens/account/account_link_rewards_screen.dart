import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/providers/riverpod_providers.dart';

class AccountLinkRewardsScreen extends ConsumerWidget {
  final bool fromOnboarding;

  const AccountLinkRewardsScreen({
    super.key,
    this.fromOnboarding = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final claims = ref.watch(accountRewardsProvider);
    final identity = ref.watch(playerIdentityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Rewards'),
        automaticallyImplyLeading: !fromOnboarding,
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(fromOnboarding ? 'Skip' : 'Done'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              fromOnboarding
                  ? 'Keep your progress and unlock extras'
                  : 'Account and social rewards',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your current identity is ${_identityLabel(identity.kind)}. Add account links when you are ready; each reward can be claimed once.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const _PrimaryLinkActions(),
            const SizedBox(height: 20),
            claims.when(
              data: (claimed) => Column(
                children: accountRewardDefinitions.map((reward) {
                  final isClaimed = claimed.contains(reward.key);
                  final action = _actionForReward(context, reward.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RewardTile(
                      reward: reward,
                      isClaimed: isClaimed,
                      actionLabel: action.label,
                      onPressed: isClaimed ? null : action.onPressed,
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text(
                'Reward status is unavailable right now. You can still play.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Continue to Home'),
            ),
          ],
        ),
      ),
    );
  }

  String _identityLabel(PlayerIdentityKind kind) {
    switch (kind) {
      case PlayerIdentityKind.platformLinked:
        return 'linked to your game platform';
      case PlayerIdentityKind.fullAccount:
        return 'a full account';
      case PlayerIdentityKind.anonymousDevice:
        return 'this device';
      case PlayerIdentityKind.unresolved:
        return 'being prepared';
    }
  }

  _RewardAction _actionForReward(BuildContext context, String rewardKey) {
    switch (rewardKey) {
      case 'onboarding_complete':
        return const _RewardAction(label: 'Auto');
      case 'website_account_linked':
        return _RewardAction(
          label: 'Create',
          onPressed: () => context.push('/register'),
        );
      case 'phone_or_qr_linked':
        return _RewardAction(
          label: 'Link',
          onPressed: () => context.push('/link-code'),
        );
      case 'discord_connected':
      case 'twitch_connected':
      case 'x_connected':
        return _RewardAction(
          label: 'Connect',
          onPressed: () => _showProviderPending(context),
        );
      default:
        return const _RewardAction(label: 'Pending');
    }
  }

  void _showProviderPending(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Social connection will be available after the provider link endpoint is enabled.',
        ),
      ),
    );
  }
}

class _RewardAction {
  final String label;
  final VoidCallback? onPressed;

  const _RewardAction({
    required this.label,
    this.onPressed,
  });
}

class _PrimaryLinkActions extends StatelessWidget {
  const _PrimaryLinkActions();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () => context.push('/register'),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create account'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/link-code'),
          icon: const Icon(Icons.password_rounded),
          label: const Text('Link code'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/qr-scanner'),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR'),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  final AccountRewardDefinition reward;
  final bool isClaimed;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _RewardTile({
    required this.reward,
    required this.isClaimed,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isClaimed ? Icons.check : Icons.card_giftcard),
        ),
        title: Text(reward.title),
        subtitle: Text('${reward.description}\n${reward.rewardText}'),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: onPressed,
          child: Text(isClaimed ? 'Claimed' : actionLabel),
        ),
        textColor: isClaimed ? theme.colorScheme.onSurfaceVariant : null,
      ),
    );
  }
}
