import 'package:flutter/material.dart';

/// Fixed bottom power-up tray (Trivia-Crack style): one slot per available
/// power-up with icon + label, separated by dividers. Replaces the floating
/// action button stack.
///
/// Expects the same power-up maps produced by
/// `QuizHelpers.getAvailablePowerUps` ({type, icon, color, label}).
class PowerupTray extends StatelessWidget {
  final List<Map<String, dynamic>> powerUps;
  final bool enabled;
  final void Function(String type) onActivate;

  const PowerupTray({
    super.key,
    required this.powerUps,
    required this.enabled,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    if (powerUps.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < powerUps.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 12,
                    endIndent: 12,
                    color: Colors.grey.shade300,
                  ),
                Expanded(child: _traySlot(powerUps[i])),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _traySlot(Map<String, dynamic> powerUp) {
    final type = powerUp['type'] as String;
    final color = powerUp['color'] as Color;
    final icon = powerUp['icon'] as IconData;
    final label = powerUp['label'] as String? ?? type;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Power-up: $label',
      child: InkWell(
        onTap: enabled ? () => onActivate(type) : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
