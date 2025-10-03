enum Direction {
  up,
  down,
  left,
  right,
  none,
}

class FlowConnectPathPoint {
  final int row;
  final int col;
  final int order;
  final Direction fromDirection;
  final Direction toDirection;

  FlowConnectPathPoint({
    required this.row,
    required this.col,
    required this.order,
    this.fromDirection = Direction.none,
    this.toDirection = Direction.none,
  });

  FlowConnectPathPoint copyWith({
    int? row,
    int? col,
    int? order,
    Direction? fromDirection,
    Direction? toDirection,
  }) {
    return FlowConnectPathPoint(
      row: row ?? this.row,
      col: col ?? this.col,
      order: order ?? this.order,
      fromDirection: fromDirection ?? this.fromDirection,
      toDirection: toDirection ?? this.toDirection,
    );
  }
}