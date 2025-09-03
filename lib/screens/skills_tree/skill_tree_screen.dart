import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/skill_tree_view.dart';

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Tree')),
      body:  InteractiveViewer(
        boundaryMargin: EdgeInsets.all(300),
        minScale: 0.5,
        maxScale: 2.5,
        child: SkillTreeView(),
      ),
    );
  }
}
