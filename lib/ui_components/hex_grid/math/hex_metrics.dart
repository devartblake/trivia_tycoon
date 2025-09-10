import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../model/coordinates.dart';
import 'hex_orientation.dart';

class HexMetrics {
  /// Returns the pixel width/height of a hex tile for a given [size] (radius).
  static Size tileSize(double size, HexOrientation o) {
    if (o == HexOrientation.pointy) {
      final w = math.sqrt(3) * size; // ≈ 1.732 * size
      final h = 2 * size;
      return Size(w, h);
    } else {
      final w = 2 * size;
      final h = math.sqrt(3) * size;
      return Size(w, h);
    }
  }

  /// Axial (q,r) -> pixel center (x,y) for the hex grid.
  /// Formulas per Red Blob Games.
  static Offset axialToPixel(int q, int r, double size, HexOrientation o) {
    if (o == HexOrientation.pointy) {
      final x = size * math.sqrt(3) * (q + r / 2.0);
      final y = size * 1.5 * r;
      return Offset(x, y);
    } else {
      final x = size * 1.5 * q;
      final y = size * math.sqrt(3) * (r + q / 2.0);
      return Offset(x, y);
    }
  }

  /// Pixel -> axial (approximate inverse).
  static Coordinates pixelToAxial(Offset p, double size, HexOrientation o) {
    double q, r;
    if (o == HexOrientation.pointy) {
      q = (p.dx * math.sqrt(3) / 3 - p.dy / 3) / size;
      r = (p.dy * 2 / 3) / size;
    } else {
      q = (p.dx * 2 / 3) / size;
      r = (-p.dx / 3 + math.sqrt(3) / 3 * p.dy) / size;
    }
    final rounded = _cubeRound(q, r, -q - r);
    return Coordinates.axial(rounded[0], rounded[1]);
  }

  static List<int> _cubeRound(double q, double r, double s) {
    int rq = q.round();
    int rr = r.round();
    int rs = s.round();

    final qDiff = (rq - q).abs();
    final rDiff = (rr - r).abs();
    final sDiff = (rs - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      rq = -rr - rs;
    } else if (rDiff > sDiff) {
      rr = -rq - rs;
    } else {
      rs = -rq - rr;
    }
    return [rq, rr, rs];
  }

  /// Corners for sharp hex (relative to center).
  static List<Offset> corners(Offset center, double size, HexOrientation o) {
    final pts = <Offset>[];
    final startDeg = (o == HexOrientation.pointy) ? 30.0 : 0.0;
    for (int i = 0; i < 6; i++) {
      final deg = startDeg + 60.0 * i;
      final rad = deg * math.pi / 180.0;
      pts.add(Offset(
          center.dx + size * math.cos(rad), center.dy + size * math.sin(rad)));
    }
    return pts;
  }

  /// Rounded-corner hex path inside [rect].
  static Path roundedPathInRect(
      Rect rect, HexOrientation o, double cornerRadius) {
    final base = pathInRect(rect, o);
    if (cornerRadius <= 0) return base;

// Build rounded by walking corners and using arcTo between edges
    final size =
        (o == HexOrientation.pointy) ? rect.height / 2.0 : rect.width / 2.0;
    final center = rect.center;
    final pts = corners(center, size, o);

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final p0 = pts[i];
      final p1 = pts[(i + 1) % 6];
      final p_1 = pts[(i + 5) % 6];

// Direction vectors
      final vIn = (p0 - p_1);
      final vOut = (p1 - p0);
      final lin = vIn / vIn.distance;
      final lout = vOut / vOut.distance;

// Entry/exit points offset by cornerRadius along edges
      final entry = p0 - lin * cornerRadius;
      final exit = p0 + lout * cornerRadius;

      if (i == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.arcToPoint(exit, radius: Radius.circular(cornerRadius));
    }
    path.close();
    return path;
  }

  /// Sharp hex path inside [rect].
  static Path pathInRect(Rect rect, HexOrientation o) {
    final size =
        (o == HexOrientation.pointy) ? rect.height / 2.0 : rect.width / 2.0;
    final center = rect.center;
    final pts = corners(center, size, o);
    final path = Path()..addPolygon(pts, true);
    return path;
  }

  /// Offset (odd/even, row/column) -> axial
  static Coordinates offsetToAxial(OffsetCoordinates oc) {
    final row = oc.row;
    final col = oc.col;
    if (oc.kind == OffsetKind.row) {
// odd-r / even-r for pointy orientation
      final q = col - ((row + (oc.parity == OffsetParity.even ? 0 : 1)) >> 1);
      final r = row;
      return Coordinates.axial(q, r);
    } else {
// odd-q / even-q for flat orientation
      final q = col;
      final r = row - ((col + (oc.parity == OffsetParity.even ? 0 : 1)) >> 1);
      return Coordinates.axial(q, r);
    }
  }
}
