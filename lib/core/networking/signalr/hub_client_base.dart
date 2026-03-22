import 'package:signalr_netcore/signalr_client.dart';

/// Base class for SignalR hub connections.
///
/// Wraps [HubConnection] to provide a consistent connect/disconnect/invoke
/// interface and exposes the connection state.
abstract class HubClientBase {
  HubConnection? _connection;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  HubConnectionState? get state => _connection?.state;

  /// Starts a hub connection to [url] authenticated with [accessToken].
  ///
  /// Calling [start] when already connected is a no-op.
  Future<void> start({
    required String url,
    required String accessToken,
  }) async {
    if (isConnected) return;

    _connection = HubConnectionBuilder()
        .withUrl(
      url,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => accessToken,
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      ),
    )
        .withAutomaticReconnect()
        .build();

    registerHandlers(_connection!);
    await _connection!.start();
  }

  /// Stops the hub connection.
  Future<void> stop() async {
    await _connection?.stop();
    _connection = null;
  }

  /// Invokes a server-side hub method with optional arguments.
  Future<void> invoke(String method, {List<Object> args = const []}) async {
    if (!isConnected) return;
    await _connection!.invoke(method, args: args);
  }

  /// Registers event listeners on [connection].
  ///
  /// Subclasses implement this to call [connection.on] for each server event.
  void registerHandlers(HubConnection connection);
}
