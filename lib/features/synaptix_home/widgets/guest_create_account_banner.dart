import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/navigation/canonical_routes.dart';
import 'package:synaptix/features/synaptix_home/theme/synaptix_home_theme.dart';
import 'package:synaptix/game/providers/guest_session_providers.dart';

/// Persistent upper-right “Create account” chip for guest sessions.
class GuestCreateAccountBanner extends ConsumerWidget {
  final bool compact;

  const GuestCreateAccountBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestSessionProvider);
    if (!isGuest) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'Create a free account to keep progress and unlock online play',
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.go(canonicalRegisterRoute),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SynaptixHomeTheme.purple.withValues(alpha: 0.95),
                  SynaptixHomeTheme.cyan.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: SynaptixHomeTheme.purple.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 8 : 9,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Create account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
