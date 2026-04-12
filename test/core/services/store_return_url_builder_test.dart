import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/env.dart';
import 'package:trivia_tycoon/core/services/store/store_return_url_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EnvConfig.load();
  });

  group('StoreReturnUrlBuilder', () {
    test('builds Stripe one-time purchase success and cancel URLs', () {
      final success = StoreReturnUrlBuilder.checkoutSuccess(
        provider: 'stripe',
        sku: 'powerup:skip',
        quantity: 1,
      );
      final cancel = StoreReturnUrlBuilder.checkoutCancel(
        provider: 'stripe',
        sku: 'powerup:skip',
      );

      expect(
        success,
        'https://app.synaptixgame.com/store/payment-return?provider=stripe&flow=purchase&status=success&sku=powerup%3Askip&quantity=1',
      );
      expect(
        cancel,
        'https://app.synaptixgame.com/store/payment-return?provider=stripe&flow=purchase&status=cancel&sku=powerup%3Askip',
      );
    });

    test('builds PayPal one-time purchase success and cancel URLs', () {
      final success = StoreReturnUrlBuilder.checkoutSuccess(
        provider: 'paypal',
        sku: 'powerup:skip',
        quantity: 2,
      );
      final cancel = StoreReturnUrlBuilder.checkoutCancel(
        provider: 'paypal',
        sku: 'powerup:skip',
      );

      expect(
        success,
        'https://app.synaptixgame.com/store/payment-return?provider=paypal&flow=purchase&status=success&sku=powerup%3Askip&quantity=2',
      );
      expect(
        cancel,
        'https://app.synaptixgame.com/store/payment-return?provider=paypal&flow=purchase&status=cancel&sku=powerup%3Askip',
      );
    });

    test('builds Stripe subscription success and cancel URLs', () {
      final success = StoreReturnUrlBuilder.subscriptionSuccess(
        provider: 'stripe',
        tier: 'premium',
        billingPeriod: 'monthly',
      );
      final cancel = StoreReturnUrlBuilder.subscriptionCancel(
        provider: 'stripe',
        tier: 'premium',
        billingPeriod: 'monthly',
      );

      expect(
        success,
        'https://app.synaptixgame.com/store/subscription-return?provider=stripe&status=success&tier=premium&billingPeriod=monthly',
      );
      expect(
        cancel,
        'https://app.synaptixgame.com/store/subscription-return?provider=stripe&status=cancel&tier=premium&billingPeriod=monthly',
      );
    });

    test('builds PayPal subscription success and cancel URLs', () {
      final success = StoreReturnUrlBuilder.subscriptionSuccess(
        provider: 'paypal',
        tier: 'elite',
        billingPeriod: 'seasonal',
      );
      final cancel = StoreReturnUrlBuilder.subscriptionCancel(
        provider: 'paypal',
        tier: 'elite',
        billingPeriod: 'seasonal',
      );

      expect(
        success,
        'https://app.synaptixgame.com/store/subscription-return?provider=paypal&status=success&tier=elite&billingPeriod=seasonal',
      );
      expect(
        cancel,
        'https://app.synaptixgame.com/store/subscription-return?provider=paypal&status=cancel&tier=elite&billingPeriod=seasonal',
      );
    });
  });
}
