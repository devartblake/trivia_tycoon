class StoreLinkRouter {
  static const _supportedHost = 'app.synaptixgame.com';

  static bool isSupportedStoreReturn(Uri uri) {
    final isHttp = uri.scheme == 'https' || uri.scheme == 'http';
    if (!isHttp) return false;
    if (uri.host.toLowerCase() != _supportedHost) return false;

    final path = uri.path;
    return path == '/store/payment-return' ||
        path == '/store/subscription-return';
  }

  static String? toAppLocation(Uri uri) {
    if (!isSupportedStoreReturn(uri)) {
      return null;
    }

    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '${uri.path}$query';
  }
}
