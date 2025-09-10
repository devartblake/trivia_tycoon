/// Axial hex coordinates (q, r) for pointy/top or flat layouts.
/// Cube "s" is implicitly: s = -q - r
class Coordinates {
  final int q;
  final int r;
  /// Unnamed constructor so you can do: `Coordinates(1, 2)`
  const Coordinates(this.q, this.r);

  /// Optional named ctor if you ever want clarity at call-sites.
  const Coordinates.axial(this.q, this.r);

  /// Construct from cube coordinates (x, y, z) with x + y + z == 0
  factory Coordinates.fromCube(int x, int y, int z) {
    assert(x + y + z == 0, 'Cube coordinates must satisfy x + y + z == 0.');
    // axial(q=x, r=z)
    return Coordinates(x, z);
  }

  int get s => -q - r;

  Coordinates copyWith({int? q, int? r}) => Coordinates(q ?? this.q, r ?? this.r);

  @override
  String toString() => 'Coordinates(q: $q, r: $r, s: $s)';

  @override
  bool operator ==(Object o) => o is Coordinates && o.q == q && o.r == r;

  @override
  int get hashCode => Object.hash(q, r);
}

enum OffsetParity { odd, even }
enum OffsetKind { row, column }

class OffsetCoordinates {
  final int a; // row or column index
  final int b; // column or row index
  final OffsetKind kind; // row-based or column-based offset
  final OffsetParity parity; // odd/even
  const OffsetCoordinates(this.a, this.b, this.kind, this.parity);
  int get row => kind == OffsetKind.row ? a : b;
  int get col => kind == OffsetKind.row ? b : a;
}
