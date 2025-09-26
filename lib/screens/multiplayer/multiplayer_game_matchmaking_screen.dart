import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/multiplayer/room_lobby_screen.dart';
import '../../game/multiplayer/providers/multiplayer_providers.dart';
import '../../game/multiplayer/services/multiplayer_service.dart';
import '../../ui_components/multiplayer/versus/versus_screen.dart';
import '../question/play_quiz_screen.dart';
import '../question/question_view_screen.dart';
import '../question/transitional/how_to_play_screen.dart';
import 'matchmaking_screen.dart';
import 'multiplayer_hub_screen.dart';
import 'multiplayer_question_screen.dart';

class MultiplayerGameMatchmakingScreen extends ConsumerStatefulWidget {
  final String gameMode;

  const MultiplayerGameMatchmakingScreen({
    super.key,
    required this.gameMode,
  });

  @override
  ConsumerState<MultiplayerGameMatchmakingScreen> createState() =>
      _MultiplayerGameMatchmakingScreenState();
}

class _MultiplayerGameMatchmakingScreenState
    extends ConsumerState<MultiplayerGameMatchmakingScreen>
    with TickerProviderStateMixin {

  late AnimationController _searchController;
  late Animation<double> _pulseAnimation;
  bool _isSearching = false;
  String? _matchedOpponent;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOut,
    ));

    // Auto-start search for the specific game mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMatchmaking();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    setState(() {
      _isSearching = true;
    });

    _searchController.repeat(reverse: true);

    try {
      // Use the existing multiplayer service but specify game mode
      final result = await ref
          .read(multiplayerServiceProvider)
          .findMatchForGameMode(widget.gameMode);

      if (result != null && context.mounted) {
        setState(() {
          _isSearching = false;
          _matchedOpponent = result.opponentName;
        });

        _searchController.stop();

        // Show versus screen before starting match
        await _showVersusScreen(result);

        // Navigate to multiplayer question screen
        context.go('/quiz/multiplayer/${widget.gameMode}');
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isSearching = false;
        });
        _searchController.stop();
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _showVersusScreen(MatchResult matchResult) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VersusScreen(
          player1Name: 'You',
          player2Name: matchResult.opponentName,
          player1Avatar: matchResult.playerAvatar ?? '',
          player2Avatar: matchResult.opponentAvatar ?? '',
          player1Color: _getGameModeColor(widget.gameMode),
          player2Color: _getOpponentColor(widget.gameMode),
        ),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Color _getGameModeColor(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return const Color(0xFFEF5350);
      case 'teams':
        return const Color(0xFFAB47BC);
      default:
        return Colors.blue;
    }
  }

  Color _getOpponentColor(String gameMode) {
    switch (gameMode) {
      case 'arena':
        return const Color(0xFF4ECDC4);
      case 'teams':
        return const Color(0xFF66BB6A);
      default:
        return Colors.orange;
    }
  }

  String _getGameModeDisplayName() {
    switch (widget.gameMode) {
      case 'arena':
        return 'Treasure Mine';
      case 'teams':
        return 'Survival Arena';
      default:
        return widget.gameMode.toUpperCase();
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Matchmaking Failed'),
        content: Text('Could not find a match: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/play');
            },
            child: const Text('Back to Games'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startMatchmaking();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameColor = _getGameModeColor(widget.gameMode);

    return PopScope(
      canPop: !_isSearching,
      onPopInvoked: (didPop) {
        if (didPop) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Matchmaking?'),
            content: const Text('Are you sure you want to stop looking for a match?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Searching'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (context.mounted) {
                    context.go('/play');
                  }
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: gameColor.withOpacity(0.1),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game mode header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: gameColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gameColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        widget.gameMode == 'arena'
                            ? Icons.diamond
                            : Icons.sports_martial_arts,
                        size: 48,
                        color: gameColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getGameModeDisplayName(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: gameColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Matchmaking status
                if (_isSearching) ...[
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gameColor, gameColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: gameColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Finding Opponent...',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Looking for players ready to challenge in ${_getGameModeDisplayName()}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  LinearProgressIndicator(
                    backgroundColor: gameColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(gameColor),
                  ),

                ] else if (_matchedOpponent != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Match Found!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Opponent: $_matchedOpponent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Cancel button
                if (_isSearching)
                  OutlinedButton.icon(
                    onPressed: () => context.go('/play'),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel Search'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Match result model
class MatchResult {
  final String opponentName;
  final String? opponentAvatar;
  final String? playerAvatar;
  final String gameMode;

  MatchResult({
    required this.opponentName,
    this.opponentAvatar,
    this.playerAvatar,
    required this.gameMode,
  });
}