import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/neon_button.dart';
import 'package:synaptix/screens/multiplayer/multiplayer_palette.dart';
import 'package:synaptix/screens/multiplayer/widgets/player_chip.dart';
import '../../game/multiplayer/providers/multiplayer_providers.dart';
import 'dialogs/exit_match_confirm.dart';

class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({super.key, this.roomId});

  final String? roomId;

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(roomControllerProvider.notifier).joinRoom(widget.roomId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomControllerProvider);
    final players = state.players;

    return SynaptixScaffold(
      appBar: GlassAppBar(
        leading: IconButton(
          onPressed: () async {
            final ok =
                await showExitMatchConfirm(context, title: 'Leave lobby?');
            if (ok == true && context.mounted) {
              context.go('/multiplayer');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
        title: GlowText(state.roomName ?? state.roomId ?? 'Room Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final ok =
                  await showExitMatchConfirm(context, title: 'Leave lobby?');
              if (ok == true && context.mounted) {
                context.go('/multiplayer');
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
              child: SizedBox(height: kToolbarHeight + 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildRoomInfoCard(state),
                  const SizedBox(height: 24),
                  _buildPlayersSection(players),
                  const SizedBox(height: 24),
                  _buildGameSettings(),
                  const SizedBox(height: 32),
                  _buildStartButton(state, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard(dynamic state) {
    return AdaptiveGlassCard(
      glowColor: MultiplayerPalette.success,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MultiplayerPalette.success, Color(0xFF2E8E68)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Room Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.tag_rounded,
                  label: 'Room ID',
                  value: state.roomId ?? 'Unknown',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Host',
                  value: state.isHost ? 'You' : 'Other Player',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: MultiplayerPalette.primary,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection(List<dynamic> players) {
    return AdaptiveGlassCard(
      glowColor: MultiplayerPalette.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      MultiplayerPalette.primary,
                      MultiplayerPalette.secondary
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Players (${players.length}/8)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MultiplayerPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: MultiplayerPalette.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Waiting',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MultiplayerPalette.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (players.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 32,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Waiting for players to join...',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: players
                  .asMap()
                  .entries
                  .map((entry) => PlayerChip(
                        name: entry.value.name,
                        isHost: entry.value.isHost,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGameSettings() {
    return AdaptiveGlassCard(
      glowColor: MultiplayerPalette.accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      MultiplayerPalette.accent,
                      MultiplayerPalette.danger
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Game Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSettingItem(
                  icon: Icons.quiz_rounded,
                  label: 'Questions',
                  value: '10',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingItem(
                  icon: Icons.timer_rounded,
                  label: 'Time Limit',
                  value: '30s',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingItem(
                  icon: Icons.category_rounded,
                  label: 'Category',
                  value: 'Mixed',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: MultiplayerPalette.accent,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(dynamic state, BuildContext context) {
    return NeonButton(
      onPressed: state.isHost ? () => context.go('/multiplayer/match') : null,
      color: MultiplayerPalette.success,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.isHost ? Icons.play_arrow_rounded : Icons.lock_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            state.isHost ? 'Start Match' : 'Waiting for Host',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
