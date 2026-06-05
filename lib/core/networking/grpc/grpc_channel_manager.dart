import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_web.dart';
import 'package:trivia_tycoon/core/env.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Manages the singleton gRPC channel connecting to the backend
/// MobileMatchService on port 5001 (HTTP/2).
///
/// Platform handling:
///   Mobile/Desktop → [ClientChannel]  (native HTTP/2)
///   Web            → [GrpcWebClientChannel] (gRPC-Web via XHR)
///
/// Configuration (from EnvConfig / .env):
///   GRPC_HOST       host of the backend (default: same host as API)
///   GRPC_PORT       port (default: 5001)
///   GRPC_USE_TLS    "true" to use TLS (default: false for local dev)
class GrpcChannelManager {
  static GrpcChannelManager? _instance;
  ClientChannelBase? _channel;

  GrpcChannelManager._();

  static GrpcChannelManager get instance =>
      _instance ??= GrpcChannelManager._();

  /// Returns (or lazily creates) the gRPC channel.
  ClientChannelBase get channel {
    _channel ??= _buildChannel();
    return _channel!;
  }

  /// Closes the current channel. The next access to [channel] re-opens it.
  Future<void> dispose() async {
    final c = _channel;
    _channel = null;
    if (c != null) {
      await c.shutdown();
      LogManager.info('[GrpcChannelManager] Channel shut down.');
    }
  }

  ClientChannelBase _buildChannel() {
    final host   = EnvConfig.grpcHost;
    final port   = EnvConfig.grpcPort;
    final useTls = EnvConfig.grpcUseTls;

    LogManager.info(
      '[GrpcChannelManager] Opening channel → $host:$port '
      '(tls=$useTls, web=$kIsWeb)',
    );

    if (kIsWeb) {
      final scheme = useTls ? 'https' : 'http';
      return GrpcWebClientChannel.xhr(Uri.parse('$scheme://$host:$port'));
    }

    return ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: useTls
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
        idleTimeout: const Duration(minutes(5)),
        connectionTimeout: const Duration(seconds: 10),
      ),
    );
  }
}
