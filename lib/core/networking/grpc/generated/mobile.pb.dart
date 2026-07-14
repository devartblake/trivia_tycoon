//
//  Generated code. Do not modify.
//  source: mobile.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class GrpcStartMatchRequest extends $pb.GeneratedMessage {
  factory GrpcStartMatchRequest({
    $core.String? hostPlayerId,
    $core.String? mode,
  }) {
    final $result = create();
    if (hostPlayerId != null) {
      $result.hostPlayerId = hostPlayerId;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    return $result;
  }
  GrpcStartMatchRequest._() : super();
  factory GrpcStartMatchRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GrpcStartMatchRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrpcStartMatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostPlayerId')
    ..aOS(2, _omitFieldNames ? '' : 'mode')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GrpcStartMatchRequest clone() =>
      GrpcStartMatchRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GrpcStartMatchRequest copyWith(
          void Function(GrpcStartMatchRequest) updates) =>
      super.copyWith((message) => updates(message as GrpcStartMatchRequest))
          as GrpcStartMatchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrpcStartMatchRequest create() => GrpcStartMatchRequest._();
  GrpcStartMatchRequest createEmptyInstance() => create();
  static $pb.PbList<GrpcStartMatchRequest> createRepeated() =>
      $pb.PbList<GrpcStartMatchRequest>();
  @$core.pragma('dart2js:noInline')
  static GrpcStartMatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrpcStartMatchRequest>(create);
  static GrpcStartMatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostPlayerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostPlayerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get mode => $_getSZ(1);
  @$pb.TagNumber(2)
  set mode($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => clearField(2);
}

class GrpcStartMatchResponse extends $pb.GeneratedMessage {
  factory GrpcStartMatchResponse({
    $core.String? matchId,
    $fixnum.Int64? startedAt,
  }) {
    final $result = create();
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (startedAt != null) {
      $result.startedAt = startedAt;
    }
    return $result;
  }
  GrpcStartMatchResponse._() : super();
  factory GrpcStartMatchResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GrpcStartMatchResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrpcStartMatchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'matchId')
    ..aInt64(2, _omitFieldNames ? '' : 'startedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GrpcStartMatchResponse clone() =>
      GrpcStartMatchResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GrpcStartMatchResponse copyWith(
          void Function(GrpcStartMatchResponse) updates) =>
      super.copyWith((message) => updates(message as GrpcStartMatchResponse))
          as GrpcStartMatchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrpcStartMatchResponse create() => GrpcStartMatchResponse._();
  GrpcStartMatchResponse createEmptyInstance() => create();
  static $pb.PbList<GrpcStartMatchResponse> createRepeated() =>
      $pb.PbList<GrpcStartMatchResponse>();
  @$core.pragma('dart2js:noInline')
  static GrpcStartMatchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrpcStartMatchResponse>(create);
  static GrpcStartMatchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get matchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set matchId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMatchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMatchId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get startedAt => $_getI64(1);
  @$pb.TagNumber(2)
  set startedAt($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStartedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartedAt() => clearField(2);
}

class GrpcSubmitMatchRequest extends $pb.GeneratedMessage {
  factory GrpcSubmitMatchRequest({
    $core.String? eventId,
    $core.String? matchId,
    $core.String? mode,
    $core.String? category,
    $core.int? questionCount,
    $fixnum.Int64? startedAtUtc,
    $fixnum.Int64? endedAtUtc,
    $core.int? status,
    $core.Iterable<ParticipantResult>? participants,
  }) {
    final $result = create();
    if (eventId != null) {
      $result.eventId = eventId;
    }
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    if (category != null) {
      $result.category = category;
    }
    if (questionCount != null) {
      $result.questionCount = questionCount;
    }
    if (startedAtUtc != null) {
      $result.startedAtUtc = startedAtUtc;
    }
    if (endedAtUtc != null) {
      $result.endedAtUtc = endedAtUtc;
    }
    if (status != null) {
      $result.status = status;
    }
    if (participants != null) {
      $result.participants.addAll(participants);
    }
    return $result;
  }
  GrpcSubmitMatchRequest._() : super();
  factory GrpcSubmitMatchRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GrpcSubmitMatchRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrpcSubmitMatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'eventId')
    ..aOS(2, _omitFieldNames ? '' : 'matchId')
    ..aOS(3, _omitFieldNames ? '' : 'mode')
    ..aOS(4, _omitFieldNames ? '' : 'category')
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'questionCount', $pb.PbFieldType.O3)
    ..aInt64(6, _omitFieldNames ? '' : 'startedAtUtc')
    ..aInt64(7, _omitFieldNames ? '' : 'endedAtUtc')
    ..a<$core.int>(8, _omitFieldNames ? '' : 'status', $pb.PbFieldType.O3)
    ..pc<ParticipantResult>(
        9, _omitFieldNames ? '' : 'participants', $pb.PbFieldType.PM,
        subBuilder: ParticipantResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GrpcSubmitMatchRequest clone() =>
      GrpcSubmitMatchRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GrpcSubmitMatchRequest copyWith(
          void Function(GrpcSubmitMatchRequest) updates) =>
      super.copyWith((message) => updates(message as GrpcSubmitMatchRequest))
          as GrpcSubmitMatchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrpcSubmitMatchRequest create() => GrpcSubmitMatchRequest._();
  GrpcSubmitMatchRequest createEmptyInstance() => create();
  static $pb.PbList<GrpcSubmitMatchRequest> createRepeated() =>
      $pb.PbList<GrpcSubmitMatchRequest>();
  @$core.pragma('dart2js:noInline')
  static GrpcSubmitMatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrpcSubmitMatchRequest>(create);
  static GrpcSubmitMatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get eventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get matchId => $_getSZ(1);
  @$pb.TagNumber(2)
  set matchId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMatchId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMatchId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get mode => $_getSZ(2);
  @$pb.TagNumber(3)
  set mode($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get category => $_getSZ(3);
  @$pb.TagNumber(4)
  set category($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCategory() => $_has(3);
  @$pb.TagNumber(4)
  void clearCategory() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get questionCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set questionCount($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasQuestionCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearQuestionCount() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get startedAtUtc => $_getI64(5);
  @$pb.TagNumber(6)
  set startedAtUtc($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasStartedAtUtc() => $_has(5);
  @$pb.TagNumber(6)
  void clearStartedAtUtc() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get endedAtUtc => $_getI64(6);
  @$pb.TagNumber(7)
  set endedAtUtc($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasEndedAtUtc() => $_has(6);
  @$pb.TagNumber(7)
  void clearEndedAtUtc() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get status => $_getIZ(7);
  @$pb.TagNumber(8)
  set status($core.int v) {
    $_setSignedInt32(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => clearField(8);

  @$pb.TagNumber(9)
  $core.List<ParticipantResult> get participants => $_getList(8);
}

class ParticipantResult extends $pb.GeneratedMessage {
  factory ParticipantResult({
    $core.String? playerId,
    $core.int? score,
    $core.int? correct,
    $core.int? wrong,
    $core.double? avgAnswerTimeMs,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (score != null) {
      $result.score = score;
    }
    if (correct != null) {
      $result.correct = correct;
    }
    if (wrong != null) {
      $result.wrong = wrong;
    }
    if (avgAnswerTimeMs != null) {
      $result.avgAnswerTimeMs = avgAnswerTimeMs;
    }
    return $result;
  }
  ParticipantResult._() : super();
  factory ParticipantResult.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantResult.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParticipantResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'score', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'correct', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'wrong', $pb.PbFieldType.O3)
    ..a<$core.double>(
        5, _omitFieldNames ? '' : 'avgAnswerTimeMs', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantResult clone() => ParticipantResult()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantResult copyWith(void Function(ParticipantResult) updates) =>
      super.copyWith((message) => updates(message as ParticipantResult))
          as ParticipantResult;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParticipantResult create() => ParticipantResult._();
  ParticipantResult createEmptyInstance() => create();
  static $pb.PbList<ParticipantResult> createRepeated() =>
      $pb.PbList<ParticipantResult>();
  @$core.pragma('dart2js:noInline')
  static ParticipantResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParticipantResult>(create);
  static ParticipantResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get score => $_getIZ(1);
  @$pb.TagNumber(2)
  set score($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearScore() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get correct => $_getIZ(2);
  @$pb.TagNumber(3)
  set correct($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCorrect() => $_has(2);
  @$pb.TagNumber(3)
  void clearCorrect() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get wrong => $_getIZ(3);
  @$pb.TagNumber(4)
  set wrong($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasWrong() => $_has(3);
  @$pb.TagNumber(4)
  void clearWrong() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get avgAnswerTimeMs => $_getN(4);
  @$pb.TagNumber(5)
  set avgAnswerTimeMs($core.double v) {
    $_setDouble(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAvgAnswerTimeMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvgAnswerTimeMs() => clearField(5);
}

class GrpcSubmitMatchResponse extends $pb.GeneratedMessage {
  factory GrpcSubmitMatchResponse({
    $core.String? eventId,
    $core.String? matchId,
    $core.String? status,
    $core.Iterable<MatchAward>? awards,
  }) {
    final $result = create();
    if (eventId != null) {
      $result.eventId = eventId;
    }
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (status != null) {
      $result.status = status;
    }
    if (awards != null) {
      $result.awards.addAll(awards);
    }
    return $result;
  }
  GrpcSubmitMatchResponse._() : super();
  factory GrpcSubmitMatchResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GrpcSubmitMatchResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrpcSubmitMatchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'eventId')
    ..aOS(2, _omitFieldNames ? '' : 'matchId')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..pc<MatchAward>(4, _omitFieldNames ? '' : 'awards', $pb.PbFieldType.PM,
        subBuilder: MatchAward.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GrpcSubmitMatchResponse clone() =>
      GrpcSubmitMatchResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GrpcSubmitMatchResponse copyWith(
          void Function(GrpcSubmitMatchResponse) updates) =>
      super.copyWith((message) => updates(message as GrpcSubmitMatchResponse))
          as GrpcSubmitMatchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrpcSubmitMatchResponse create() => GrpcSubmitMatchResponse._();
  GrpcSubmitMatchResponse createEmptyInstance() => create();
  static $pb.PbList<GrpcSubmitMatchResponse> createRepeated() =>
      $pb.PbList<GrpcSubmitMatchResponse>();
  @$core.pragma('dart2js:noInline')
  static GrpcSubmitMatchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrpcSubmitMatchResponse>(create);
  static GrpcSubmitMatchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get eventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get matchId => $_getSZ(1);
  @$pb.TagNumber(2)
  set matchId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMatchId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMatchId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<MatchAward> get awards => $_getList(3);
}

class MatchAward extends $pb.GeneratedMessage {
  factory MatchAward({
    $core.String? playerId,
    $core.int? awardedXp,
    $core.int? awardedCoins,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (awardedXp != null) {
      $result.awardedXp = awardedXp;
    }
    if (awardedCoins != null) {
      $result.awardedCoins = awardedCoins;
    }
    return $result;
  }
  MatchAward._() : super();
  factory MatchAward.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MatchAward.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchAward',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'awardedXp', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'awardedCoins', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MatchAward clone() => MatchAward()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MatchAward copyWith(void Function(MatchAward) updates) =>
      super.copyWith((message) => updates(message as MatchAward)) as MatchAward;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchAward create() => MatchAward._();
  MatchAward createEmptyInstance() => create();
  static $pb.PbList<MatchAward> createRepeated() => $pb.PbList<MatchAward>();
  @$core.pragma('dart2js:noInline')
  static MatchAward getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchAward>(create);
  static MatchAward? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get awardedXp => $_getIZ(1);
  @$pb.TagNumber(2)
  set awardedXp($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAwardedXp() => $_has(1);
  @$pb.TagNumber(2)
  void clearAwardedXp() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get awardedCoins => $_getIZ(2);
  @$pb.TagNumber(3)
  set awardedCoins($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAwardedCoins() => $_has(2);
  @$pb.TagNumber(3)
  void clearAwardedCoins() => clearField(3);
}

enum PlayerAction_Action { join, answer, ping, notSet }

/// Messages sent by the client → server
class PlayerAction extends $pb.GeneratedMessage {
  factory PlayerAction({
    JoinMatchAction? join,
    SubmitAnswerAction? answer,
    HeartbeatAction? ping,
  }) {
    final $result = create();
    if (join != null) {
      $result.join = join;
    }
    if (answer != null) {
      $result.answer = answer;
    }
    if (ping != null) {
      $result.ping = ping;
    }
    return $result;
  }
  PlayerAction._() : super();
  factory PlayerAction.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PlayerAction.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, PlayerAction_Action>
      _PlayerAction_ActionByTag = {
    1: PlayerAction_Action.join,
    2: PlayerAction_Action.answer,
    3: PlayerAction_Action.ping,
    0: PlayerAction_Action.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayerAction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<JoinMatchAction>(1, _omitFieldNames ? '' : 'join',
        subBuilder: JoinMatchAction.create)
    ..aOM<SubmitAnswerAction>(2, _omitFieldNames ? '' : 'answer',
        subBuilder: SubmitAnswerAction.create)
    ..aOM<HeartbeatAction>(3, _omitFieldNames ? '' : 'ping',
        subBuilder: HeartbeatAction.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PlayerAction clone() => PlayerAction()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PlayerAction copyWith(void Function(PlayerAction) updates) =>
      super.copyWith((message) => updates(message as PlayerAction))
          as PlayerAction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayerAction create() => PlayerAction._();
  PlayerAction createEmptyInstance() => create();
  static $pb.PbList<PlayerAction> createRepeated() =>
      $pb.PbList<PlayerAction>();
  @$core.pragma('dart2js:noInline')
  static PlayerAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayerAction>(create);
  static PlayerAction? _defaultInstance;

  PlayerAction_Action whichAction() =>
      _PlayerAction_ActionByTag[$_whichOneof(0)]!;
  void clearAction() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  JoinMatchAction get join => $_getN(0);
  @$pb.TagNumber(1)
  set join(JoinMatchAction v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasJoin() => $_has(0);
  @$pb.TagNumber(1)
  void clearJoin() => clearField(1);
  @$pb.TagNumber(1)
  JoinMatchAction ensureJoin() => $_ensure(0);

  @$pb.TagNumber(2)
  SubmitAnswerAction get answer => $_getN(1);
  @$pb.TagNumber(2)
  set answer(SubmitAnswerAction v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAnswer() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnswer() => clearField(2);
  @$pb.TagNumber(2)
  SubmitAnswerAction ensureAnswer() => $_ensure(1);

  @$pb.TagNumber(3)
  HeartbeatAction get ping => $_getN(2);
  @$pb.TagNumber(3)
  set ping(HeartbeatAction v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPing() => $_has(2);
  @$pb.TagNumber(3)
  void clearPing() => clearField(3);
  @$pb.TagNumber(3)
  HeartbeatAction ensurePing() => $_ensure(2);
}

class JoinMatchAction extends $pb.GeneratedMessage {
  factory JoinMatchAction({
    $core.String? matchId,
    $core.String? playerId,
  }) {
    final $result = create();
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (playerId != null) {
      $result.playerId = playerId;
    }
    return $result;
  }
  JoinMatchAction._() : super();
  factory JoinMatchAction.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory JoinMatchAction.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinMatchAction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'matchId')
    ..aOS(2, _omitFieldNames ? '' : 'playerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  JoinMatchAction clone() => JoinMatchAction()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  JoinMatchAction copyWith(void Function(JoinMatchAction) updates) =>
      super.copyWith((message) => updates(message as JoinMatchAction))
          as JoinMatchAction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinMatchAction create() => JoinMatchAction._();
  JoinMatchAction createEmptyInstance() => create();
  static $pb.PbList<JoinMatchAction> createRepeated() =>
      $pb.PbList<JoinMatchAction>();
  @$core.pragma('dart2js:noInline')
  static JoinMatchAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinMatchAction>(create);
  static JoinMatchAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get matchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set matchId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMatchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMatchId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get playerId => $_getSZ(1);
  @$pb.TagNumber(2)
  set playerId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPlayerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayerId() => clearField(2);
}

class SubmitAnswerAction extends $pb.GeneratedMessage {
  factory SubmitAnswerAction({
    $core.String? matchId,
    $core.String? questionId,
    $core.String? selectedOptionId,
    $fixnum.Int64? answeredAtMs,
  }) {
    final $result = create();
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (questionId != null) {
      $result.questionId = questionId;
    }
    if (selectedOptionId != null) {
      $result.selectedOptionId = selectedOptionId;
    }
    if (answeredAtMs != null) {
      $result.answeredAtMs = answeredAtMs;
    }
    return $result;
  }
  SubmitAnswerAction._() : super();
  factory SubmitAnswerAction.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubmitAnswerAction.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitAnswerAction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'matchId')
    ..aOS(2, _omitFieldNames ? '' : 'questionId')
    ..aOS(3, _omitFieldNames ? '' : 'selectedOptionId')
    ..aInt64(4, _omitFieldNames ? '' : 'answeredAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubmitAnswerAction clone() => SubmitAnswerAction()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubmitAnswerAction copyWith(void Function(SubmitAnswerAction) updates) =>
      super.copyWith((message) => updates(message as SubmitAnswerAction))
          as SubmitAnswerAction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitAnswerAction create() => SubmitAnswerAction._();
  SubmitAnswerAction createEmptyInstance() => create();
  static $pb.PbList<SubmitAnswerAction> createRepeated() =>
      $pb.PbList<SubmitAnswerAction>();
  @$core.pragma('dart2js:noInline')
  static SubmitAnswerAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitAnswerAction>(create);
  static SubmitAnswerAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get matchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set matchId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMatchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMatchId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get questionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set questionId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasQuestionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuestionId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get selectedOptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set selectedOptionId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSelectedOptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelectedOptionId() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get answeredAtMs => $_getI64(3);
  @$pb.TagNumber(4)
  set answeredAtMs($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAnsweredAtMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearAnsweredAtMs() => clearField(4);
}

class HeartbeatAction extends $pb.GeneratedMessage {
  factory HeartbeatAction({
    $fixnum.Int64? clientTimestampMs,
  }) {
    final $result = create();
    if (clientTimestampMs != null) {
      $result.clientTimestampMs = clientTimestampMs;
    }
    return $result;
  }
  HeartbeatAction._() : super();
  factory HeartbeatAction.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HeartbeatAction.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeartbeatAction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'clientTimestampMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  HeartbeatAction clone() => HeartbeatAction()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  HeartbeatAction copyWith(void Function(HeartbeatAction) updates) =>
      super.copyWith((message) => updates(message as HeartbeatAction))
          as HeartbeatAction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeartbeatAction create() => HeartbeatAction._();
  HeartbeatAction createEmptyInstance() => create();
  static $pb.PbList<HeartbeatAction> createRepeated() =>
      $pb.PbList<HeartbeatAction>();
  @$core.pragma('dart2js:noInline')
  static HeartbeatAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeartbeatAction>(create);
  static HeartbeatAction? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get clientTimestampMs => $_getI64(0);
  @$pb.TagNumber(1)
  set clientTimestampMs($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasClientTimestampMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientTimestampMs() => clearField(1);
}

enum MatchEvent_Event {
  question,
  opponentScore,
  timer,
  answerResult,
  matchEnd,
  error,
  notSet
}

/// Messages sent by the server → client
class MatchEvent extends $pb.GeneratedMessage {
  factory MatchEvent({
    QuestionEvent? question,
    OpponentScoreEvent? opponentScore,
    TimerEvent? timer,
    AnswerResultEvent? answerResult,
    MatchEndEvent? matchEnd,
    ErrorEvent? error,
  }) {
    final $result = create();
    if (question != null) {
      $result.question = question;
    }
    if (opponentScore != null) {
      $result.opponentScore = opponentScore;
    }
    if (timer != null) {
      $result.timer = timer;
    }
    if (answerResult != null) {
      $result.answerResult = answerResult;
    }
    if (matchEnd != null) {
      $result.matchEnd = matchEnd;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  MatchEvent._() : super();
  factory MatchEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MatchEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, MatchEvent_Event> _MatchEvent_EventByTag = {
    1: MatchEvent_Event.question,
    2: MatchEvent_Event.opponentScore,
    3: MatchEvent_Event.timer,
    4: MatchEvent_Event.answerResult,
    5: MatchEvent_Event.matchEnd,
    6: MatchEvent_Event.error,
    0: MatchEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOM<QuestionEvent>(1, _omitFieldNames ? '' : 'question',
        subBuilder: QuestionEvent.create)
    ..aOM<OpponentScoreEvent>(2, _omitFieldNames ? '' : 'opponentScore',
        subBuilder: OpponentScoreEvent.create)
    ..aOM<TimerEvent>(3, _omitFieldNames ? '' : 'timer',
        subBuilder: TimerEvent.create)
    ..aOM<AnswerResultEvent>(4, _omitFieldNames ? '' : 'answerResult',
        subBuilder: AnswerResultEvent.create)
    ..aOM<MatchEndEvent>(5, _omitFieldNames ? '' : 'matchEnd',
        subBuilder: MatchEndEvent.create)
    ..aOM<ErrorEvent>(6, _omitFieldNames ? '' : 'error',
        subBuilder: ErrorEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MatchEvent clone() => MatchEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MatchEvent copyWith(void Function(MatchEvent) updates) =>
      super.copyWith((message) => updates(message as MatchEvent)) as MatchEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchEvent create() => MatchEvent._();
  MatchEvent createEmptyInstance() => create();
  static $pb.PbList<MatchEvent> createRepeated() => $pb.PbList<MatchEvent>();
  @$core.pragma('dart2js:noInline')
  static MatchEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchEvent>(create);
  static MatchEvent? _defaultInstance;

  MatchEvent_Event whichEvent() => _MatchEvent_EventByTag[$_whichOneof(0)]!;
  void clearEvent() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  QuestionEvent get question => $_getN(0);
  @$pb.TagNumber(1)
  set question(QuestionEvent v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasQuestion() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuestion() => clearField(1);
  @$pb.TagNumber(1)
  QuestionEvent ensureQuestion() => $_ensure(0);

  @$pb.TagNumber(2)
  OpponentScoreEvent get opponentScore => $_getN(1);
  @$pb.TagNumber(2)
  set opponentScore(OpponentScoreEvent v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOpponentScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpponentScore() => clearField(2);
  @$pb.TagNumber(2)
  OpponentScoreEvent ensureOpponentScore() => $_ensure(1);

  @$pb.TagNumber(3)
  TimerEvent get timer => $_getN(2);
  @$pb.TagNumber(3)
  set timer(TimerEvent v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTimer() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimer() => clearField(3);
  @$pb.TagNumber(3)
  TimerEvent ensureTimer() => $_ensure(2);

  @$pb.TagNumber(4)
  AnswerResultEvent get answerResult => $_getN(3);
  @$pb.TagNumber(4)
  set answerResult(AnswerResultEvent v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAnswerResult() => $_has(3);
  @$pb.TagNumber(4)
  void clearAnswerResult() => clearField(4);
  @$pb.TagNumber(4)
  AnswerResultEvent ensureAnswerResult() => $_ensure(3);

  @$pb.TagNumber(5)
  MatchEndEvent get matchEnd => $_getN(4);
  @$pb.TagNumber(5)
  set matchEnd(MatchEndEvent v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMatchEnd() => $_has(4);
  @$pb.TagNumber(5)
  void clearMatchEnd() => clearField(5);
  @$pb.TagNumber(5)
  MatchEndEvent ensureMatchEnd() => $_ensure(4);

  @$pb.TagNumber(6)
  ErrorEvent get error => $_getN(5);
  @$pb.TagNumber(6)
  set error(ErrorEvent v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => clearField(6);
  @$pb.TagNumber(6)
  ErrorEvent ensureError() => $_ensure(5);
}

class QuestionEvent extends $pb.GeneratedMessage {
  factory QuestionEvent({
    $core.String? questionId,
    $core.String? text,
    $core.String? category,
    $core.int? difficulty,
    $core.Iterable<Option>? options,
    $core.String? mediaUrl,
    $core.int? timeLimitS,
    $core.int? questionNum,
  }) {
    final $result = create();
    if (questionId != null) {
      $result.questionId = questionId;
    }
    if (text != null) {
      $result.text = text;
    }
    if (category != null) {
      $result.category = category;
    }
    if (difficulty != null) {
      $result.difficulty = difficulty;
    }
    if (options != null) {
      $result.options.addAll(options);
    }
    if (mediaUrl != null) {
      $result.mediaUrl = mediaUrl;
    }
    if (timeLimitS != null) {
      $result.timeLimitS = timeLimitS;
    }
    if (questionNum != null) {
      $result.questionNum = questionNum;
    }
    return $result;
  }
  QuestionEvent._() : super();
  factory QuestionEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QuestionEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuestionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'questionId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'category')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'difficulty', $pb.PbFieldType.O3)
    ..pc<Option>(5, _omitFieldNames ? '' : 'options', $pb.PbFieldType.PM,
        subBuilder: Option.create)
    ..aOS(6, _omitFieldNames ? '' : 'mediaUrl')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'timeLimitS', $pb.PbFieldType.O3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'questionNum', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QuestionEvent clone() => QuestionEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QuestionEvent copyWith(void Function(QuestionEvent) updates) =>
      super.copyWith((message) => updates(message as QuestionEvent))
          as QuestionEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuestionEvent create() => QuestionEvent._();
  QuestionEvent createEmptyInstance() => create();
  static $pb.PbList<QuestionEvent> createRepeated() =>
      $pb.PbList<QuestionEvent>();
  @$core.pragma('dart2js:noInline')
  static QuestionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuestionEvent>(create);
  static QuestionEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get questionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set questionId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasQuestionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuestionId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get category => $_getSZ(2);
  @$pb.TagNumber(3)
  set category($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCategory() => $_has(2);
  @$pb.TagNumber(3)
  void clearCategory() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get difficulty => $_getIZ(3);
  @$pb.TagNumber(4)
  set difficulty($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasDifficulty() => $_has(3);
  @$pb.TagNumber(4)
  void clearDifficulty() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<Option> get options => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get mediaUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set mediaUrl($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasMediaUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearMediaUrl() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get timeLimitS => $_getIZ(6);
  @$pb.TagNumber(7)
  set timeLimitS($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasTimeLimitS() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimeLimitS() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get questionNum => $_getIZ(7);
  @$pb.TagNumber(8)
  set questionNum($core.int v) {
    $_setSignedInt32(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasQuestionNum() => $_has(7);
  @$pb.TagNumber(8)
  void clearQuestionNum() => clearField(8);
}

class Option extends $pb.GeneratedMessage {
  factory Option({
    $core.String? id,
    $core.String? text,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (text != null) {
      $result.text = text;
    }
    return $result;
  }
  Option._() : super();
  factory Option.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Option.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Option',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Option clone() => Option()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Option copyWith(void Function(Option) updates) =>
      super.copyWith((message) => updates(message as Option)) as Option;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Option create() => Option._();
  Option createEmptyInstance() => create();
  static $pb.PbList<Option> createRepeated() => $pb.PbList<Option>();
  @$core.pragma('dart2js:noInline')
  static Option getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Option>(create);
  static Option? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);
}

class OpponentScoreEvent extends $pb.GeneratedMessage {
  factory OpponentScoreEvent({
    $core.String? opponentPlayerId,
    $core.int? score,
    $core.int? correctCount,
  }) {
    final $result = create();
    if (opponentPlayerId != null) {
      $result.opponentPlayerId = opponentPlayerId;
    }
    if (score != null) {
      $result.score = score;
    }
    if (correctCount != null) {
      $result.correctCount = correctCount;
    }
    return $result;
  }
  OpponentScoreEvent._() : super();
  factory OpponentScoreEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory OpponentScoreEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpponentScoreEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'opponentPlayerId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'score', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'correctCount', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OpponentScoreEvent clone() => OpponentScoreEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OpponentScoreEvent copyWith(void Function(OpponentScoreEvent) updates) =>
      super.copyWith((message) => updates(message as OpponentScoreEvent))
          as OpponentScoreEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpponentScoreEvent create() => OpponentScoreEvent._();
  OpponentScoreEvent createEmptyInstance() => create();
  static $pb.PbList<OpponentScoreEvent> createRepeated() =>
      $pb.PbList<OpponentScoreEvent>();
  @$core.pragma('dart2js:noInline')
  static OpponentScoreEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpponentScoreEvent>(create);
  static OpponentScoreEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get opponentPlayerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set opponentPlayerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasOpponentPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpponentPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get score => $_getIZ(1);
  @$pb.TagNumber(2)
  set score($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearScore() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get correctCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set correctCount($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCorrectCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCorrectCount() => clearField(3);
}

class TimerEvent extends $pb.GeneratedMessage {
  factory TimerEvent({
    $core.String? questionId,
    $core.int? remainingSeconds,
  }) {
    final $result = create();
    if (questionId != null) {
      $result.questionId = questionId;
    }
    if (remainingSeconds != null) {
      $result.remainingSeconds = remainingSeconds;
    }
    return $result;
  }
  TimerEvent._() : super();
  factory TimerEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TimerEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimerEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'questionId')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'remainingSeconds', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TimerEvent clone() => TimerEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TimerEvent copyWith(void Function(TimerEvent) updates) =>
      super.copyWith((message) => updates(message as TimerEvent)) as TimerEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimerEvent create() => TimerEvent._();
  TimerEvent createEmptyInstance() => create();
  static $pb.PbList<TimerEvent> createRepeated() => $pb.PbList<TimerEvent>();
  @$core.pragma('dart2js:noInline')
  static TimerEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimerEvent>(create);
  static TimerEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get questionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set questionId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasQuestionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuestionId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get remainingSeconds => $_getIZ(1);
  @$pb.TagNumber(2)
  set remainingSeconds($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRemainingSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemainingSeconds() => clearField(2);
}

class AnswerResultEvent extends $pb.GeneratedMessage {
  factory AnswerResultEvent({
    $core.String? questionId,
    $core.String? selectedOptionId,
    $core.String? correctOptionId,
    $core.bool? isCorrect,
    $core.int? pointsAwarded,
    $core.int? runningScore,
  }) {
    final $result = create();
    if (questionId != null) {
      $result.questionId = questionId;
    }
    if (selectedOptionId != null) {
      $result.selectedOptionId = selectedOptionId;
    }
    if (correctOptionId != null) {
      $result.correctOptionId = correctOptionId;
    }
    if (isCorrect != null) {
      $result.isCorrect = isCorrect;
    }
    if (pointsAwarded != null) {
      $result.pointsAwarded = pointsAwarded;
    }
    if (runningScore != null) {
      $result.runningScore = runningScore;
    }
    return $result;
  }
  AnswerResultEvent._() : super();
  factory AnswerResultEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AnswerResultEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnswerResultEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'questionId')
    ..aOS(2, _omitFieldNames ? '' : 'selectedOptionId')
    ..aOS(3, _omitFieldNames ? '' : 'correctOptionId')
    ..aOB(4, _omitFieldNames ? '' : 'isCorrect')
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'pointsAwarded', $pb.PbFieldType.O3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'runningScore', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AnswerResultEvent clone() => AnswerResultEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AnswerResultEvent copyWith(void Function(AnswerResultEvent) updates) =>
      super.copyWith((message) => updates(message as AnswerResultEvent))
          as AnswerResultEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnswerResultEvent create() => AnswerResultEvent._();
  AnswerResultEvent createEmptyInstance() => create();
  static $pb.PbList<AnswerResultEvent> createRepeated() =>
      $pb.PbList<AnswerResultEvent>();
  @$core.pragma('dart2js:noInline')
  static AnswerResultEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnswerResultEvent>(create);
  static AnswerResultEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get questionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set questionId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasQuestionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuestionId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get selectedOptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set selectedOptionId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSelectedOptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelectedOptionId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get correctOptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set correctOptionId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCorrectOptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearCorrectOptionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isCorrect => $_getBF(3);
  @$pb.TagNumber(4)
  set isCorrect($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasIsCorrect() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsCorrect() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get pointsAwarded => $_getIZ(4);
  @$pb.TagNumber(5)
  set pointsAwarded($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPointsAwarded() => $_has(4);
  @$pb.TagNumber(5)
  void clearPointsAwarded() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get runningScore => $_getIZ(5);
  @$pb.TagNumber(6)
  set runningScore($core.int v) {
    $_setSignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRunningScore() => $_has(5);
  @$pb.TagNumber(6)
  void clearRunningScore() => clearField(6);
}

class MatchEndEvent extends $pb.GeneratedMessage {
  factory MatchEndEvent({
    $core.String? matchId,
    $core.String? outcome,
    $core.int? finalScore,
    $core.int? awardedXp,
    $core.int? awardedCoins,
    $core.Iterable<FinalParticipant>? participants,
  }) {
    final $result = create();
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (outcome != null) {
      $result.outcome = outcome;
    }
    if (finalScore != null) {
      $result.finalScore = finalScore;
    }
    if (awardedXp != null) {
      $result.awardedXp = awardedXp;
    }
    if (awardedCoins != null) {
      $result.awardedCoins = awardedCoins;
    }
    if (participants != null) {
      $result.participants.addAll(participants);
    }
    return $result;
  }
  MatchEndEvent._() : super();
  factory MatchEndEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MatchEndEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchEndEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'matchId')
    ..aOS(2, _omitFieldNames ? '' : 'outcome')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'finalScore', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'awardedXp', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'awardedCoins', $pb.PbFieldType.O3)
    ..pc<FinalParticipant>(
        6, _omitFieldNames ? '' : 'participants', $pb.PbFieldType.PM,
        subBuilder: FinalParticipant.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MatchEndEvent clone() => MatchEndEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MatchEndEvent copyWith(void Function(MatchEndEvent) updates) =>
      super.copyWith((message) => updates(message as MatchEndEvent))
          as MatchEndEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchEndEvent create() => MatchEndEvent._();
  MatchEndEvent createEmptyInstance() => create();
  static $pb.PbList<MatchEndEvent> createRepeated() =>
      $pb.PbList<MatchEndEvent>();
  @$core.pragma('dart2js:noInline')
  static MatchEndEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchEndEvent>(create);
  static MatchEndEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get matchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set matchId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMatchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMatchId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get outcome => $_getSZ(1);
  @$pb.TagNumber(2)
  set outcome($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOutcome() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutcome() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get finalScore => $_getIZ(2);
  @$pb.TagNumber(3)
  set finalScore($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasFinalScore() => $_has(2);
  @$pb.TagNumber(3)
  void clearFinalScore() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get awardedXp => $_getIZ(3);
  @$pb.TagNumber(4)
  set awardedXp($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAwardedXp() => $_has(3);
  @$pb.TagNumber(4)
  void clearAwardedXp() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get awardedCoins => $_getIZ(4);
  @$pb.TagNumber(5)
  set awardedCoins($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAwardedCoins() => $_has(4);
  @$pb.TagNumber(5)
  void clearAwardedCoins() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<FinalParticipant> get participants => $_getList(5);
}

class FinalParticipant extends $pb.GeneratedMessage {
  factory FinalParticipant({
    $core.String? playerId,
    $core.int? score,
    $core.int? correct,
    $core.int? wrong,
    $core.String? outcome,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (score != null) {
      $result.score = score;
    }
    if (correct != null) {
      $result.correct = correct;
    }
    if (wrong != null) {
      $result.wrong = wrong;
    }
    if (outcome != null) {
      $result.outcome = outcome;
    }
    return $result;
  }
  FinalParticipant._() : super();
  factory FinalParticipant.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FinalParticipant.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinalParticipant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'score', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'correct', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'wrong', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'outcome')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FinalParticipant clone() => FinalParticipant()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FinalParticipant copyWith(void Function(FinalParticipant) updates) =>
      super.copyWith((message) => updates(message as FinalParticipant))
          as FinalParticipant;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FinalParticipant create() => FinalParticipant._();
  FinalParticipant createEmptyInstance() => create();
  static $pb.PbList<FinalParticipant> createRepeated() =>
      $pb.PbList<FinalParticipant>();
  @$core.pragma('dart2js:noInline')
  static FinalParticipant getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinalParticipant>(create);
  static FinalParticipant? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get score => $_getIZ(1);
  @$pb.TagNumber(2)
  set score($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearScore() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get correct => $_getIZ(2);
  @$pb.TagNumber(3)
  set correct($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCorrect() => $_has(2);
  @$pb.TagNumber(3)
  void clearCorrect() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get wrong => $_getIZ(3);
  @$pb.TagNumber(4)
  set wrong($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasWrong() => $_has(3);
  @$pb.TagNumber(4)
  void clearWrong() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get outcome => $_getSZ(4);
  @$pb.TagNumber(5)
  set outcome($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasOutcome() => $_has(4);
  @$pb.TagNumber(5)
  void clearOutcome() => clearField(5);
}

class ErrorEvent extends $pb.GeneratedMessage {
  factory ErrorEvent({
    $core.String? code,
    $core.String? message,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ErrorEvent._() : super();
  factory ErrorEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ErrorEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ErrorEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ErrorEvent clone() => ErrorEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ErrorEvent copyWith(void Function(ErrorEvent) updates) =>
      super.copyWith((message) => updates(message as ErrorEvent)) as ErrorEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ErrorEvent create() => ErrorEvent._();
  ErrorEvent createEmptyInstance() => create();
  static $pb.PbList<ErrorEvent> createRepeated() => $pb.PbList<ErrorEvent>();
  @$core.pragma('dart2js:noInline')
  static ErrorEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ErrorEvent>(create);
  static ErrorEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);
}

class LeaderboardWatchRequest extends $pb.GeneratedMessage {
  factory LeaderboardWatchRequest({
    $core.String? playerId,
    $core.String? mode,
    $core.int? windowSize,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    if (windowSize != null) {
      $result.windowSize = windowSize;
    }
    return $result;
  }
  LeaderboardWatchRequest._() : super();
  factory LeaderboardWatchRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LeaderboardWatchRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaderboardWatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'mode')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'windowSize', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LeaderboardWatchRequest clone() =>
      LeaderboardWatchRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LeaderboardWatchRequest copyWith(
          void Function(LeaderboardWatchRequest) updates) =>
      super.copyWith((message) => updates(message as LeaderboardWatchRequest))
          as LeaderboardWatchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LeaderboardWatchRequest create() => LeaderboardWatchRequest._();
  LeaderboardWatchRequest createEmptyInstance() => create();
  static $pb.PbList<LeaderboardWatchRequest> createRepeated() =>
      $pb.PbList<LeaderboardWatchRequest>();
  @$core.pragma('dart2js:noInline')
  static LeaderboardWatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaderboardWatchRequest>(create);
  static LeaderboardWatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get mode => $_getSZ(1);
  @$pb.TagNumber(2)
  set mode($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get windowSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set windowSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWindowSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearWindowSize() => clearField(3);
}

class LeaderboardUpdate extends $pb.GeneratedMessage {
  factory LeaderboardUpdate({
    $core.String? playerId,
    $core.int? playerRank,
    $core.int? playerScore,
    $core.Iterable<LeaderboardEntry>? nearby,
    $fixnum.Int64? snapshotAtMs,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (playerRank != null) {
      $result.playerRank = playerRank;
    }
    if (playerScore != null) {
      $result.playerScore = playerScore;
    }
    if (nearby != null) {
      $result.nearby.addAll(nearby);
    }
    if (snapshotAtMs != null) {
      $result.snapshotAtMs = snapshotAtMs;
    }
    return $result;
  }
  LeaderboardUpdate._() : super();
  factory LeaderboardUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LeaderboardUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaderboardUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'playerRank', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'playerScore', $pb.PbFieldType.O3)
    ..pc<LeaderboardEntry>(
        4, _omitFieldNames ? '' : 'nearby', $pb.PbFieldType.PM,
        subBuilder: LeaderboardEntry.create)
    ..aInt64(5, _omitFieldNames ? '' : 'snapshotAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LeaderboardUpdate clone() => LeaderboardUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LeaderboardUpdate copyWith(void Function(LeaderboardUpdate) updates) =>
      super.copyWith((message) => updates(message as LeaderboardUpdate))
          as LeaderboardUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LeaderboardUpdate create() => LeaderboardUpdate._();
  LeaderboardUpdate createEmptyInstance() => create();
  static $pb.PbList<LeaderboardUpdate> createRepeated() =>
      $pb.PbList<LeaderboardUpdate>();
  @$core.pragma('dart2js:noInline')
  static LeaderboardUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaderboardUpdate>(create);
  static LeaderboardUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get playerRank => $_getIZ(1);
  @$pb.TagNumber(2)
  set playerRank($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPlayerRank() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayerRank() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get playerScore => $_getIZ(2);
  @$pb.TagNumber(3)
  set playerScore($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPlayerScore() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlayerScore() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<LeaderboardEntry> get nearby => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get snapshotAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set snapshotAtMs($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSnapshotAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearSnapshotAtMs() => clearField(5);
}

class LeaderboardEntry extends $pb.GeneratedMessage {
  factory LeaderboardEntry({
    $core.int? rank,
    $core.String? playerId,
    $core.String? handle,
    $core.int? score,
    $core.String? country,
  }) {
    final $result = create();
    if (rank != null) {
      $result.rank = rank;
    }
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (handle != null) {
      $result.handle = handle;
    }
    if (score != null) {
      $result.score = score;
    }
    if (country != null) {
      $result.country = country;
    }
    return $result;
  }
  LeaderboardEntry._() : super();
  factory LeaderboardEntry.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LeaderboardEntry.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaderboardEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'rank', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'playerId')
    ..aOS(3, _omitFieldNames ? '' : 'handle')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'score', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'country')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LeaderboardEntry clone() => LeaderboardEntry()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LeaderboardEntry copyWith(void Function(LeaderboardEntry) updates) =>
      super.copyWith((message) => updates(message as LeaderboardEntry))
          as LeaderboardEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LeaderboardEntry create() => LeaderboardEntry._();
  LeaderboardEntry createEmptyInstance() => create();
  static $pb.PbList<LeaderboardEntry> createRepeated() =>
      $pb.PbList<LeaderboardEntry>();
  @$core.pragma('dart2js:noInline')
  static LeaderboardEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaderboardEntry>(create);
  static LeaderboardEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get rank => $_getIZ(0);
  @$pb.TagNumber(1)
  set rank($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRank() => $_has(0);
  @$pb.TagNumber(1)
  void clearRank() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get playerId => $_getSZ(1);
  @$pb.TagNumber(2)
  set playerId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPlayerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayerId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get handle => $_getSZ(2);
  @$pb.TagNumber(3)
  set handle($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasHandle() => $_has(2);
  @$pb.TagNumber(3)
  void clearHandle() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get score => $_getIZ(3);
  @$pb.TagNumber(4)
  set score($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasScore() => $_has(3);
  @$pb.TagNumber(4)
  void clearScore() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get country => $_getSZ(4);
  @$pb.TagNumber(5)
  set country($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCountry() => $_has(4);
  @$pb.TagNumber(5)
  void clearCountry() => clearField(5);
}

class WatchMatchmakingRequest extends $pb.GeneratedMessage {
  factory WatchMatchmakingRequest({
    $core.String? playerId,
    $core.String? mode,
    $core.int? tierId,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (mode != null) {
      $result.mode = mode;
    }
    if (tierId != null) {
      $result.tierId = tierId;
    }
    return $result;
  }
  WatchMatchmakingRequest._() : super();
  factory WatchMatchmakingRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory WatchMatchmakingRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchMatchmakingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'mode')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'tierId', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  WatchMatchmakingRequest clone() =>
      WatchMatchmakingRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  WatchMatchmakingRequest copyWith(
          void Function(WatchMatchmakingRequest) updates) =>
      super.copyWith((message) => updates(message as WatchMatchmakingRequest))
          as WatchMatchmakingRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchMatchmakingRequest create() => WatchMatchmakingRequest._();
  WatchMatchmakingRequest createEmptyInstance() => create();
  static $pb.PbList<WatchMatchmakingRequest> createRepeated() =>
      $pb.PbList<WatchMatchmakingRequest>();
  @$core.pragma('dart2js:noInline')
  static WatchMatchmakingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchMatchmakingRequest>(create);
  static WatchMatchmakingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get mode => $_getSZ(1);
  @$pb.TagNumber(2)
  set mode($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get tierId => $_getIZ(2);
  @$pb.TagNumber(3)
  set tierId($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTierId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTierId() => clearField(3);
}

/// Emitted by the server until status = "Matched" or the stream is cancelled.
class MatchmakingStatusUpdate extends $pb.GeneratedMessage {
  factory MatchmakingStatusUpdate({
    $core.String? ticketId,
    $core.String? status,
    $core.int? queuePosition,
    $core.String? matchId,
    $core.String? opponentId,
    $core.String? opponentHandle,
  }) {
    final $result = create();
    if (ticketId != null) {
      $result.ticketId = ticketId;
    }
    if (status != null) {
      $result.status = status;
    }
    if (queuePosition != null) {
      $result.queuePosition = queuePosition;
    }
    if (matchId != null) {
      $result.matchId = matchId;
    }
    if (opponentId != null) {
      $result.opponentId = opponentId;
    }
    if (opponentHandle != null) {
      $result.opponentHandle = opponentHandle;
    }
    return $result;
  }
  MatchmakingStatusUpdate._() : super();
  factory MatchmakingStatusUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MatchmakingStatusUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchmakingStatusUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ticketId')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'queuePosition', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'matchId')
    ..aOS(5, _omitFieldNames ? '' : 'opponentId')
    ..aOS(6, _omitFieldNames ? '' : 'opponentHandle')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MatchmakingStatusUpdate clone() =>
      MatchmakingStatusUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MatchmakingStatusUpdate copyWith(
          void Function(MatchmakingStatusUpdate) updates) =>
      super.copyWith((message) => updates(message as MatchmakingStatusUpdate))
          as MatchmakingStatusUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchmakingStatusUpdate create() => MatchmakingStatusUpdate._();
  MatchmakingStatusUpdate createEmptyInstance() => create();
  static $pb.PbList<MatchmakingStatusUpdate> createRepeated() =>
      $pb.PbList<MatchmakingStatusUpdate>();
  @$core.pragma('dart2js:noInline')
  static MatchmakingStatusUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchmakingStatusUpdate>(create);
  static MatchmakingStatusUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ticketId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ticketId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTicketId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTicketId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get queuePosition => $_getIZ(2);
  @$pb.TagNumber(3)
  set queuePosition($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasQueuePosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueuePosition() => clearField(3);

  /// Populated when status = "Matched"
  @$pb.TagNumber(4)
  $core.String get matchId => $_getSZ(3);
  @$pb.TagNumber(4)
  set matchId($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMatchId() => $_has(3);
  @$pb.TagNumber(4)
  void clearMatchId() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get opponentId => $_getSZ(4);
  @$pb.TagNumber(5)
  set opponentId($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasOpponentId() => $_has(4);
  @$pb.TagNumber(5)
  void clearOpponentId() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get opponentHandle => $_getSZ(5);
  @$pb.TagNumber(6)
  set opponentHandle($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasOpponentHandle() => $_has(5);
  @$pb.TagNumber(6)
  void clearOpponentHandle() => clearField(6);
}

class CancelMatchmakingRequest extends $pb.GeneratedMessage {
  factory CancelMatchmakingRequest({
    $core.String? playerId,
    $core.String? ticketId,
  }) {
    final $result = create();
    if (playerId != null) {
      $result.playerId = playerId;
    }
    if (ticketId != null) {
      $result.ticketId = ticketId;
    }
    return $result;
  }
  CancelMatchmakingRequest._() : super();
  factory CancelMatchmakingRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CancelMatchmakingRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelMatchmakingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'ticketId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CancelMatchmakingRequest clone() =>
      CancelMatchmakingRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CancelMatchmakingRequest copyWith(
          void Function(CancelMatchmakingRequest) updates) =>
      super.copyWith((message) => updates(message as CancelMatchmakingRequest))
          as CancelMatchmakingRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelMatchmakingRequest create() => CancelMatchmakingRequest._();
  CancelMatchmakingRequest createEmptyInstance() => create();
  static $pb.PbList<CancelMatchmakingRequest> createRepeated() =>
      $pb.PbList<CancelMatchmakingRequest>();
  @$core.pragma('dart2js:noInline')
  static CancelMatchmakingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelMatchmakingRequest>(create);
  static CancelMatchmakingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get ticketId => $_getSZ(1);
  @$pb.TagNumber(2)
  set ticketId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTicketId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTicketId() => clearField(2);
}

class CancelMatchmakingResponse extends $pb.GeneratedMessage {
  factory CancelMatchmakingResponse({
    $core.bool? cancelled,
    $core.String? ticketId,
  }) {
    final $result = create();
    if (cancelled != null) {
      $result.cancelled = cancelled;
    }
    if (ticketId != null) {
      $result.ticketId = ticketId;
    }
    return $result;
  }
  CancelMatchmakingResponse._() : super();
  factory CancelMatchmakingResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CancelMatchmakingResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelMatchmakingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'synaptix.mobile'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'cancelled')
    ..aOS(2, _omitFieldNames ? '' : 'ticketId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CancelMatchmakingResponse clone() =>
      CancelMatchmakingResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CancelMatchmakingResponse copyWith(
          void Function(CancelMatchmakingResponse) updates) =>
      super.copyWith((message) => updates(message as CancelMatchmakingResponse))
          as CancelMatchmakingResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelMatchmakingResponse create() => CancelMatchmakingResponse._();
  CancelMatchmakingResponse createEmptyInstance() => create();
  static $pb.PbList<CancelMatchmakingResponse> createRepeated() =>
      $pb.PbList<CancelMatchmakingResponse>();
  @$core.pragma('dart2js:noInline')
  static CancelMatchmakingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelMatchmakingResponse>(create);
  static CancelMatchmakingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get cancelled => $_getBF(0);
  @$pb.TagNumber(1)
  set cancelled($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCancelled() => $_has(0);
  @$pb.TagNumber(1)
  void clearCancelled() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get ticketId => $_getSZ(1);
  @$pb.TagNumber(2)
  set ticketId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTicketId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTicketId() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
