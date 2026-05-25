import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reward_reactor_providers.dart';

class ReactorActionControls extends ConsumerWidget {
  const ReactorActionControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reactorProvider);
    final notifier = ref.read(reactorProvider.notifier);

    final canSpin = state.phase == ReactorPhase.idle;
    final canClaim =
        state.phase == ReactorPhase.pendingClaim && !state.isClaimInFlight;
    final showClaim = state.phase == ReactorPhase.pendingClaim ||
        state.phase == ReactorPhase.claiming ||
        state.phase == ReactorPhase.chaining;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              opacity: canSpin ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: canSpin ? notifier.spin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SPIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          if (showClaim) ...[
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedOpacity(
                opacity: canClaim ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: canClaim ? notifier.claim : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1A1040),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isClaimInFlight ||
                          state.phase == ReactorPhase.chaining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1040),
                          ),
                        )
                      : const Text(
                          'CLAIM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
