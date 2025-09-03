class BitMatrix {
  final int width;
  final int height;
  final List<List<bool>> matrix;

  BitMatrix(this.width, this.height)
      : matrix = List.generate(height, (_) => List.filled(width, false));

  bool get(int x, int y) => matrix[y][x];
  void set(int x, int y, bool value) => matrix[y][x] = value;

  int getWidth() => width;
  int getHeight() => height;

  void flip(int x, int y) {
    matrix[y][x] = !matrix[y][x];
  }

  BitMatrix clone() {
    final clone = BitMatrix(width, height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        clone.set(x, y, get(x, y));
      }
    }
    return clone;
  }
}
