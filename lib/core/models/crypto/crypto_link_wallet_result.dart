import 'crypto_network.dart';

class CryptoLinkWalletResult {
  const CryptoLinkWalletResult({
    required this.playerId,
    required this.walletAddress,
    required this.network,
    required this.transactionId,
    required this.status,
  });

  final String playerId;
  final String walletAddress;
  final CryptoNetwork network;
  final String transactionId;
  final String status;

  factory CryptoLinkWalletResult.fromJson(Map<String, dynamic> json) {
    return CryptoLinkWalletResult(
      playerId: json['playerId']?.toString() ?? '',
      walletAddress: json['walletAddress']?.toString() ?? '',
      network: CryptoNetwork.fromKey(json['network']?.toString() ?? 'solana'),
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
