import 'package:flutter/material.dart';

class TierProgressionWidget extends StatefulWidget {
  final int currentTier;
  final int totalTiers;
  final Function(int)? onTierTap;

  const TierProgressionWidget({
    super.key,
    required this.currentTier,
    this.totalTiers = 10,
    this.onTierTap,
  });

  @override
  State<TierProgressionWidget> createState() => _TierProgressionWidgetState();
}

class _TierProgressionWidgetState extends State<TierProgressionWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _pulseAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.totalTiers,
          (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _pulseAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _animationControllers[i].forward();

          // Add pulse animation for current tier
          if (i == widget.currentTier) {
            _animationControllers[i].addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                _animationControllers[i].repeat(reverse: true);
              }
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(widget.totalTiers, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTierItem(index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTierItem(int index) {
    final isCurrentTier = index == widget.currentTier;
    final isUnlocked = index <= widget.currentTier;
    final isNextTier = index == widget.currentTier + 1;

    return GestureDetector(
      onTap: () {
        if (isUnlocked && widget.onTierTap != null) {
          widget.onTierTap!(index);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: isCurrentTier
                ? AnimatedBuilder(
              animation: _pulseAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimations[index].value,
                  child: _buildTierIcon(index, isCurrentTier, isUnlocked, isNextTier),
                );
              },
            )
                : _buildTierIcon(index, isCurrentTier, isUnlocked, isNextTier),
          );
        },
      ),
    );
  }

  Widget _buildTierIcon(int index, bool isCurrentTier, bool isUnlocked, bool isNextTier) {
    final size = isCurrentTier ? 80.0 : 60.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getTierGradient(index, isCurrentTier, isUnlocked),
        border: Border.all(
          color: isCurrentTier
              ? Colors.white
              : isUnlocked
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: isCurrentTier ? 3 : 2,
        ),
        boxShadow: isCurrentTier
            ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ]
            : isUnlocked
            ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _getTierIcon(index, isCurrentTier, isUnlocked),
            size: isCurrentTier ? 36 : 28,
            color: _getTierIconColor(index, isCurrentTier, isUnlocked),
          ),
          if (!isUnlocked && !isNextTier)
            Icon(
              Icons.lock,
              size: isCurrentTier ? 20 : 16,
              color: Colors.white.withOpacity(0.7),
            ),
          if (isCurrentTier)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  LinearGradient _getTierGradient(int index, bool isCurrentTier, bool isUnlocked) {
    if (isCurrentTier) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFD700), // Gold
          Color(0xFFFFA500), // Orange
          Color(0xFFFF8C00), // Dark Orange
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isUnlocked) {
      return LinearGradient(
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.8),
          const Color(0xFF7C3AED).withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.grey.withOpacity(0.3),
          Colors.grey.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  IconData _getTierIcon(int index, bool isCurrentTier, bool isUnlocked) {
    if (isCurrentTier) {
      return Icons.emoji_events; // Trophy for current tier
    } else if (isUnlocked) {
      return _getTierIconByIndex(index);
    } else {
      return Icons.shield_outlined;
    }
  }

  IconData _getTierIconByIndex(int index) {
    final icons = [
      Icons.emoji_events,
      Icons.star_border,
      Icons.star,
      Icons.shield,
      Icons.diamond,
      Icons.workspace_premium,
      Icons.military_tech,
      Icons.emoji_events_outlined,
      Icons.workspace_premium_outlined,
      Icons.monetization_on_outlined,
    ];
    return icons[index % icons.length];
  }

  Color _getTierIconColor(int index, bool isCurrentTier, bool isUnlocked) {
    if (isCurrentTier) {
      return Colors.white;
    } else if (isUnlocked) {
      return Colors.white;
    } else {
      return Colors.white.withOpacity(0.4);
    }
  }
}

// Example usage widget
class TierProgressionDemo extends StatefulWidget {
  const TierProgressionDemo({super.key});

  @override
  State<TierProgressionDemo> createState() => _TierProgressionDemoState();
}

class _TierProgressionDemoState extends State<TierProgressionDemo> {
  int currentTier = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text('Tier Progression'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TierProgressionWidget(
              currentTier: currentTier,
              totalTiers: 10,
              onTierTap: (index) {
                if (index <= currentTier) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tier ${index + 1} details'),
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: currentTier > 0
                      ? () => setState(() => currentTier--)
                      : null,
                  child: const Text('Previous Tier'),
                ),
                ElevatedButton(
                  onPressed: currentTier < 9
                      ? () => setState(() => currentTier++)
                      : null,
                  child: const Text('Next Tier'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Current Tier: ${currentTier + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}