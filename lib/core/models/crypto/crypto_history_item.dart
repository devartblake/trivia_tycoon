import 'crypto_transaction_kind.dart';
import 'crypto_transaction_status.dart';

class CryptoHistoryItem {
  const CryptoHistoryItem({
    required this.transactionId,
    required this.kind,
    required this.unitsDelta,
    required this.status,
    this.receiptRef,
    this.createdAtUtc,
    this.completedAtUtc,
  });

  final String transactionId;
  final CryptoTransactionKind kind;
  final int unitsDelta;
  final CryptoTransactionStatus status;
  final String? receiptRef;
  final DateTime? createdAtUtc;
  final DateTime? completedAtUtc;

  bool get isPending => status.isPending;

  factory CryptoHistoryItem.fromJson(Map<String, dynamic> json) {
    return CryptoHistoryItem(
      transactionId: json['transactionId']?.toString() ?? '',
      kind: CryptoTransactionKind.fromApiValue(json['kind']?.toString()),
      unitsDelta: (json['unitsDelta'] as num?)?.toInt() ?? 0,
      status: CryptoTransactionStatus.fromApiValue(json['status']?.toString()),
      receiptRef: json['receiptRef']?.toString(),
      createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? ''),
      completedAtUtc:
          DateTime.tryParse(json['completedAtUtc']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'kind': kind.apiValue,
      'unitsDelta': unitsDelta,
      'status': status.apiValue,
      'receiptRef': receiptRef,
      'createdAtUtc': createdAtUtc?.toIso8601String(),
      'completedAtUtc': completedAtUtc?.toIso8601String(),
    };
  }
}
