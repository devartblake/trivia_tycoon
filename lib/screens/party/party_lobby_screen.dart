import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/dto/party_dto.dart';
import '../../game/providers/party_providers.dart';
import '../../game/providers/profile_providers.dart';

/// Party / group-play lobby: create a party, invite players, manage incoming
/// invites, and enter matchmaking together. Backed by `/party/*` (gated by the
/// `social_enabled` flag server-side) with live updates over MatchHub.
class PartyLobbyScreen extends ConsumerWidget {
  const PartyLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerIdAsync = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Party')),
      body: playerIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Sign in required: $e')),
        data: (playerId) => _PartyBody(playerId: playerId),
      ),
    );
  }
}

class _PartyBody extends ConsumerStatefulWidget {
  final String playerId;
  const _PartyBody({required this.playerId});

  @override
  ConsumerState<_PartyBody> createState() => _PartyBodyState();
}

class _PartyBodyState extends ConsumerState<_PartyBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partyControllerProvider(widget.playerId).notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = partyControllerProvider(widget.playerId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    // One-shot navigation when a match is found for the party.
    ref.listen(provider, (prev, next) {
      if (next.matched != null) {
        controller.consumeMatched();
        context.go('/multiplayer/match');
      }
    });

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.error != null)
            _ErrorBanner(message: state.error!, onDismiss: () {}),
          if (!state.inParty)
            _NoPartyCard(busy: state.busy, onCreate: controller.createParty)
          else
            _RosterCard(
              state: state,
              isLeader: controller.isLeader,
              onLeave: controller.leaveParty,
              onInvite: () => _showInviteDialog(context, controller),
              onEnqueue: () => controller.enqueue(mode: 'ranked', tier: 1),
              onCancelQueue: controller.cancelQueue,
            ),
          const SizedBox(height: 24),
          Text('Invitations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.incomingInvites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No pending invitations.'),
            )
          else
            ...state.incomingInvites.map((inv) => _InviteTile(
                  invite: inv,
                  busy: state.busy,
                  onAccept: () => controller.acceptInvite(inv),
                  onDecline: () => controller.declineInvite(inv),
                )),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(
      BuildContext context, PartyController controller) async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite player'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Player ID',
            hintText: 'Paste the player\'s id',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (id != null && id.isNotEmpty) {
      await controller.invite(id);
    }
  }
}

class _NoPartyCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onCreate;
  const _NoPartyCard({required this.busy, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.groups, size: 48),
            const SizedBox(height: 12),
            Text('Play with friends',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Create a party, invite players, and queue for matches together.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : onCreate,
                child: const Text('Create Party'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  final PartyState state;
  final bool isLeader;
  final VoidCallback onLeave;
  final VoidCallback onInvite;
  final VoidCallback onEnqueue;
  final VoidCallback onCancelQueue;

  const _RosterCard({
    required this.state,
    required this.isLeader,
    required this.onLeave,
    required this.onInvite,
    required this.onEnqueue,
    required this.onCancelQueue,
  });

  @override
  Widget build(BuildContext context) {
    final roster = state.roster!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Party', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Chip(label: Text(state.queueStatus ?? roster.status)),
              ],
            ),
            const Divider(),
            ...roster.members.map((m) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: Text(m.playerId == roster.leaderPlayerId
                      ? '${m.playerId}  •  Leader'
                      : m.playerId),
                  subtitle: Text(m.role),
                )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: state.busy ? null : onInvite,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite'),
                ),
                if (isLeader && !state.isQueued)
                  FilledButton.icon(
                    onPressed: state.busy ? null : onEnqueue,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Find Match'),
                  ),
                if (isLeader && state.isQueued)
                  FilledButton.icon(
                    onPressed: state.busy ? null : onCancelQueue,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel Queue'),
                  ),
                TextButton.icon(
                  onPressed: state.busy ? null : onLeave,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Leave'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final PartyInviteDto invite;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InviteTile({
    required this.invite,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mail),
        title: Text('From ${invite.fromPlayerId}'),
        subtitle: Text('Party ${invite.partyId}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: busy ? null : onAccept,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: busy ? null : onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
