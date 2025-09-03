class BitArray {
  final List<bool> _bits;

  BitArray([int size = 0]) : _bits = List.filled(size, false);

  int get size => _bits.length;

  void set(int index, bool value) {
    _ensureSize(index + 1);
    _bits[index] = value;
  }

  bool get(int index) => _bits[index];

  void appendBit(bool bit) {
    _bits.add(bit);
  }

  void appendBits(int value, int numBits) {
    for (int i = numBits - 1; i >= 0; i--) {
      _bits.add(((value >> i) & 1) == 1);
    }
  }

  int toInt([int start = 0, int length = 8]) {
    int result = 0;
    for (int i = 0; i < length; i++) {
      result = (result << 1) | (_bits[start + i] ? 1 : 0);
    }
    return result;
  }

  List<bool> toList() => List.from(_bits);

  void _ensureSize(int newSize) {
    if (newSize > _bits.length) {
      _bits.length = newSize;
      for (int i = _bits.length; i < newSize; i++) {
        _bits[i] = false;
      }
    }
  }
}
