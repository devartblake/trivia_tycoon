import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:trivia_tycoon/core/networking/grpc/grpc_channel_manager.dart';
import 'package:trivia_tycoon/core/networking/grpc/grpc_auth_interceptor.dart';
import 'package:trivia_tycoon/core/networking/grpc/grpc_match_client.dart';
import 'package:trivia_tycoon/core/services/grpc_match_service.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';

// ---------------------------------------------------------------------------
// Channel (singleton)
// ---------------------------------------------------------------------------

/// The gRPC channel connecting to the backend MobileMatchService (port 5001).
/// Includes [GrpcAuthInterceptor] so every call carries the Bearer JWT.
final grpcChannelProvider = Provider<ClientChannelBase>((ref) {
  final tokenStore = ref.watch(authTokenStoreProvider);
  final base = GrpcChannelManager.instance.channel;
  return base.intercept(GrpcAuthInterceptor(tokenStore));
});

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

/// Low-level typed stub wrapper — prefer using [grpcMatchServiceProvider]
/// in application code.
final grpcMatchClientProvider = Provider<GrpcMatchClient>((ref) {
  final channel = ref.watch(grpcChannelProvider);
  return GrpcMatchClient(channel);
});

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// High-level business-logic façade used by controllers and screens.
final grpcMatchServiceProvider = Provider<GrpcMatchService>((ref) {
  final client = ref.watch(grpcMatchClientProvider);
  return GrpcMatchService(client);
});
