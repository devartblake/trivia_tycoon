enum CryptoNetwork {
  solana(
    key: 'solana',
    symbol: 'SOL',
    displayName: 'Solana',
    isPhaseOne: true,
  ),
  xrp(
    key: 'xrp',
    symbol: 'XRP',
    displayName: 'XRP',
    isPhaseOne: true,
  ),
  snx(
    key: 'snx',
    symbol: 'SNX',
    displayName: 'Synaptix Coin',
    isPhaseOne: false,
  ),
  shib(
    key: 'shib',
    symbol: 'SHIB',
    displayName: 'Shiba Inu',
    isPhaseOne: false,
  );

  const CryptoNetwork({
    required this.key,
    required this.symbol,
    required this.displayName,
    required this.isPhaseOne,
  });

  final String key;
  final String symbol;
  final String displayName;
  final bool isPhaseOne;

  static CryptoNetwork fromKey(String value) {
    return tryParse(value) ?? CryptoNetwork.solana;
  }

  static CryptoNetwork? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim().toLowerCase();
    for (final network in CryptoNetwork.values) {
      if (network.key == normalized) {
        return network;
      }
    }
    return null;
  }

  static List<CryptoNetwork> phaseOneNetworks() {
    return CryptoNetwork.values
        .where((network) => network.isPhaseOne)
        .toList(growable: false);
  }
}
