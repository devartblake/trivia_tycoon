import 'crypto_network.dart';

class CryptoWithdrawResult {
  const CryptoWithdrawResult({
    required this.transactionId,
    required this.status,
    required this.units,
    required this.network,
  });

  final String transactionId;
  final String status;
  final int units;
  final CryptoNetwork network;

  factory CryptoWithdrawResult.fromJson(Map<String, dynamic> json) {
    return CryptoWithdrawResult(
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      units: (json['units'] as num?)?.toInt() ?? 0,
      network: CryptoNetwork.fromKey(json['network']?.toString() ?? 'solana'),
    );
  }
}
