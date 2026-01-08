class GaloisField {
  final List<int> expTable;
  final List<int> logTable;
  final int size;
  final int primitive;
  final int generatorBase;

  GaloisField._internal(this.primitive, this.size, this.generatorBase)
      : expTable = List.filled(size, 0),
        logTable = List.filled(size, 0) {
    int x = 1;
    for (int i = 0; i < size; i++) {
      expTable[i] = x;
      x = (x << 1) ^ (x >= size ? primitive : 0);
      x &= size - 1;
    }
    for (int i = 0; i < size - 1; i++) {
      logTable[expTable[i]] = i;
    }
  }

  static final GaloisField qrField = GaloisField._internal(0x011D, 256, 0); // QR-specific GF(256)

  int addOrSubtract(int a, int b) => a ^ b;

  int exp(int a) => expTable[a];

  int log(int a) {
    if (a == 0) throw ArgumentError('Cannot take log of 0');
    return logTable[a];
  }

  int inverse(int a) {
    if (a == 0) throw ArgumentError('Cannot invert 0');
    return expTable[size - logTable[a] - 1];
  }

  int multiply(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return expTable[(logTable[a] + logTable[b]) % (size - 1)];
  }
}
