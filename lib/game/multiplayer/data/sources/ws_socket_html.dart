// Web implementation
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel socketConnect(
    Uri uri, {
      Map<String, dynamic>? headers,
    }) {
  // Browsers generally ignore custom headers. If you need auth, put it in
  // the query string (e.g., ?token=...) or rely on cookies.
  return HtmlWebSocketChannel.connect(uri.toString());
}
