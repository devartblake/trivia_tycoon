import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class GameModeGrid extends StatelessWidget {
  final List<SynaptixHomeAction> modes;

  const GameModeGrid({super.key, required this.modes});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHOOSE YOUR MODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final aspectRatio = columns == 1
                  ? 1.25
                  : columns == 2
                      ? 0.92
                      : 0.72;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: aspectRatio,
                children: [
                  for (final mode in modes) _ModeCard(mode: mode),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final SynaptixHomeAction mode;

  const _ModeCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.go(mode.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: SynaptixHomeTheme.modeGradient(mode.color),
          border: Border.all(color: mode.color.withValues(alpha: 0.55)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(mode.icon, color: mode.color, size: 42),
            const SizedBox(height: 12),
            Text(
              mode.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mode.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SynaptixHomeTheme.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: mode.color.withValues(alpha: 0.84),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => context.go(mode.route),
                child: const Text(
                  'PLAY NOW',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
