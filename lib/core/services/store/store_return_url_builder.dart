import '../../env.dart';

class StoreReturnUrlBuilder {
  static String? checkoutSuccess({
    required String provider,
    required String sku,
    required int quantity,
  }) {
    return _build(
      '/store/payment-return',
      queryParameters: {
        'provider': provider,
        'flow': 'purchase',
        'status': 'success',
        'sku': sku,
        'quantity': quantity.toString(),
      },
    );
  }

  static String? checkoutCancel({
    required String provider,
    required String sku,
  }) {
    return _build(
      '/store/payment-return',
      queryParameters: {
        'provider': provider,
        'flow': 'purchase',
        'status': 'cancel',
        'sku': sku,
      },
    );
  }

  static String? subscriptionSuccess({
    required String provider,
    required String tier,
    required String billingPeriod,
  }) {
    return _build(
      '/store/subscription-return',
      queryParameters: {
        'provider': provider,
        'status': 'success',
        'tier': tier,
        'billingPeriod': billingPeriod,
      },
    );
  }

  static String? subscriptionCancel({
    required String provider,
    required String tier,
    required String billingPeriod,
  }) {
    return _build(
      '/store/subscription-return',
      queryParameters: {
        'provider': provider,
        'status': 'cancel',
        'tier': tier,
        'billingPeriod': billingPeriod,
      },
    );
  }

  static String? _build(
    String path, {
    required Map<String, String> queryParameters,
  }) {
    final base = EnvConfig.appRedirectBaseUrl;
    if (base == null || base.isEmpty) {
      return null;
    }

    final uri = Uri.parse(base);
    final segments = [
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
      ...Uri.parse(path).pathSegments.where((segment) => segment.isNotEmpty),
    ];

    return uri.replace(
      pathSegments: segments,
      queryParameters: queryParameters,
      fragment: '',
    ).toString();
  }
}
