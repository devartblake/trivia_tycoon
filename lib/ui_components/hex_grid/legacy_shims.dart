import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/paint/hex_shape.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/widgets/hexagon.dart';

import 'index.dart';
import 'math/hex_orientation.dart';
import 'model/coordinates.dart'; // re-exports math/model/paint/widgets

/// --- hex_spider_background_painter.dart (alias) ---------------------------
/// If code still imports the old filename, re-export your new painter:
export '../../screens/skills_tree/render/skill_tree_background_painter.dart'; // keep your class name consistent

/// --- hex_clipper.dart (shim) ----------------------------------------------
class HexClipper extends CustomClipper<Path> {
  final double radius;
  final HexOrientation orientation;
  HexClipper({required this.radius, this.orientation = HexOrientation.pointy});

  @override
  Path getClip(Size size) =>
      buildHexPath(center: size.center(Offset.zero), radius: radius, orientation: orientation);

  @override
  bool shouldReclip(covariant HexClipper old) =>
      old.radius != radius || old.orientation != orientation;
}

/// --- hex_tile.dart (shim) --------------------------------------------------
class HexTile extends StatelessWidget {
  final double radius;
  final HexOrientation orientation;
  final double cornerRadius;
  final double elevation;
  final Gradient? gradient;
  final Color? color;
  final Color borderColor;
  final double borderWidth;
  final Widget? child;

  const HexTile({
    super.key,
    required this.radius,
    this.orientation = HexOrientation.pointy,
    this.cornerRadius = 0,
    this.elevation = 2.0,
    this.gradient,
    this.color,
    this.borderColor = const Color(0x44FFFFFF),
    this.borderWidth = 1.5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Hexagon(
      radius: radius,
      orientation: orientation,
      gradient: gradient,
      color: color,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: child,
    );
  }
}

/// --- hex_interactive.dart (shim) ------------------------------------------
class HexInteractive extends StatelessWidget {
  final double radius;
  final HexOrientation orientation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? child;

  const HexInteractive({
    super.key,
    required this.radius,
    this.orientation = HexOrientation.pointy,
    this.onTap,
    this.onLongPress,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Hexagon(
        radius: radius,
        orientation: orientation,
        child: child,
      ),
    );
  }
}

/// --- hex_border_painter.dart (shim) ---------------------------------------
class HexBorderPainter extends CustomPainter {
  final double radius;
  final HexOrientation orientation;
  final Color color;
  final double strokeWidth;

  HexBorderPainter({
    required this.radius,
    this.orientation = HexOrientation.pointy,
    this.color = const Color(0x66FFFFFF),
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildHexPath(
      center: size.center(Offset.zero),
      radius: radius,
      orientation: orientation,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant HexBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
          oldDelegate.orientation != orientation ||
          oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth;
}

/// --- hex_edge_painter.dart (light shim) -----------------------------------
/// Paints per-edge highlights. Adjust [highlightEdge] or iterate all edges.
class HexEdgePainter extends CustomPainter {
  final double radius;
  final HexOrientation orientation;
  final int? highlightEdge; // 0..5 or null for all
  final Color color;
  final double strokeWidth;

  HexEdgePainter({
    required this.radius,
    this.orientation = HexOrientation.pointy,
    this.highlightEdge,
    this.color = const Color(0xAAFFFFFF),
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final path = buildHexPath(center: center, radius: radius, orientation: orientation);
    final metrics = path.computeMetrics().toList();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < metrics.length; i++) {
      if (highlightEdge != null && i != highlightEdge) continue;
      final m = metrics[i];
      // Draw each edge as a small extract of the path
      final tangent = m.getTangentForOffset(0)!;
      canvas.drawPath(m.extractPath(0, m.length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HexEdgePainter old) =>
      old.radius != radius || old.orientation != orientation ||
          old.highlightEdge != highlightEdge || old.color != color ||
          old.strokeWidth != strokeWidth;
}

/// --- hex_offset_grid.dart (adapter helpers) -------------------------------
/// Convert “offset coords” (odd-r/even-r or odd-q/even-q) to axial.
enum OffsetLayout { oddR, evenR, oddQ, evenQ }

class OffsetCoord {
  final int col; // x
  final int row; // y
  const OffsetCoord(this.col, this.row);
}

Coordinates offsetToAxial(OffsetCoord o, OffsetLayout layout) {
  switch (layout) {
    case OffsetLayout.oddR:  // rows shifted on odd rows
      final q = o.col - ((o.row - (o.row & 1)) ~/ 2);
      final r = o.row;
      return Coordinates(q, r);
    case OffsetLayout.evenR: // rows shifted on even rows
      final q = o.col - ((o.row + (o.row & 1)) ~/ 2);
      final r = o.row;
      return Coordinates(q, r);
    case OffsetLayout.oddQ:  // cols shifted on odd columns
      final q = o.col;
      final r = o.row - ((o.col - (o.col & 1)) ~/ 2);
      return Coordinates(q, r);
    case OffsetLayout.evenQ: // cols shifted on even columns
      final q = o.col;
      final r = o.row - ((o.col + (o.col & 1)) ~/ 2);
      return Coordinates(q, r);
  }
}
