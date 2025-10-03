class FlowConnectGridCell {
  final int row;
  final int col;
  final int? number;
  final bool isVisited;
  final bool isWall;

  FlowConnectGridCell({
    required this.row,
    required this.col,
    this.number,
    this.isVisited = false,
    this.isWall = false,
  });

  FlowConnectGridCell copyWith({
    int? row,
    int? col,
    int? number,
    bool? isVisited,
    bool? isWall,
  }) {
    return FlowConnectGridCell(
      row: row ?? this.row,
      col: col ?? this.col,
      number: number ?? this.number,
      isVisited: isVisited ?? this.isVisited,
      isWall: isWall ?? this.isWall,
    );
  }
}