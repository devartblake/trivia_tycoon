import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/service_api.dart';
import 'package:trivia_tycoon/core/networking/grpc/grpc_channel_manager.dart';
import 'package:trivia_tycoon/core/networking/grpc/grpc_auth_interceptor.dart';
import 'package:trivia_tycoon/core/networking/grpc/grpc_match_client.dart';
import 'package:trivia_tycoon/core/services/grpc_match_service.dart';
import 'package:trivia_tycoon/game/providers/core_providers.dart';

// ---------------------------------------------------------------------------
// Channel (singleton)
// ---------------------------------------------------------------------------

/// The gRPC channel connecting to the backend MobileMatchService (port 5001).
final grpcChannelProvider = Provider<ClientChannel>((ref) {
  return GrpcChannelManager.instance.channel;
});

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

/// Low-level typed stub wrapper — prefer using [grpcMatchServiceProvider]
/// in application code.
final grpcMatchClientProvider = Provider<GrpcMatchClient>((ref) {
  final channel = ref.watch(grpcChannelProvider);
  final tokenStore = ref.watch(authTokenStoreProvider);
  return GrpcMatchClient(
    channel,
    interceptors: [GrpcAuthInterceptor(tokenStore)],
  );
});

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// High-level business-logic façade used by controllers and screens.
final grpcMatchServiceProvider = Provider<GrpcMatchService>((ref) {
  final client = ref.watch(grpcMatchClientProvider);
  return GrpcMatchService(client);
});
