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
  late AnimationController _slideController;
  late AnimationController _vsController;
  late Animation<Offset> _player1SlideAnimation;
  late Animation<Offset> _player2SlideAnimation;
  late Animation<double> _vsScaleAnimation;
  late Animation<double> _vsOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animations for players
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // VS animation
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

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _vsController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top padding
                const SizedBox(height: 60),

                // Player 1 container
                SlideTransition(
                  position: _player1SlideAnimation,
                  child: PlayerContainer(
                    playerName: widget.player1Name,
                    playerAvatar: widget.player1Avatar,
                    score: widget.player1Score,
                    isLeftSide: true,
                    primaryColor: widget.player1Color,
                  ),
                ),

                // VS Section
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
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Player 2 container
                SlideTransition(
                  position: _player2SlideAnimation,
                  child: PlayerContainer(
                    playerName: widget.player2Name,
                    playerAvatar: widget.player2Avatar,
                    score: widget.player2Score,
                    isLeftSide: false,
                    primaryColor: widget.player2Color,
                  ),
                ),

                // Bottom padding
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
        // Split background with gradients
        Row(
          children: [
            // Player 1 side
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.player1Color.withOpacity(0.9),
                      widget.player1Color.withOpacity(0.7),
                      widget.player1Color.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            // Player 2 side
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      widget.player2Color.withOpacity(0.9),
                      widget.player2Color.withOpacity(0.7),
                      widget.player2Color.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Background image overlay if provided
        if (widget.backgroundImage != null)
          Positioned.fill(
            child: Image.asset(
              widget.backgroundImage!,
              fit: BoxFit.cover,
            ),
          ),

        // Diagonal split effect
        Positioned.fill(
          child: CustomPaint(
            painter: DiagonalSplitPainter(
              leftColor: widget.player1Color.withOpacity(0.3),
              rightColor: widget.player2Color.withOpacity(0.3),
            ),
          ),
        ),

        // Animated particles
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

  const PlayerContainer({
    super.key,
    required this.playerName,
    required this.playerAvatar,
    required this.score,
    required this.isLeftSide,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isLeftSide ? 20 : 60,
        right: isLeftSide ? 60 : 20,
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: isLeftSide ? MainAxisAlignment.start : MainAxisAlignment.end,
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
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.9),
            primaryColor.withOpacity(0.7),
          ],
          begin: isLeftSide ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeftSide ? Alignment.centerRight : Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
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
            crossAxisAlignment: isLeftSide ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
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
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.5),
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
      color: primaryColor.withOpacity(0.3),
      child: Icon(
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

    // Create diagonal split path
    final path = Path();
    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.6, 0);
    path.lineTo(size.width * 0.6, size.height);
    path.lineTo(size.width * 0.4, size.height);
    path.close();

    // Apply gradient
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

    // Draw animated particles
    for (int i = 0; i < 20; i++) {
      final isLeft = i % 2 == 0;
      final baseX = isLeft ? size.width * 0.25 : size.width * 0.75;
      final baseY = size.height * (i / 20);

      final offsetX = (isLeft ? -50 : 50) * (1 - animationValue);
      final opacity = animationValue * 0.6;

      paint.color = (isLeft ? leftColor : rightColor).withOpacity(opacity);

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
