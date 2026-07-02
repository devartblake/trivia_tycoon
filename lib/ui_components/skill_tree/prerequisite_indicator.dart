import 'package:flutter/material.dart';

/// Indicator showing prerequisite requirement status
class PrerequisiteIndicator extends StatelessWidget {
  final String requiredSkillName;
  final bool isMet;
  final IconData? icon;

  const PrerequisiteIndicator({
    super.key,
    required this.requiredSkillName,
    required this.isMet,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMet ? Colors.green : Colors.grey;
    final statusIcon = isMet ? Icons.check_circle : Icons.lock;

    return Row(
      children: [
        Icon(icon ?? statusIcon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            requiredSkillName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }
}
