import 'dart:math';

class ReferralCodeGen {
  // Crockford base32 alphabet without confusing chars
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static final _rng = Random.secure();

  /// 8 chars ~ 40 bits of entropy (1e12 space). Adjust length as needed.
  static String generate({int length = 8}) {
    final codeChars = List.generate(length, (_) => _alphabet[_rng.nextInt(_alphabet.length)]);
    return 'RC${String.fromCharCodes(codeChars as Iterable<int>)}';
  }
}