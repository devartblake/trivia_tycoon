import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/paint/auto_path_overlay_painter.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/widgets/mini_hex_preview.dart';

void main() {
  group('AutoPathOverlayPainter', () {
    test('paints a single-node highlighted path without throwing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = AutoPathOverlayPainter(
        centers: const {'root': Offset(60, 40)},
        pathIds: const ['root'],
        currentIndex: 0,
        showFullPath: true,
      );

      try {
        expect(
          () => painter.paint(canvas, const Size(120, 80)),
          returnsNormally,
        );
      } finally {
        final picture = recorder.endRecording();
        picture.dispose();
      }
    });
  });

  group('MiniHexBranchPreview', () {
    testWidgets('disables the dim mask for mini previews', (tester) async {
      final graph = SkillTreeGraph(
        nodes: [
          SkillNode(
            id: 'scholar_root',
            title: 'Scholar Root',
            description: 'start',
            tier: 0,
            cost: 1,
            category: SkillCategory.scholar,
            effects: const {},
            branchId: 'scholar',
          ),
          SkillNode(
            id: 'scholar_mid',
            title: 'Scholar Mid',
            description: 'next',
            tier: 1,
            cost: 1,
            category: SkillCategory.scholar,
            effects: const {},
            branchId: 'scholar',
          ),
        ],
        edges: const [
          SkillEdge(fromId: 'scholar_root', toId: 'scholar_mid'),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 220,
                child: MiniHexBranchPreview.fromGraph(
                  graph: graph,
                  branchId: 'scholar',
                  highlightPath: true,
                ),
              ),
            ),
          ),
        ),
      );

      final overlayPainters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<AutoPathOverlayPainter>()
          .toList();

      expect(overlayPainters, hasLength(1));
      expect(overlayPainters.single.showDimMask, isFalse);
    });
  });
}
