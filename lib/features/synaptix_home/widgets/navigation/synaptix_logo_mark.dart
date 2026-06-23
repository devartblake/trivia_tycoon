import 'package:flutter/material.dart';

import '../../theme/synaptix_home_theme.dart';

class SynaptixLogoMark extends StatelessWidget {
  const SynaptixLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [SynaptixHomeTheme.purple, SynaptixHomeTheme.blue],
        ),
      ),
      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
    );
  }
}
