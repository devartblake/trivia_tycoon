import 'package:flutter/material.dart';

import '../../theme/synaptix_home_theme.dart';

class SynaptixProgressBar extends StatelessWidget {
  final double value;

  const SynaptixProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: value,
        backgroundColor: SynaptixHomeTheme.stroke.withValues(alpha: 0.72),
        valueColor: const AlwaysStoppedAnimation(SynaptixHomeTheme.cyan),
      ),
    );
  }
}
