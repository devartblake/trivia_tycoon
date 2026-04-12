import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/store/store_link_router.dart';

void main() {
  group('StoreLinkRouter', () {
    test('accepts payment return links for the configured app domain', () {
      final uri = Uri.parse(
        'https://app.synaptixgame.com/store/payment-return?provider=stripe&status=success&sku=powerup%3Askip',
      );

      expect(StoreLinkRouter.isSupportedStoreReturn(uri), isTrue);
      expect(
        StoreLinkRouter.toAppLocation(uri),
        '/store/payment-return?provider=stripe&status=success&sku=powerup%3Askip',
      );
    });

    test('accepts subscription return links for the configured app domain', () {
      final uri = Uri.parse(
        'https://app.synaptixgame.com/store/subscription-return?provider=paypal&status=success&tier=elite&billingPeriod=seasonal',
      );

      expect(StoreLinkRouter.isSupportedStoreReturn(uri), isTrue);
      expect(
        StoreLinkRouter.toAppLocation(uri),
        '/store/subscription-return?provider=paypal&status=success&tier=elite&billingPeriod=seasonal',
      );
    });

    test('rejects unrelated domains', () {
      final uri = Uri.parse(
        'https://example.com/store/payment-return?provider=stripe&status=success',
      );

      expect(StoreLinkRouter.isSupportedStoreReturn(uri), isFalse);
      expect(StoreLinkRouter.toAppLocation(uri), isNull);
    });

    test('rejects unrelated paths on the same domain', () {
      final uri = Uri.parse(
        'https://app.synaptixgame.com/profile?tab=wallet',
      );

      expect(StoreLinkRouter.isSupportedStoreReturn(uri), isFalse);
      expect(StoreLinkRouter.toAppLocation(uri), isNull);
    });
  });
}
