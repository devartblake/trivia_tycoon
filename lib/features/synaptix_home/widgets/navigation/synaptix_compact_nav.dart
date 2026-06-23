import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/canonical_routes.dart';
import '../../theme/synaptix_home_theme.dart';

class SynaptixCompactNav extends StatelessWidget {
  const SynaptixCompactNav({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final destination = canonicalPrimaryNavRoutes[index];
          return ActionChip(
            avatar: Icon(
              destination.icon,
              size: 18,
              color: SynaptixHomeTheme.text,
            ),
            label: Text(destination.label),
            labelStyle: const TextStyle(color: SynaptixHomeTheme.text),
            backgroundColor: SynaptixHomeTheme.panel.withValues(alpha: 0.84),
            side: const BorderSide(color: SynaptixHomeTheme.stroke),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: () => context.go(destination.route),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: canonicalPrimaryNavRoutes.length,
      ),
    );
  }
}
