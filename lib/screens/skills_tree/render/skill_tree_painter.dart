import 'dart:ui';
import '../../../core/theme/skill_category_colors.dart';
import 'math_types.dart';
import 'package:flutter/material.dart';
import '../../../game/models/skill_tree_graph.dart';

class SkillTreePainter extends CustomPainter {
  final SkillTreeGraph graph;
  final Map<String, Offset> positions;
  final Mat4 worldToScreen;
  final double nodeRadius;
  final String? selectedId;

  // Cache static edge picture:
  Picture? _edgesPicture;
  Size? _cachedSizeKey;

  SkillTreePainter({
    required this.graph,
    required this.positions,
    required this.worldToScreen,
    required this.nodeRadius,
    required this.selectedId,
  });

  static final Map<SkillCategory, Color> categoryColors = {
    SkillCategory.Scholar: Color(0xFF73C2FB), // Sky blue
    SkillCategory.Strategist: Color(0xFFFFA07A), // Salmon
    SkillCategory.XP: Color(0xFFFFD700), // Gold
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in positions.entries) {
      final nodeId = entry.key;
      final position = entry.value;
      final node = graph.byId[nodeId];
      if (node == null) continue;


      final screenPos = MatrixUtils.transformPoint(worldToScreen, position);
      final isSelected = nodeId == selectedId;
      final isUnlocked = node.unlocked;


      final backgroundColor = SkillCategoryColors.background[node.category] ?? Colors.grey;
      final glowColor = SkillCategoryColors.glow[node.category] ?? Colors.white;


// Draw glow if selected or unlocked
      if (isSelected || isUnlocked) {
        final glowPaint = Paint()
          ..color = glowColor.withOpacity(isSelected ? 0.6 : 0.35)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(screenPos, nodeRadius + 4, glowPaint);
      }


// Fill circle
      final fillPaint = Paint()
        ..color = backgroundColor.withOpacity(isUnlocked ? 1.0 : 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(screenPos, nodeRadius, fillPaint);


// Stroke
      final strokePaint = Paint()
        ..color = isSelected ? Colors.white : Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.2;
      canvas.drawCircle(screenPos, nodeRadius, strokePaint);


      _drawLabel(canvas, screenPos, node.title);
    }
  }


  void _drawLabel(Canvas canvas, Offset pos, String text) {
    final span = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout(minWidth: 0, maxWidth: 100);
    final offset = pos + Offset(-tp.width / 2, nodeRadius + 6);
    tp.paint(canvas, offset);
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
