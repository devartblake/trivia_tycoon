class DecodedBitStreamParser {
  final List<int> bytes;
  late final _BitStreamReader _reader;

  DecodedBitStreamParser(this.bytes) {
    _reader = _BitStreamReader(bytes);
  }

  String parse() {
    final buffer = StringBuffer();

    while (_reader.hasBits(4)) {
      final modeBits = _reader.readBits(4);
      if (modeBits == 0) break; // end of data

      switch (modeBits) {
        case 0x1: // Numeric
          final count = _readCharCount(modeBits);
          buffer.write(_readNumeric(count));
          break;
        case 0x2: // Alphanumeric
          final count = _readCharCount(modeBits);
          buffer.write(_readAlphanumeric(count));
          break;
        case 0x4: // Byte mode
          final count = _readCharCount(modeBits);
          buffer.write(_readByte(count));
          break;
        default:
        // For now, skip unsupported modes like Kanji/ECI
          return '[Unsupported mode: $modeBits]';
      }
    }

    return buffer.toString();
  }

  int _readCharCount(int mode) {
    // Temporary: default version assumption
    switch (mode) {
      case 0x1:
        return _reader.readBits(10); // Numeric
      case 0x2:
        return _reader.readBits(9); // Alphanumeric
      case 0x4:
        return _reader.readBits(8); // Byte
      default:
        return 0;
    }
  }

  String _readNumeric(int count) {
    final buffer = StringBuffer();
    while (count >= 3) {
      final group = _reader.readBits(10);
      buffer.write(group.toString().padLeft(3, '0'));
      count -= 3;
    }
    if (count == 2) {
      final group = _reader.readBits(7);
      buffer.write(group.toString().padLeft(2, '0'));
    } else if (count == 1) {
      final group = _reader.readBits(4);
      buffer.write(group.toString());
    }
    return buffer.toString();
  }

  static const _alphanumericTable = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:';

  String _readAlphanumeric(int count) {
    final buffer = StringBuffer();
    while (count >= 2) {
      final v = _reader.readBits(11);
      buffer.write(_alphanumericTable[v ~/ 45]);
      buffer.write(_alphanumericTable[v % 45]);
      count -= 2;
    }
    if (count == 1) {
      final v = _reader.readBits(6);
      buffer.write(_alphanumericTable[v]);
    }
    return buffer.toString();
  }

  String _readByte(int count) {
    final buffer = StringBuffer();
    for (int i = 0; i < count; i++) {
      final b = _reader.readBits(8);
      buffer.writeCharCode(b); // ASCII for now
    }
    return buffer.toString();
  }
}

class _BitStreamReader {
  final List<int> bytes;
  int byteOffset = 0;
  int bitOffset = 0;

  _BitStreamReader(this.bytes);

  bool hasBits(int count) {
    final bitsLeft = (bytes.length - byteOffset) * 8 - bitOffset;
    return bitsLeft >= count;
  }

  int readBits(int count) {
    int result = 0;
    while (count > 0) {
      final availableBits = 8 - bitOffset;
      final toRead = count < availableBits ? count : availableBits;
      final mask = (0xFF >> bitOffset) & (0xFF << (8 - (bitOffset + toRead)));
      final bits = (bytes[byteOffset] & mask) >> (8 - (bitOffset + toRead));

      result = (result << toRead) | bits;
      bitOffset += toRead;
      count -= toRead;

      if (bitOffset == 8) {
        byteOffset++;
        bitOffset = 0;
      }
    }
    return result;
  }
}
