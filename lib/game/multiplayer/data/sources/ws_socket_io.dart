// Mobile/Desktop (dart:io) implementation
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel socketConnect(
    Uri uri, {
      Map<String, dynamic>? headers,
    }) {
  return IOWebSocketChannel.connect(uri, headers: headers);
}
