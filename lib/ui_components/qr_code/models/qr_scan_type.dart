enum QrScanType {
  url,
  userId,
  json,
  plainText,
  unknown,
}

QrScanType detectQrType(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return QrScanType.url;
  }
  if (RegExp(r'^user_\d+$').hasMatch(trimmed)) {
    return QrScanType.userId;
  }
  if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
    return QrScanType.json;
  }
  if (trimmed.isNotEmpty) {
    return QrScanType.plainText;
  }
  return QrScanType.unknown;
}
