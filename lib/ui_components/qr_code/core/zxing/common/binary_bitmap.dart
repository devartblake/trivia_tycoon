import 'bit_matrix.dart';

class BinaryBitmap {
  final BitMatrix matrix;

  BinaryBitmap(this.matrix);

  int get width => matrix.getWidth();
  int get height => matrix.getHeight();

  bool get(int x, int y) => matrix.get(x, y);

  BitMatrix getBlackMatrix() => matrix;
}
