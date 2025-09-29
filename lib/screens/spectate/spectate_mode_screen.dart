import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/advanced/spectate_streaming_service.dart';
import 'widgets/live_game_viewer.dart';
import 'widgets/spectator_chat.dart';
import 'widgets/game_progress_indicator.dart';

class SpectateModeScreen extends StatefulWidget {
  final String gameId;
  final String currentUserId;
  final String currentUserDisplayName;

  const SpectateModeScreen({
    super.key,
    required this.gameId,
    required this.currentUserId,
    required this.currentUserDisplayName,
  });

  @override
  State<SpectateModeScreen> createState() => _SpectateModeScreenState();
}

class _SpectateModeScreenState extends State<SpectateModeScreen> {
  final SpectateStreamingService _spectateService = SpectateStreamingService();
  bool _showChat = true;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _joinSpectate();
  }

  @override
  void dispose() {
    _leaveSpectate();
    super.dispose();
  }

  void _joinSpectate() {
    _spectateService.joinSpectate(
      gameId: widget.gameId,
      spectatorId: widget.currentUserId,
      spectatorName: widget.currentUserDisplayName,
    );
  }

  void _leaveSpectate() {
    _spectateService.leaveSpectate(
      gameId: widget.gameId,
      spectatorId: widget.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showLeaveConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StreamBuilder<GameSpectateState>(
          stream: _spectateService.watchGame(widget.gameId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildLoadingState();
            }

            final gameState = snapshot.data!;

            if (gameState.hasEnded) {
              return _buildGameEndedState(gameState);
            }

            return Stack(
              children: [
                // Main game viewer
                _buildGameViewer(gameState),

                // Top overlay with info
                if (_showControls) _buildTopOverlay(gameState),

                // Bottom overlay with controls
                if (_showControls) _buildBottomOverlay(gameState),

                // Side chat panel
                if (_showChat) _buildChatPanel(gameState),

                // Floating action buttons
                _buildFloatingControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Connecting to game...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameEndedState(GameSpectateState gameState) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Game Ended!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Winner: ${gameState.winner ?? "Unknown"}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Leave'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _findAnotherGame,
                  icon: const Icon(Icons.search),
                  label: const Text('Find Another Game'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameViewer(GameSpectateState gameState) {
    return LiveGameViewer(
      gameState: gameState,
      onQuestionChange: (index) {
        // Handle question change
      },
    );
  }

  Widget _buildTopOverlay(GameSpectateState gameState) {
    return Positioned(
      top: 0,
      left: 0,
      right: _showChat ? 300 : 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => _showLeaveConfirmation(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle, size: 8, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${gameState.spectatorCount} watching',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gameState.gameTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GameProgressIndicator(gameState: gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(GameSpectateState gameState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: _showChat ? 300 : 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlayerScores(gameState),
            const SizedBox(height: 12),
            _buildActionButtons(gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScores(GameSpectateState gameState) {
    return Row(
      children: gameState.players.map((player) {
        final isLeading = player.score == gameState.players
            .map((p) => p.score)
            .reduce((a, b) => a > b ? a : b);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLeading
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLeading ? Colors.amber : Colors.white30,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Text(
                        player.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLeading) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.score} pts',
                  style: TextStyle(
                    color: isLeading ? Colors.amber : Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(GameSpectateState gameState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.favorite_border,
          label: 'Cheer',
          onPressed: _sendCheer,
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onPressed: _shareGame,
        ),
        _buildActionButton(
          icon: Icons.sports_esports,
          label: 'Join Next',
          onPressed: () => _requestToJoin(gameState),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white30),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildChatPanel(GameSpectateState gameState) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 300,
      child: SpectatorChat(
        gameId: widget.gameId,
        currentUserId: widget.currentUserId,
        currentUserDisplayName: widget.currentUserDisplayName,
        spectatorCount: gameState.spectatorCount,
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: _showChat ? 316 : 16,
      top: MediaQuery.of(context).size.height / 2 - 50,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'chat',
            onPressed: () => setState(() => _showChat = !_showChat),
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            heroTag: 'controls',
            onPressed: () => setState(() => _showControls = !_showControls),
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              _showControls ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _sendCheer() {
    HapticFeedback.mediumImpact();
    _spectateService.sendReaction(
      gameId: widget.gameId,
      spectatorId: widget.currentUserId,
      reaction: '❤️',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cheer sent!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareGame() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share This Game',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text: 'https://yourapp.com/spectate/${widget.gameId}',
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.white),
              title: const Text('Share to Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Share to chat
              },
            ),
          ],
        ),
      ),
    );
  }

  void _requestToJoin(GameSpectateState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Next Game'),
        content: const Text('Would you like to join when the next game starts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Request to join logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You\'ll be notified when the next game starts')),
              );
            },
            child: const Text('Join Queue'),
          ),
        ],
      ),
    );
  }

  void _findAnotherGame() {
    Navigator.pop(context);
    // Navigate to spectate lobby
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Spectate Mode'),
        content: const Text('Are you sure you want to stop watching this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
