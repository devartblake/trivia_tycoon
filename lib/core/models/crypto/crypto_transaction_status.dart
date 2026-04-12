enum CryptoTransactionStatus {
  pending(
    apiValue: 'Pending',
    displayLabel: 'Pending',
  ),
  applied(
    apiValue: 'Applied',
    displayLabel: 'Applied',
  ),
  failed(
    apiValue: 'Failed',
    displayLabel: 'Failed',
  ),
  reversed(
    apiValue: 'Reversed',
    displayLabel: 'Reversed',
  ),
  unknown(
    apiValue: 'Unknown',
    displayLabel: 'Unknown',
  );

  const CryptoTransactionStatus({
    required this.apiValue,
    required this.displayLabel,
  });

  final String apiValue;
  final String displayLabel;

  bool get isPending => this == CryptoTransactionStatus.pending;

  static CryptoTransactionStatus fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CryptoTransactionStatus.unknown;
    }

    final normalized = value.trim().toLowerCase();
    for (final status in CryptoTransactionStatus.values) {
      if (status.apiValue.toLowerCase() == normalized) {
        return status;
      }
    }
    return CryptoTransactionStatus.unknown;
  }
}
