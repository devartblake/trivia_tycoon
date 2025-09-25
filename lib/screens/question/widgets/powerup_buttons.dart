import 'package:flutter/material.dart';

class EnhancedPowerUpButtons extends StatelessWidget {
  final List<PowerUpOption> powerUps;
  final String classLevel;

  const EnhancedPowerUpButtons({
    super.key,
    required this.powerUps,
    this.classLevel = '1',
  });

  @override
  Widget build(BuildContext context) {
    if (powerUps.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.amber.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Power-Ups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: powerUps.map((powerUp) {
              return _PowerUpButton(
                powerUp: powerUp,
                classLevel: classLevel,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PowerUpButton extends StatefulWidget {
  final PowerUpOption powerUp;
  final String classLevel;

  const _PowerUpButton({
    required this.powerUp,
    required this.classLevel,
  });

  @override
  State<_PowerUpButton> createState() => _PowerUpButtonState();
}

class _PowerUpButtonState extends State<_PowerUpButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.powerUp.isEnabled ? () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                widget.powerUp.onTap();
              } : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.powerUp.isEnabled
                      ? widget.powerUp.color.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.powerUp.isEnabled
                        ? widget.powerUp.color.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.powerUp.icon,
                      size: 18,
                      color: widget.powerUp.isEnabled
                          ? widget.powerUp.color
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.powerUp.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.powerUp.isEnabled
                            ? widget.powerUp.color
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Data class for Power-Up options
class PowerUpOption {
  final String label;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final VoidCallback onTap;
  final String description;

  PowerUpOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.onTap,
    required this.description,
  });
}
