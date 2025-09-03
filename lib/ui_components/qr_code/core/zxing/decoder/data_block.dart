class DataBlock {
  final List<int> codewords;

  DataBlock(this.codewords);

  static DataBlock fromRawCodewords(List<int> rawCodewords) {
    // For Version 1–3, EC Level M: all codewords are part of a single block
    return DataBlock(rawCodewords);
  }
}
