class QrMatrix {
  final int size;
  final List<List<bool>> modules;

  QrMatrix(this.size)
      : modules = List.generate(size, (_) => List.filled(size, false));

  void set(int x, int y, bool value) {
    if (x >= 0 && x < size && y >= 0 && y < size) {
      modules[y][x] = value;
    }
  }

  bool get(int x, int y) {
    if (x >= 0 && x < size && y >= 0 && y < size) {
      return modules[y][x];
    }
    return false;
  }
}
