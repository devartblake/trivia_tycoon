import 'crypto_network.dart';

class CryptoWithdrawRequest {
  const CryptoWithdrawRequest({
    required this.playerId,
    required this.units,
    required this.toWalletAddress,
    this.network = CryptoNetwork.solana,
  });

  final String playerId;
  final int units;
  final String toWalletAddress;
  final CryptoNetwork network;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'units': units,
      'toWalletAddress': toWalletAddress,
      'network': network.key,
    };
  }
}
