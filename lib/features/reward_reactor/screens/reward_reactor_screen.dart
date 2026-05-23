import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reward_reactor_providers.dart';
import '../widgets/arcade_reward_machine_widget.dart';

class RewardReactorScreen extends ConsumerWidget {
  const RewardReactorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ReactorState>(reactorProvider, (previous, next) {
      if (previous?.phase != next.phase && next.phase == ReactorPhase.applied) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
      }
      if (previous?.phase != next.phase &&
          next.phase == ReactorPhase.cooldown) {
        HapticFeedback.heavyImpact();
      }
      if (next.phase == ReactorPhase.error && next.errorMessage != null) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFF3D0C0C),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white70,
              onPressed: () => ref.read(reactorProvider.notifier).dismiss(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0718),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0924),
        foregroundColor: Colors.white,
        title: const Text(
          'Reward Reactor',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF3D2E7C)),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: ArcadeRewardMachineWidget(),
          ),
        ),
      ),
    );
  }
}
