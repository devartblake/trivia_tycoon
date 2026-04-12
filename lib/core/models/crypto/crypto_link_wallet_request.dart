import 'crypto_network.dart';

class CryptoLinkWalletRequest {
  const CryptoLinkWalletRequest({
    required this.playerId,
    required this.walletAddress,
    this.network = CryptoNetwork.solana,
  });

  final String playerId;
  final String walletAddress;
  final CryptoNetwork network;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'walletAddress': walletAddress,
      'network': network.key,
    };
  }
}
