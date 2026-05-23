import 'package:flutter/material.dart';

import 'arcade_reward_machine_widget.dart';

class ReactorOverlay extends StatelessWidget {
  const ReactorOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0718),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReactorOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: const SingleChildScrollView(
          child: ArcadeRewardMachineWidget(),
        ),
      ),
    );
  }
}
