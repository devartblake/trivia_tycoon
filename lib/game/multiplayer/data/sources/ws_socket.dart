// Public adapter API — chooses the right implementation per platform.
//
// Usage from WsClient:
//   final ch = socketConnect(uri, headers: headers);
//   _socket = ch; // WebSocketChannel
//
// Notes:
// - Web: most browsers ignore custom headers. Pass auth via query params or a cookie.
// - IO: headers are supported.

import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

// Conditional imports select the right `socketConnect` implementation
// at compile time.
import 'ws_socket_html.dart'
if (dart.library.io) 'ws_socket_io.dart' as impl;

WebSocketChannel socketConnect(
    Uri uri, {
      Map<String, dynamic>? headers,
    }) =>
    impl.socketConnect(uri, headers: headers);
