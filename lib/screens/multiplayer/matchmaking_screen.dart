import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/adaptive_glass_card.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/neon_button.dart';
import 'package:synaptix/core/design_system/neural_bloom_indicator.dart';
import 'package:synaptix/screens/multiplayer/multiplayer_palette.dart';
import 'package:synaptix/screens/multiplayer/widgets/connection_banner.dart';
import '../../game/multiplayer/providers/multiplayer_providers.dart';
import 'dialogs/exit_match_confirm.dart';
import 'dialogs/select_room_dialog.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _roomNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mpState = ref.watch(multiplayerControllerProvider);
    final roomState = ref.watch(roomControllerProvider);

    return PopScope(
        canPop: false, // Prevent default back behavior
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final ok =
              await showExitMatchConfirm(context, title: 'Leave matchmaking?');
          if (ok == true && context.mounted) {
            context.go('/multiplayer'); // Go back to MultiplayerHub
          }
        },
        child: SynaptixScaffold(
          appBar: GlassAppBar(
            title: const GlowText('Find Match'),
            leading: IconButton(
              onPressed: () async {
                final ok = await showExitMatchConfirm(context,
                    title: 'Leave matchmaking?');
                if (ok == true && context.mounted) {
                  context.go('/multiplayer');
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ConnectionBanner(state: mpState),
                    const SizedBox(height: 32),
                    _buildMatchmakingOptions(),
                    const SizedBox(height: 32),
                    if (roomState.loading) _buildLoadingCard(),
                    if (!roomState.loading && roomState.roomId != null)
                      _buildRoomJoinedCard(roomState),
                    const SizedBox(height: 24),
                    _buildQuickTips(),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildMatchmakingOptions() {
    return AdaptiveGlassCard(
      glowColor: MultiplayerPalette.primary,
      padding: const EdgeInsets.all(24),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Find Your Match',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCreateRoomSection(),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          _buildBrowseRoomsSection(),
        ],
      ),
    );
  }

  Widget _buildCreateRoomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: MultiplayerPalette.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Create New Room',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: _roomNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter room name...',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon:
                  Icon(Icons.meeting_room_rounded, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLength: 30,
            buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
          ),
        ),
        const SizedBox(height: 12),
        NeonButton(
          onPressed: () => _createRoom(),
          color: MultiplayerPalette.success,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Create Room'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseRoomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.explore_rounded,
              color: MultiplayerPalette.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Browse Existing Rooms',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NeonButton(
          onPressed: () => _browseRooms(),
          color: MultiplayerPalette.primary,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Browse Rooms'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return AdaptiveGlassCard(
      glowColor: MultiplayerPalette.primary,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const NeuralBloomIndicator(size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlowText(
                  'Creating Room...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Setting up your multiplayer room',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomJoinedCard(dynamic roomState) {
    return AdaptiveGlassCard(
      glowColor: MultiplayerPalette.success,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const GlowText(
                'Room Joined!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Room ID: ${roomState.roomId}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          NeonButton(
            onPressed: () => context.go('/multiplayer/rooms'),
            color: MultiplayerPalette.success,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Enter Lobby'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: MultiplayerPalette.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: MultiplayerPalette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip('Create a custom room to play with friends'),
          _buildTip('Browse public rooms for quick matches'),
          _buildTip('Room names can be up to 30 characters long'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: MultiplayerPalette.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a room name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ref.read(roomControllerProvider.notifier).createRoom(roomName);
      _roomNameController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _browseRooms() async {
    final picked = await showSelectRoomDialog(context);
    if (picked == null) return;

    await ref.read(roomControllerProvider.notifier).joinRoom(picked);
    if (!mounted) return;
    context.go('/multiplayer/rooms');
  }
}
