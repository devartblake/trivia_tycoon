//
//  Generated code. Do not modify.
//  source: mobile.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mobile.pb.dart' as $0;

export 'mobile.pb.dart';

@$pb.GrpcServiceName('tycoon.mobile.MobileMatchService')
class MobileMatchServiceClient extends $grpc.Client {
  static final _$startMatch =
      $grpc.ClientMethod<$0.GrpcStartMatchRequest, $0.GrpcStartMatchResponse>(
          '/tycoon.mobile.MobileMatchService/StartMatch',
          ($0.GrpcStartMatchRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.GrpcStartMatchResponse.fromBuffer(value));
  static final _$submitMatch =
      $grpc.ClientMethod<$0.GrpcSubmitMatchRequest, $0.GrpcSubmitMatchResponse>(
          '/tycoon.mobile.MobileMatchService/SubmitMatch',
          ($0.GrpcSubmitMatchRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.GrpcSubmitMatchResponse.fromBuffer(value));
  static final _$playMatch = $grpc.ClientMethod<$0.PlayerAction, $0.MatchEvent>(
      '/tycoon.mobile.MobileMatchService/PlayMatch',
      ($0.PlayerAction value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.MatchEvent.fromBuffer(value));
  static final _$watchLeaderboard =
      $grpc.ClientMethod<$0.LeaderboardWatchRequest, $0.LeaderboardUpdate>(
          '/tycoon.mobile.MobileMatchService/WatchLeaderboard',
          ($0.LeaderboardWatchRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.LeaderboardUpdate.fromBuffer(value));
  static final _$watchMatchmaking = $grpc.ClientMethod<
          $0.WatchMatchmakingRequest, $0.MatchmakingStatusUpdate>(
      '/tycoon.mobile.MobileMatchService/WatchMatchmaking',
      ($0.WatchMatchmakingRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.MatchmakingStatusUpdate.fromBuffer(value));
  static final _$cancelMatchmaking = $grpc.ClientMethod<
          $0.CancelMatchmakingRequest, $0.CancelMatchmakingResponse>(
      '/tycoon.mobile.MobileMatchService/CancelMatchmaking',
      ($0.CancelMatchmakingRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.CancelMatchmakingResponse.fromBuffer(value));

  MobileMatchServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.GrpcStartMatchResponse> startMatch(
      $0.GrpcStartMatchRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$startMatch, request, options: options);
  }

  $grpc.ResponseFuture<$0.GrpcSubmitMatchResponse> submitMatch(
      $0.GrpcSubmitMatchRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$submitMatch, request, options: options);
  }

  $grpc.ResponseStream<$0.MatchEvent> playMatch(
      $async.Stream<$0.PlayerAction> request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$playMatch, request, options: options);
  }

  $grpc.ResponseStream<$0.LeaderboardUpdate> watchLeaderboard(
      $0.LeaderboardWatchRequest request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$watchLeaderboard, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.MatchmakingStatusUpdate> watchMatchmaking(
      $0.WatchMatchmakingRequest request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$watchMatchmaking, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.CancelMatchmakingResponse> cancelMatchmaking(
      $0.CancelMatchmakingRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$cancelMatchmaking, request, options: options);
  }
}

@$pb.GrpcServiceName('tycoon.mobile.MobileMatchService')
abstract class MobileMatchServiceBase extends $grpc.Service {
  $core.String get $name => 'tycoon.mobile.MobileMatchService';

  MobileMatchServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GrpcStartMatchRequest,
            $0.GrpcStartMatchResponse>(
        'StartMatch',
        startMatch_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GrpcStartMatchRequest.fromBuffer(value),
        ($0.GrpcStartMatchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GrpcSubmitMatchRequest,
            $0.GrpcSubmitMatchResponse>(
        'SubmitMatch',
        submitMatch_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GrpcSubmitMatchRequest.fromBuffer(value),
        ($0.GrpcSubmitMatchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PlayerAction, $0.MatchEvent>(
        'PlayMatch',
        playMatch,
        true,
        true,
        ($core.List<$core.int> value) => $0.PlayerAction.fromBuffer(value),
        ($0.MatchEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.LeaderboardWatchRequest, $0.LeaderboardUpdate>(
            'WatchLeaderboard',
            watchLeaderboard_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.LeaderboardWatchRequest.fromBuffer(value),
            ($0.LeaderboardUpdate value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchMatchmakingRequest,
            $0.MatchmakingStatusUpdate>(
        'WatchMatchmaking',
        watchMatchmaking_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchMatchmakingRequest.fromBuffer(value),
        ($0.MatchmakingStatusUpdate value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelMatchmakingRequest,
            $0.CancelMatchmakingResponse>(
        'CancelMatchmaking',
        cancelMatchmaking_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CancelMatchmakingRequest.fromBuffer(value),
        ($0.CancelMatchmakingResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GrpcStartMatchResponse> startMatch_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.GrpcStartMatchRequest> request) async {
    return startMatch(call, await request);
  }

  $async.Future<$0.GrpcSubmitMatchResponse> submitMatch_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.GrpcSubmitMatchRequest> request) async {
    return submitMatch(call, await request);
  }

  $async.Stream<$0.LeaderboardUpdate> watchLeaderboard_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.LeaderboardWatchRequest> request) async* {
    yield* watchLeaderboard(call, await request);
  }

  $async.Stream<$0.MatchmakingStatusUpdate> watchMatchmaking_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.WatchMatchmakingRequest> request) async* {
    yield* watchMatchmaking(call, await request);
  }

  $async.Future<$0.CancelMatchmakingResponse> cancelMatchmaking_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.CancelMatchmakingRequest> request) async {
    return cancelMatchmaking(call, await request);
  }

  $async.Future<$0.GrpcStartMatchResponse> startMatch(
      $grpc.ServiceCall call, $0.GrpcStartMatchRequest request);
  $async.Future<$0.GrpcSubmitMatchResponse> submitMatch(
      $grpc.ServiceCall call, $0.GrpcSubmitMatchRequest request);
  $async.Stream<$0.MatchEvent> playMatch(
      $grpc.ServiceCall call, $async.Stream<$0.PlayerAction> request);
  $async.Stream<$0.LeaderboardUpdate> watchLeaderboard(
      $grpc.ServiceCall call, $0.LeaderboardWatchRequest request);
  $async.Stream<$0.MatchmakingStatusUpdate> watchMatchmaking(
      $grpc.ServiceCall call, $0.WatchMatchmakingRequest request);
  $async.Future<$0.CancelMatchmakingResponse> cancelMatchmaking(
      $grpc.ServiceCall call, $0.CancelMatchmakingRequest request);
}
