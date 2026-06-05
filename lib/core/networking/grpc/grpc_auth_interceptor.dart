import 'package:grpc/grpc.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';

/// Injects the Bearer JWT into every gRPC call (both unary and streaming).
/// Attach to the channel via [ClientChannel.intercept] so that streaming RPCs
/// (PlayMatch, WatchLeaderboard, WatchMatchmaking) also carry the token.
class GrpcAuthInterceptor implements ClientInterceptor {
  final AuthTokenStore _tokenStore;

  const GrpcAuthInterceptor(this._tokenStore);

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) =>
      invoker(method, request, _mergeAuth(options));

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) =>
      invoker(method, requests, _mergeAuth(options));

  CallOptions _mergeAuth(CallOptions options) {
    final token = _tokenStore.accessTokenSync;
    if (token == null || token.isEmpty) return options;
    return options.mergedWith(
      CallOptions(metadata: {'authorization': 'Bearer $token'}),
    );
  }
}
