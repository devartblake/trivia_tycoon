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

  // Cache static edge picture:
  Size? _cachedSizeKey;

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
  }) : categoryImages = categoryImages ?? const <SkillCategory, ui.Image?>{},
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
      if (from == null || to == null) {
        final fromScreen = _transformPoint(worldToScreen, from!);
        final toScreen = _transformPoint(worldToScreen, to!);
        canvas.drawLine(fromScreen, toScreen, edgePaint);
      }
    }

// Draw nodes using SkillNodeWidget as visual reference
    for (final node in graph.nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;
      final screenPos = _transformPoint(worldToScreen, pos);
      final isUnlocked = unlocked.contains(node.id);
      final categoryColor = SkillTreeCategoryColors.getColor(node.category);
      final isSelected = selectedId == node.id;
      final isFocused = focusedId == node.id;

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
    final bgColor = categoryColor;
    final glowColor = (isSelected || isUnlocked) ? bgColor.withOpacity(0.5) : Colors.transparent;
    final borderColor = isSelected ? Colors.white : Colors.black;

    final center = Offset(size.width / 2, size.height / 2);

    final paintFill = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (isSelected || isUnlocked) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius, glowPaint);
    }

    canvas.drawCircle(center, radius, paintFill);
    canvas.drawCircle(center, radius, paintBorder);

// Optional: You can render the title or icon here
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.title,
        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: radius * 2);
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }
}
