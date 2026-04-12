import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_network.dart';
import 'package:trivia_tycoon/core/utils/crypto_address_validator.dart';

void main() {
  test('accepts valid solana addresses', () {
    expect(
      CryptoAddressValidator.isValid(
        '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        CryptoNetwork.solana,
      ),
      isTrue,
    );
  });

  test('rejects invalid solana addresses', () {
    expect(
      CryptoAddressValidator.isValid(
        'invalid-solana-address',
        CryptoNetwork.solana,
      ),
      isFalse,
    );
  });

  test('accepts valid xrp addresses', () {
    expect(
      CryptoAddressValidator.isValid(
        'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh',
        CryptoNetwork.xrp,
      ),
      isTrue,
    );
  });

  test('accepts valid shib addresses', () {
    expect(
      CryptoAddressValidator.isValid(
        '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        CryptoNetwork.shib,
      ),
      isTrue,
    );
  });

  test('returns network-specific validation messages', () {
    expect(
      CryptoAddressValidator.validationMessage(
        'bad-address',
        CryptoNetwork.xrp,
      ),
      'Enter a valid XRP wallet address starting with r.',
    );
  });
}
