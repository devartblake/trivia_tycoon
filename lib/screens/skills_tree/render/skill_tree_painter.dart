import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/utils/math_types.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/models/skill_tree_category_colors.dart';

class SkillTreePainter extends CustomPainter {
  final SkillTreeGraph graph;
  final Map<String, Offset> positions;
  final Mat4 worldToScreen;
  final double nodeRadius;
  final String? selectedId;
  final Set<String> unlocked;
  final void Function(String nodeId)? onNodeTap;
  final Map<SkillCategory, ui.Image?> categoryImages;
  final String? focusedId;
  final double glowPulse;

  SkillTreePainter({
    required this.graph,
    required this.positions,
    required this.worldToScreen,
    required this.nodeRadius,
    required this.selectedId,
    this.unlocked = const {},
    this.onNodeTap,
    this.glowPulse = 0.2,
    Map<SkillCategory, ui.Image?>? categoryImages,
    String? focusedId,
  })  : categoryImages = categoryImages ?? const <SkillCategory, ui.Image?>{},
        focusedId = focusedId ?? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint edgePaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 6;

// Draw edges
    for (final edge in graph.edges) {
      final from = positions[edge.fromId];
      final to = positions[edge.toId];
      if (from == null || to == null) continue;
      final fromScreen = _transformPoint(worldToScreen, from);
      final toScreen = _transformPoint(worldToScreen, to);
      canvas.drawLine(fromScreen, toScreen, edgePaint);
    }

// Draw nodes using SkillNodeWidget as visual reference
    for (final node in graph.nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;
      final screenPos = _transformPoint(worldToScreen, pos);
      final isUnlocked = unlocked.contains(node.id);
      final categoryColor = SkillTreeCategoryColors.getColor(node.category);
      final isSelected = selectedId == node.id;

      final painter = _SkillNodePainter(
        node: node,
        radius: nodeRadius,
        isUnlocked: isUnlocked,
        isSelected: isSelected,
        isFocused: focusedId,
        categoryColor: categoryColor,
      );

      canvas.save();
      canvas.translate(screenPos.dx - nodeRadius, screenPos.dy - nodeRadius);
      painter.paint(canvas, Size(nodeRadius * 2, nodeRadius * 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SkillTreePainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.positions != positions ||
        oldDelegate.worldToScreen != worldToScreen ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.focusedId != focusedId ||
        oldDelegate.glowPulse != glowPulse ||
        oldDelegate.unlocked != unlocked;
  }

  Offset _transformPoint(Matrix4 m, Offset p) {
    final v = m.transform3(Vec3(p.dx, p.dy, 0));
    return Offset(v.x, v.y);
  }
}

class _SkillNodePainter {
  final SkillNode node;
  final bool isUnlocked;
  final bool isSelected;
  final String? isFocused;
  final double radius;
  final Color categoryColor;

  _SkillNodePainter({
    required this.node,
    required this.radius,
    required this.isUnlocked,
    required this.isSelected,
    required this.isFocused,
    required this.categoryColor,
  });

  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Dark-to-pastel fill matching SkillNodeWidget gradient logic.
    final mixA = isSelected ? 0.45 : (isUnlocked ? 0.30 : 0.12);
    final fillColor = Color.lerp(const Color(0xFF090C1A), categoryColor, mixA)!;

    // Border: white for selected, category-tinted otherwise.
    final borderColor = isSelected
        ? Colors.white
        : isUnlocked
            ? categoryColor.withValues(alpha: 0.65)
            : categoryColor.withValues(alpha: 0.40);
    final borderWidth = isSelected ? 2.0 : 1.5;

    // Optional glow for selected / unlocked nodes.
    if (isSelected || isUnlocked) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = categoryColor.withValues(alpha: isSelected ? 0.35 : 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawCircle(center, radius, Paint()..color = fillColor);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // "+cost" label — large, category-coloured.
    final costColor = isUnlocked
        ? categoryColor.withValues(alpha: 0.90)
        : isSelected
            ? Colors.white
            : categoryColor.withValues(alpha: 0.55);

    final costPainter = TextPainter(
      text: TextSpan(
        text: '+${node.cost}',
        style: TextStyle(
          fontSize: radius * 0.50,
          fontWeight: FontWeight.bold,
          color: costColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: radius * 2);
    costPainter.paint(
      canvas,
      Offset(center.dx - costPainter.width / 2,
          center.dy - costPainter.height / 2 - radius * 0.10),
    );

    // Abbreviated title — small, muted white.
    final abbrev = node.title.length > 8
        ? '${node.title.substring(0, 7)}…'
        : node.title;
    final titlePainter = TextPainter(
      text: TextSpan(
        text: abbrev,
        style: TextStyle(
          fontSize: radius * 0.26,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: radius * 2);
    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2,
          center.dy + radius * 0.22),
    );
  }
}
