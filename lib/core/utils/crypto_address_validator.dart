import '../models/crypto/crypto_network.dart';

class CryptoAddressValidator {
  static final RegExp _hexAddressPattern = RegExp(r'^0x[0-9a-fA-F]{40}$');
  static const String _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static bool isValid(String address, CryptoNetwork network) {
    final value = address.trim();
    if (value.isEmpty) {
      return false;
    }

    switch (network) {
      case CryptoNetwork.solana:
      case CryptoNetwork.snx:
        final decoded = _tryDecodeBase58(value);
        return decoded != null && decoded.length == 32;
      case CryptoNetwork.xrp:
        return value.startsWith('r') &&
            value.length >= 25 &&
            value.length <= 34;
      case CryptoNetwork.shib:
        return _hexAddressPattern.hasMatch(value);
    }
  }

  static String? validationMessage(String address, CryptoNetwork network) {
    if (isValid(address, network)) {
      return null;
    }

    switch (network) {
      case CryptoNetwork.solana:
      case CryptoNetwork.snx:
        return 'Enter a valid base58 wallet address.';
      case CryptoNetwork.xrp:
        return 'Enter a valid XRP wallet address starting with r.';
      case CryptoNetwork.shib:
        return 'Enter a valid 0x Ethereum address.';
    }
  }

  static List<int>? _tryDecodeBase58(String input) {
    BigInt value = BigInt.zero;

    for (final codePoint in input.codeUnits) {
      final character = String.fromCharCode(codePoint);
      final index = _base58Alphabet.indexOf(character);
      if (index < 0) {
        return null;
      }
      value = (value * BigInt.from(58)) + BigInt.from(index);
    }

    final leadingZeroCount = input.runes.takeWhile((rune) => rune == 49).length;
    final bytes = <int>[];
    var remainder = value;
    while (remainder > BigInt.zero) {
      bytes.add((remainder % BigInt.from(256)).toInt());
      remainder = remainder ~/ BigInt.from(256);
    }

    return <int>[
      ...List<int>.filled(leadingZeroCount, 0),
      ...bytes.reversed,
    ];
  }
}
