import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mode/synaptix_mode.dart';
import '../mode/synaptix_mode_provider.dart';
import '../theme/synaptix_theme_extension.dart';

/// Small banner showing the current Synaptix audience mode.
class SynaptixModeBanner extends ConsumerWidget {
  const SynaptixModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(synaptixModeProvider);
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = synaptix?.accentGlow ?? const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_modeIcon(mode), size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            _modeLabel(mode),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(SynaptixMode mode) {
    switch (mode) {
      case SynaptixMode.kids:
        return Icons.child_care;
      case SynaptixMode.teen:
        return Icons.bolt;
      case SynaptixMode.adult:
        return Icons.workspace_premium;
    }
  }

  String _modeLabel(SynaptixMode mode) {
    switch (mode) {
      case SynaptixMode.kids:
        return 'Kids Mode';
      case SynaptixMode.teen:
        return 'Teen Mode';
      case SynaptixMode.adult:
        return 'Adult Mode';
    }
  }
}
