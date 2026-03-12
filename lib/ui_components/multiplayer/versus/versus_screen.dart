import 'dart:async';
import 'package:flutter/material.dart';

class VersusScreen extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final String player1Avatar;
  final String player2Avatar;
  final int player1Score;
  final int player2Score;
  final Color player1Color;
  final Color player2Color;
  final String? backgroundImage;

  const VersusScreen({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.player1Avatar,
    required this.player2Avatar,
    this.player1Score = 0,
    this.player2Score = 0,
    this.player1Color = const Color(0xFFFF6B35),
    this.player2Color = const Color(0xFF4ECDC4),
    this.backgroundImage,
  });

  @override
  State<VersusScreen> createState() => _VersusScreenState();
}

class _VersusScreenState extends State<VersusScreen>
    with TickerProviderStateMixin {
  static const int _initialCountdown = 5;

  late AnimationController _slideController;
  late AnimationController _vsController;
  late Animation<Offset> _player1SlideAnimation;
  late Animation<Offset> _player2SlideAnimation;
  late Animation<double> _vsScaleAnimation;
  late Animation<double> _vsOpacityAnimation;

  int _countdown = _initialCountdown;
  Timer? _countdownTimer;
  bool _isPlayer1Ready = false;
  bool _isPlayer2Ready = false;
  bool _matchStarting = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _vsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _player1SlideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _player2SlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _vsScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _vsController,
      curve: Curves.bounceOut,
    ));

    _vsOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _vsController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _vsController.forward();
      _startCountdown();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown <= 1) {
        timer.cancel();
        _startMatch();
        return;
      }

      setState(() {
        _countdown -= 1;
      });
    });
  }

  void _toggleReady(bool isPlayer1) {
    if (_matchStarting) return;

    setState(() {
      if (isPlayer1) {
        _isPlayer1Ready = !_isPlayer1Ready;
      } else {
        _isPlayer2Ready = !_isPlayer2Ready;
      }

      if (_isPlayer1Ready && _isPlayer2Ready && _countdown > 1) {
        _countdown = 1;
      }
    });
  }

  void _startMatch() {
    if (_matchStarting || !mounted) return;

    setState(() {
      _matchStarting = true;
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _slideController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                SlideTransition(
                  position: _player1SlideAnimation,
                  child: PlayerContainer(
                    playerName: widget.player1Name,
                    playerAvatar: widget.player1Avatar,
                    score: widget.player1Score,
                    isLeftSide: true,
                    primaryColor: widget.player1Color,
                    isReady: _isPlayer1Ready,
                    onReadyPressed: () => _toggleReady(true),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _vsController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _vsScaleAnimation.value,
                          child: Opacity(
                            opacity: _vsOpacityAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'VS',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _matchStarting
                                        ? 'Starting…'
                                        : 'Match starts in $_countdown',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SlideTransition(
                  position: _player2SlideAnimation,
                  child: PlayerContainer(
                    playerName: widget.player2Name,
                    playerAvatar: widget.player2Avatar,
                    score: widget.player2Score,
                    isLeftSide: false,
                    primaryColor: widget.player2Color,
                    isReady: _isPlayer2Ready,
                    onReadyPressed: () => _toggleReady(false),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.player1Color.withValues(alpha: 0.9),
                      widget.player1Color.withValues(alpha: 0.7),
                      widget.player1Color.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      widget.player2Color.withValues(alpha: 0.9),
                      widget.player2Color.withValues(alpha: 0.7),
                      widget.player2Color.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.backgroundImage != null)
          Positioned.fill(
            child: Image.asset(
              widget.backgroundImage!,
              fit: BoxFit.cover,
            ),
          ),
        Positioned.fill(
          child: CustomPaint(
            painter: DiagonalSplitPainter(
              leftColor: widget.player1Color.withValues(alpha: 0.3),
              rightColor: widget.player2Color.withValues(alpha: 0.3),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  animationValue: _slideController.value,
                  leftColor: widget.player1Color,
                  rightColor: widget.player2Color,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PlayerContainer extends StatelessWidget {
  final String playerName;
  final String playerAvatar;
  final int score;
  final bool isLeftSide;
  final Color primaryColor;
  final bool isReady;
  final VoidCallback onReadyPressed;

  const PlayerContainer({
    super.key,
    required this.playerName,
    required this.playerAvatar,
    required this.score,
    required this.isLeftSide,
    required this.primaryColor,
    required this.isReady,
    required this.onReadyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isLeftSide ? 20 : 60,
        right: isLeftSide ? 60 : 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment:
            isLeftSide ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment:
                isLeftSide ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isLeftSide) ...[
                _buildPlayerInfo(),
                const SizedBox(width: 16),
                _buildAvatar(),
              ] else ...[
                _buildAvatar(),
                const SizedBox(width: 16),
                _buildPlayerInfo(),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: isLeftSide ? Alignment.centerLeft : Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onReadyPressed,
              icon: Icon(isReady ? Icons.check_circle : Icons.play_arrow_rounded),
              label: Text(isReady ? 'Ready' : 'Ready Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady
                    ? Colors.green.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.9),
                foregroundColor: isReady ? Colors.white : primaryColor,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.9),
            primaryColor.withValues(alpha: 0.7),
          ],
          begin: isLeftSide ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeftSide ? Alignment.centerRight : Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeftSide) ...[
            _buildScoreContainer(),
            const SizedBox(width: 12),
          ],
          Column(
            crossAxisAlignment:
                isLeftSide ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLeftSide) ...[
            const SizedBox(width: 12),
            _buildScoreContainer(),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.amber.shade300,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$score',
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

  Widget _buildAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.8),
            primaryColor.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: playerAvatar.startsWith('http')
            ? Image.network(
                playerAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: primaryColor.withValues(alpha: 0.3),
      child: const Icon(
        Icons.person,
        size: 35,
        color: Colors.white,
      ),
    );
  }
}

class DiagonalSplitPainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;

  DiagonalSplitPainter({
    required this.leftColor,
    required this.rightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final path = Path();
    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.6, 0);
    path.lineTo(size.width * 0.6, size.height);
    path.lineTo(size.width * 0.4, size.height);
    path.close();

    paint.shader = LinearGradient(
      colors: [
        leftColor,
        rightColor,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color leftColor;
  final Color rightColor;

  ParticlesPainter({
    required this.animationValue,
    required this.leftColor,
    required this.rightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final isLeft = i % 2 == 0;
      final baseX = isLeft ? size.width * 0.25 : size.width * 0.75;
      final baseY = size.height * (i / 20);

      final offsetX = (isLeft ? -50 : 50) * (1 - animationValue);
      final opacity = animationValue * 0.6;

      paint.color = (isLeft ? leftColor : rightColor).withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(baseX + offsetX, baseY),
        3 * animationValue,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
