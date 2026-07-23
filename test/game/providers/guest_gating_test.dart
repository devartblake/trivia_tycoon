import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/providers/auth_providers.dart';

class _FakeIdentity extends PlayerIdentityNotifier {
  _FakeIdentity(Ref ref, PlayerIdentityKind kind) : super(ref) {
    state = PlayerIdentityState(isReady: true, kind: kind);
  }
}

ProviderContainer _containerFor(PlayerIdentityKind kind) {
  final c = ProviderContainer(overrides: [
    playerIdentityProvider.overrideWith((ref) => _FakeIdentity(ref, kind)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('guest gating providers', () {
    test('anonymous device-guest is a guest and not upgraded', () {
      final c = _containerFor(PlayerIdentityKind.anonymousDevice);
      expect(c.read(isGuestProvider), isTrue);
      expect(c.read(hasUpgradedAccountProvider), isFalse);
    });

    test('full account is not a guest and is upgraded', () {
      final c = _containerFor(PlayerIdentityKind.fullAccount);
      expect(c.read(isGuestProvider), isFalse);
      expect(c.read(hasUpgradedAccountProvider), isTrue);
    });

    test('platform-linked is not a guest and is upgraded', () {
      final c = _containerFor(PlayerIdentityKind.platformLinked);
      expect(c.read(isGuestProvider), isFalse);
      expect(c.read(hasUpgradedAccountProvider), isTrue);
    });

    test('unresolved identity is not upgraded (gated like a guest)', () {
      final c = _containerFor(PlayerIdentityKind.unresolved);
      expect(c.read(hasUpgradedAccountProvider), isFalse);
    });
  });
}
