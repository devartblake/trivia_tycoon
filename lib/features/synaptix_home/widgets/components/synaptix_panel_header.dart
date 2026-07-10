import 'package:flutter/material.dart';

import '../../theme/synaptix_home_theme.dart';

class SynaptixPanelHeader extends StatelessWidget {
  final String title;
  final String action;

  const SynaptixPanelHeader(
      {super.key, required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: SynaptixHomeTheme.purple,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
