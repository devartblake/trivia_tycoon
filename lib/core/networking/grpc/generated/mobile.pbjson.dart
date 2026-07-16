//
//  Generated code. Do not modify.
//  source: mobile.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use grpcStartMatchRequestDescriptor instead')
const GrpcStartMatchRequest$json = {
  '1': 'GrpcStartMatchRequest',
  '2': [
    {'1': 'host_player_id', '3': 1, '4': 1, '5': 9, '10': 'hostPlayerId'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
  ],
};

/// Descriptor for `GrpcStartMatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grpcStartMatchRequestDescriptor = $convert.base64Decode(
    'ChVHcnBjU3RhcnRNYXRjaFJlcXVlc3QSJAoOaG9zdF9wbGF5ZXJfaWQYASABKAlSDGhvc3RQbG'
    'F5ZXJJZBISCgRtb2RlGAIgASgJUgRtb2Rl');

@$core.Deprecated('Use grpcStartMatchResponseDescriptor instead')
const GrpcStartMatchResponse$json = {
  '1': 'GrpcStartMatchResponse',
  '2': [
    {'1': 'match_id', '3': 1, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'started_at', '3': 2, '4': 1, '5': 3, '10': 'startedAt'},
  ],
};

/// Descriptor for `GrpcStartMatchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grpcStartMatchResponseDescriptor =
    $convert.base64Decode(
        'ChZHcnBjU3RhcnRNYXRjaFJlc3BvbnNlEhkKCG1hdGNoX2lkGAEgASgJUgdtYXRjaElkEh0KCn'
        'N0YXJ0ZWRfYXQYAiABKANSCXN0YXJ0ZWRBdA==');

@$core.Deprecated('Use grpcSubmitMatchRequestDescriptor instead')
const GrpcSubmitMatchRequest$json = {
  '1': 'GrpcSubmitMatchRequest',
  '2': [
    {'1': 'event_id', '3': 1, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'match_id', '3': 2, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'mode', '3': 3, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'category', '3': 4, '4': 1, '5': 9, '10': 'category'},
    {'1': 'question_count', '3': 5, '4': 1, '5': 5, '10': 'questionCount'},
    {'1': 'started_at_utc', '3': 6, '4': 1, '5': 3, '10': 'startedAtUtc'},
    {'1': 'ended_at_utc', '3': 7, '4': 1, '5': 3, '10': 'endedAtUtc'},
    {'1': 'status', '3': 8, '4': 1, '5': 5, '10': 'status'},
    {
      '1': 'participants',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.synaptix.mobile.ParticipantResult',
      '10': 'participants'
    },
  ],
};

/// Descriptor for `GrpcSubmitMatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grpcSubmitMatchRequestDescriptor = $convert.base64Decode(
    'ChZHcnBjU3VibWl0TWF0Y2hSZXF1ZXN0EhkKCGV2ZW50X2lkGAEgASgJUgdldmVudElkEhkKCG'
    '1hdGNoX2lkGAIgASgJUgdtYXRjaElkEhIKBG1vZGUYAyABKAlSBG1vZGUSGgoIY2F0ZWdvcnkY'
    'BCABKAlSCGNhdGVnb3J5EiUKDnF1ZXN0aW9uX2NvdW50GAUgASgFUg1xdWVzdGlvbkNvdW50Ei'
    'QKDnN0YXJ0ZWRfYXRfdXRjGAYgASgDUgxzdGFydGVkQXRVdGMSIAoMZW5kZWRfYXRfdXRjGAcg'
    'ASgDUgplbmRlZEF0VXRjEhYKBnN0YXR1cxgIIAEoBVIGc3RhdHVzEkQKDHBhcnRpY2lwYW50cx'
    'gJIAMoCzIgLnR5Y29vbi5tb2JpbGUuUGFydGljaXBhbnRSZXN1bHRSDHBhcnRpY2lwYW50cw==');

@$core.Deprecated('Use participantResultDescriptor instead')
const ParticipantResult$json = {
  '1': 'ParticipantResult',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'score', '3': 2, '4': 1, '5': 5, '10': 'score'},
    {'1': 'correct', '3': 3, '4': 1, '5': 5, '10': 'correct'},
    {'1': 'wrong', '3': 4, '4': 1, '5': 5, '10': 'wrong'},
    {
      '1': 'avg_answer_time_ms',
      '3': 5,
      '4': 1,
      '5': 1,
      '10': 'avgAnswerTimeMs'
    },
  ],
};

/// Descriptor for `ParticipantResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantResultDescriptor = $convert.base64Decode(
    'ChFQYXJ0aWNpcGFudFJlc3VsdBIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEhQKBXNjb3'
    'JlGAIgASgFUgVzY29yZRIYCgdjb3JyZWN0GAMgASgFUgdjb3JyZWN0EhQKBXdyb25nGAQgASgF'
    'UgV3cm9uZxIrChJhdmdfYW5zd2VyX3RpbWVfbXMYBSABKAFSD2F2Z0Fuc3dlclRpbWVNcw==');

@$core.Deprecated('Use grpcSubmitMatchResponseDescriptor instead')
const GrpcSubmitMatchResponse$json = {
  '1': 'GrpcSubmitMatchResponse',
  '2': [
    {'1': 'event_id', '3': 1, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'match_id', '3': 2, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'awards',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.synaptix.mobile.MatchAward',
      '10': 'awards'
    },
  ],
};

/// Descriptor for `GrpcSubmitMatchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grpcSubmitMatchResponseDescriptor = $convert.base64Decode(
    'ChdHcnBjU3VibWl0TWF0Y2hSZXNwb25zZRIZCghldmVudF9pZBgBIAEoCVIHZXZlbnRJZBIZCg'
    'htYXRjaF9pZBgCIAEoCVIHbWF0Y2hJZBIWCgZzdGF0dXMYAyABKAlSBnN0YXR1cxIxCgZhd2Fy'
    'ZHMYBCADKAsyGS50eWNvb24ubW9iaWxlLk1hdGNoQXdhcmRSBmF3YXJkcw==');

@$core.Deprecated('Use matchAwardDescriptor instead')
const MatchAward$json = {
  '1': 'MatchAward',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'awarded_xp', '3': 2, '4': 1, '5': 5, '10': 'awardedXp'},
    {'1': 'awarded_coins', '3': 3, '4': 1, '5': 5, '10': 'awardedCoins'},
  ],
};

/// Descriptor for `MatchAward`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchAwardDescriptor = $convert.base64Decode(
    'CgpNYXRjaEF3YXJkEhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQSHQoKYXdhcmRlZF94cB'
    'gCIAEoBVIJYXdhcmRlZFhwEiMKDWF3YXJkZWRfY29pbnMYAyABKAVSDGF3YXJkZWRDb2lucw==');

@$core.Deprecated('Use playerActionDescriptor instead')
const PlayerAction$json = {
  '1': 'PlayerAction',
  '2': [
    {
      '1': 'join',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.JoinMatchAction',
      '9': 0,
      '10': 'join'
    },
    {
      '1': 'answer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.SubmitAnswerAction',
      '9': 0,
      '10': 'answer'
    },
    {
      '1': 'ping',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.HeartbeatAction',
      '9': 0,
      '10': 'ping'
    },
  ],
  '8': [
    {'1': 'action'},
  ],
};

/// Descriptor for `PlayerAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playerActionDescriptor = $convert.base64Decode(
    'CgxQbGF5ZXJBY3Rpb24SNAoEam9pbhgBIAEoCzIeLnR5Y29vbi5tb2JpbGUuSm9pbk1hdGNoQW'
    'N0aW9uSABSBGpvaW4SOwoGYW5zd2VyGAIgASgLMiEudHljb29uLm1vYmlsZS5TdWJtaXRBbnN3'
    'ZXJBY3Rpb25IAFIGYW5zd2VyEjQKBHBpbmcYAyABKAsyHi50eWNvb24ubW9iaWxlLkhlYXJ0Ym'
    'VhdEFjdGlvbkgAUgRwaW5nQggKBmFjdGlvbg==');

@$core.Deprecated('Use joinMatchActionDescriptor instead')
const JoinMatchAction$json = {
  '1': 'JoinMatchAction',
  '2': [
    {'1': 'match_id', '3': 1, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'player_id', '3': 2, '4': 1, '5': 9, '10': 'playerId'},
  ],
};

/// Descriptor for `JoinMatchAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinMatchActionDescriptor = $convert.base64Decode(
    'Cg9Kb2luTWF0Y2hBY3Rpb24SGQoIbWF0Y2hfaWQYASABKAlSB21hdGNoSWQSGwoJcGxheWVyX2'
    'lkGAIgASgJUghwbGF5ZXJJZA==');

@$core.Deprecated('Use submitAnswerActionDescriptor instead')
const SubmitAnswerAction$json = {
  '1': 'SubmitAnswerAction',
  '2': [
    {'1': 'match_id', '3': 1, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'question_id', '3': 2, '4': 1, '5': 9, '10': 'questionId'},
    {
      '1': 'selected_option_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'selectedOptionId'
    },
    {'1': 'answered_at_ms', '3': 4, '4': 1, '5': 3, '10': 'answeredAtMs'},
  ],
};

/// Descriptor for `SubmitAnswerAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitAnswerActionDescriptor = $convert.base64Decode(
    'ChJTdWJtaXRBbnN3ZXJBY3Rpb24SGQoIbWF0Y2hfaWQYASABKAlSB21hdGNoSWQSHwoLcXVlc3'
    'Rpb25faWQYAiABKAlSCnF1ZXN0aW9uSWQSLAoSc2VsZWN0ZWRfb3B0aW9uX2lkGAMgASgJUhBz'
    'ZWxlY3RlZE9wdGlvbklkEiQKDmFuc3dlcmVkX2F0X21zGAQgASgDUgxhbnN3ZXJlZEF0TXM=');

@$core.Deprecated('Use heartbeatActionDescriptor instead')
const HeartbeatAction$json = {
  '1': 'HeartbeatAction',
  '2': [
    {
      '1': 'client_timestamp_ms',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'clientTimestampMs'
    },
  ],
};

/// Descriptor for `HeartbeatAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatActionDescriptor = $convert.base64Decode(
    'Cg9IZWFydGJlYXRBY3Rpb24SLgoTY2xpZW50X3RpbWVzdGFtcF9tcxgBIAEoA1IRY2xpZW50VG'
    'ltZXN0YW1wTXM=');

@$core.Deprecated('Use matchEventDescriptor instead')
const MatchEvent$json = {
  '1': 'MatchEvent',
  '2': [
    {
      '1': 'question',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.QuestionEvent',
      '9': 0,
      '10': 'question'
    },
    {
      '1': 'opponent_score',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.OpponentScoreEvent',
      '9': 0,
      '10': 'opponentScore'
    },
    {
      '1': 'timer',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.TimerEvent',
      '9': 0,
      '10': 'timer'
    },
    {
      '1': 'answer_result',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.AnswerResultEvent',
      '9': 0,
      '10': 'answerResult'
    },
    {
      '1': 'match_end',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.MatchEndEvent',
      '9': 0,
      '10': 'matchEnd'
    },
    {
      '1': 'error',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.synaptix.mobile.ErrorEvent',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `MatchEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchEventDescriptor = $convert.base64Decode(
    'CgpNYXRjaEV2ZW50EjoKCHF1ZXN0aW9uGAEgASgLMhwudHljb29uLm1vYmlsZS5RdWVzdGlvbk'
    'V2ZW50SABSCHF1ZXN0aW9uEkoKDm9wcG9uZW50X3Njb3JlGAIgASgLMiEudHljb29uLm1vYmls'
    'ZS5PcHBvbmVudFNjb3JlRXZlbnRIAFINb3Bwb25lbnRTY29yZRIxCgV0aW1lchgDIAEoCzIZLn'
    'R5Y29vbi5tb2JpbGUuVGltZXJFdmVudEgAUgV0aW1lchJHCg1hbnN3ZXJfcmVzdWx0GAQgASgL'
    'MiAudHljb29uLm1vYmlsZS5BbnN3ZXJSZXN1bHRFdmVudEgAUgxhbnN3ZXJSZXN1bHQSOwoJbW'
    'F0Y2hfZW5kGAUgASgLMhwudHljb29uLm1vYmlsZS5NYXRjaEVuZEV2ZW50SABSCG1hdGNoRW5k'
    'EjEKBWVycm9yGAYgASgLMhkudHljb29uLm1vYmlsZS5FcnJvckV2ZW50SABSBWVycm9yQgcKBW'
    'V2ZW50');

@$core.Deprecated('Use questionEventDescriptor instead')
const QuestionEvent$json = {
  '1': 'QuestionEvent',
  '2': [
    {'1': 'question_id', '3': 1, '4': 1, '5': 9, '10': 'questionId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'category', '3': 3, '4': 1, '5': 9, '10': 'category'},
    {'1': 'difficulty', '3': 4, '4': 1, '5': 5, '10': 'difficulty'},
    {
      '1': 'options',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.synaptix.mobile.Option',
      '10': 'options'
    },
    {'1': 'media_url', '3': 6, '4': 1, '5': 9, '10': 'mediaUrl'},
    {'1': 'time_limit_s', '3': 7, '4': 1, '5': 5, '10': 'timeLimitS'},
    {'1': 'question_num', '3': 8, '4': 1, '5': 5, '10': 'questionNum'},
  ],
};

/// Descriptor for `QuestionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List questionEventDescriptor = $convert.base64Decode(
    'Cg1RdWVzdGlvbkV2ZW50Eh8KC3F1ZXN0aW9uX2lkGAEgASgJUgpxdWVzdGlvbklkEhIKBHRleH'
    'QYAiABKAlSBHRleHQSGgoIY2F0ZWdvcnkYAyABKAlSCGNhdGVnb3J5Eh4KCmRpZmZpY3VsdHkY'
    'BCABKAVSCmRpZmZpY3VsdHkSLwoHb3B0aW9ucxgFIAMoCzIVLnR5Y29vbi5tb2JpbGUuT3B0aW'
    '9uUgdvcHRpb25zEhsKCW1lZGlhX3VybBgGIAEoCVIIbWVkaWFVcmwSIAoMdGltZV9saW1pdF9z'
    'GAcgASgFUgp0aW1lTGltaXRTEiEKDHF1ZXN0aW9uX251bRgIIAEoBVILcXVlc3Rpb25OdW0=');

@$core.Deprecated('Use optionDescriptor instead')
const Option$json = {
  '1': 'Option',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `Option`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List optionDescriptor = $convert.base64Decode(
    'CgZPcHRpb24SDgoCaWQYASABKAlSAmlkEhIKBHRleHQYAiABKAlSBHRleHQ=');

@$core.Deprecated('Use opponentScoreEventDescriptor instead')
const OpponentScoreEvent$json = {
  '1': 'OpponentScoreEvent',
  '2': [
    {
      '1': 'opponent_player_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'opponentPlayerId'
    },
    {'1': 'score', '3': 2, '4': 1, '5': 5, '10': 'score'},
    {'1': 'correct_count', '3': 3, '4': 1, '5': 5, '10': 'correctCount'},
  ],
};

/// Descriptor for `OpponentScoreEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List opponentScoreEventDescriptor = $convert.base64Decode(
    'ChJPcHBvbmVudFNjb3JlRXZlbnQSLAoSb3Bwb25lbnRfcGxheWVyX2lkGAEgASgJUhBvcHBvbm'
    'VudFBsYXllcklkEhQKBXNjb3JlGAIgASgFUgVzY29yZRIjCg1jb3JyZWN0X2NvdW50GAMgASgF'
    'Ugxjb3JyZWN0Q291bnQ=');

@$core.Deprecated('Use timerEventDescriptor instead')
const TimerEvent$json = {
  '1': 'TimerEvent',
  '2': [
    {'1': 'question_id', '3': 1, '4': 1, '5': 9, '10': 'questionId'},
    {
      '1': 'remaining_seconds',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'remainingSeconds'
    },
  ],
};

/// Descriptor for `TimerEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timerEventDescriptor = $convert.base64Decode(
    'CgpUaW1lckV2ZW50Eh8KC3F1ZXN0aW9uX2lkGAEgASgJUgpxdWVzdGlvbklkEisKEXJlbWFpbm'
    'luZ19zZWNvbmRzGAIgASgFUhByZW1haW5pbmdTZWNvbmRz');

@$core.Deprecated('Use answerResultEventDescriptor instead')
const AnswerResultEvent$json = {
  '1': 'AnswerResultEvent',
  '2': [
    {'1': 'question_id', '3': 1, '4': 1, '5': 9, '10': 'questionId'},
    {
      '1': 'selected_option_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'selectedOptionId'
    },
    {'1': 'correct_option_id', '3': 3, '4': 1, '5': 9, '10': 'correctOptionId'},
    {'1': 'is_correct', '3': 4, '4': 1, '5': 8, '10': 'isCorrect'},
    {'1': 'points_awarded', '3': 5, '4': 1, '5': 5, '10': 'pointsAwarded'},
    {'1': 'running_score', '3': 6, '4': 1, '5': 5, '10': 'runningScore'},
  ],
};

/// Descriptor for `AnswerResultEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List answerResultEventDescriptor = $convert.base64Decode(
    'ChFBbnN3ZXJSZXN1bHRFdmVudBIfCgtxdWVzdGlvbl9pZBgBIAEoCVIKcXVlc3Rpb25JZBIsCh'
    'JzZWxlY3RlZF9vcHRpb25faWQYAiABKAlSEHNlbGVjdGVkT3B0aW9uSWQSKgoRY29ycmVjdF9v'
    'cHRpb25faWQYAyABKAlSD2NvcnJlY3RPcHRpb25JZBIdCgppc19jb3JyZWN0GAQgASgIUglpc0'
    'NvcnJlY3QSJQoOcG9pbnRzX2F3YXJkZWQYBSABKAVSDXBvaW50c0F3YXJkZWQSIwoNcnVubmlu'
    'Z19zY29yZRgGIAEoBVIMcnVubmluZ1Njb3Jl');

@$core.Deprecated('Use matchEndEventDescriptor instead')
const MatchEndEvent$json = {
  '1': 'MatchEndEvent',
  '2': [
    {'1': 'match_id', '3': 1, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'outcome', '3': 2, '4': 1, '5': 9, '10': 'outcome'},
    {'1': 'final_score', '3': 3, '4': 1, '5': 5, '10': 'finalScore'},
    {'1': 'awarded_xp', '3': 4, '4': 1, '5': 5, '10': 'awardedXp'},
    {'1': 'awarded_coins', '3': 5, '4': 1, '5': 5, '10': 'awardedCoins'},
    {
      '1': 'participants',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.synaptix.mobile.FinalParticipant',
      '10': 'participants'
    },
  ],
};

/// Descriptor for `MatchEndEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchEndEventDescriptor = $convert.base64Decode(
    'Cg1NYXRjaEVuZEV2ZW50EhkKCG1hdGNoX2lkGAEgASgJUgdtYXRjaElkEhgKB291dGNvbWUYAi'
    'ABKAlSB291dGNvbWUSHwoLZmluYWxfc2NvcmUYAyABKAVSCmZpbmFsU2NvcmUSHQoKYXdhcmRl'
    'ZF94cBgEIAEoBVIJYXdhcmRlZFhwEiMKDWF3YXJkZWRfY29pbnMYBSABKAVSDGF3YXJkZWRDb2'
    'lucxJDCgxwYXJ0aWNpcGFudHMYBiADKAsyHy50eWNvb24ubW9iaWxlLkZpbmFsUGFydGljaXBh'
    'bnRSDHBhcnRpY2lwYW50cw==');

@$core.Deprecated('Use finalParticipantDescriptor instead')
const FinalParticipant$json = {
  '1': 'FinalParticipant',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'score', '3': 2, '4': 1, '5': 5, '10': 'score'},
    {'1': 'correct', '3': 3, '4': 1, '5': 5, '10': 'correct'},
    {'1': 'wrong', '3': 4, '4': 1, '5': 5, '10': 'wrong'},
    {'1': 'outcome', '3': 5, '4': 1, '5': 9, '10': 'outcome'},
  ],
};

/// Descriptor for `FinalParticipant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List finalParticipantDescriptor = $convert.base64Decode(
    'ChBGaW5hbFBhcnRpY2lwYW50EhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQSFAoFc2Nvcm'
    'UYAiABKAVSBXNjb3JlEhgKB2NvcnJlY3QYAyABKAVSB2NvcnJlY3QSFAoFd3JvbmcYBCABKAVS'
    'BXdyb25nEhgKB291dGNvbWUYBSABKAlSB291dGNvbWU=');

@$core.Deprecated('Use errorEventDescriptor instead')
const ErrorEvent$json = {
  '1': 'ErrorEvent',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ErrorEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorEventDescriptor = $convert.base64Decode(
    'CgpFcnJvckV2ZW50EhIKBGNvZGUYASABKAlSBGNvZGUSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2'
    'FnZQ==');

@$core.Deprecated('Use leaderboardWatchRequestDescriptor instead')
const LeaderboardWatchRequest$json = {
  '1': 'LeaderboardWatchRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'window_size', '3': 3, '4': 1, '5': 5, '10': 'windowSize'},
  ],
};

/// Descriptor for `LeaderboardWatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaderboardWatchRequestDescriptor = $convert.base64Decode(
    'ChdMZWFkZXJib2FyZFdhdGNoUmVxdWVzdBIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEh'
    'IKBG1vZGUYAiABKAlSBG1vZGUSHwoLd2luZG93X3NpemUYAyABKAVSCndpbmRvd1NpemU=');

@$core.Deprecated('Use leaderboardUpdateDescriptor instead')
const LeaderboardUpdate$json = {
  '1': 'LeaderboardUpdate',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'player_rank', '3': 2, '4': 1, '5': 5, '10': 'playerRank'},
    {'1': 'player_score', '3': 3, '4': 1, '5': 5, '10': 'playerScore'},
    {
      '1': 'nearby',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.synaptix.mobile.LeaderboardEntry',
      '10': 'nearby'
    },
    {'1': 'snapshot_at_ms', '3': 5, '4': 1, '5': 3, '10': 'snapshotAtMs'},
  ],
};

/// Descriptor for `LeaderboardUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaderboardUpdateDescriptor = $convert.base64Decode(
    'ChFMZWFkZXJib2FyZFVwZGF0ZRIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEh8KC3BsYX'
    'llcl9yYW5rGAIgASgFUgpwbGF5ZXJSYW5rEiEKDHBsYXllcl9zY29yZRgDIAEoBVILcGxheWVy'
    'U2NvcmUSNwoGbmVhcmJ5GAQgAygLMh8udHljb29uLm1vYmlsZS5MZWFkZXJib2FyZEVudHJ5Ug'
    'ZuZWFyYnkSJAoOc25hcHNob3RfYXRfbXMYBSABKANSDHNuYXBzaG90QXRNcw==');

@$core.Deprecated('Use leaderboardEntryDescriptor instead')
const LeaderboardEntry$json = {
  '1': 'LeaderboardEntry',
  '2': [
    {'1': 'rank', '3': 1, '4': 1, '5': 5, '10': 'rank'},
    {'1': 'player_id', '3': 2, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'handle', '3': 3, '4': 1, '5': 9, '10': 'handle'},
    {'1': 'score', '3': 4, '4': 1, '5': 5, '10': 'score'},
    {'1': 'country', '3': 5, '4': 1, '5': 9, '10': 'country'},
  ],
};

/// Descriptor for `LeaderboardEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaderboardEntryDescriptor = $convert.base64Decode(
    'ChBMZWFkZXJib2FyZEVudHJ5EhIKBHJhbmsYASABKAVSBHJhbmsSGwoJcGxheWVyX2lkGAIgAS'
    'gJUghwbGF5ZXJJZBIWCgZoYW5kbGUYAyABKAlSBmhhbmRsZRIUCgVzY29yZRgEIAEoBVIFc2Nv'
    'cmUSGAoHY291bnRyeRgFIAEoCVIHY291bnRyeQ==');

@$core.Deprecated('Use watchMatchmakingRequestDescriptor instead')
const WatchMatchmakingRequest$json = {
  '1': 'WatchMatchmakingRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'tier_id', '3': 3, '4': 1, '5': 5, '10': 'tierId'},
  ],
};

/// Descriptor for `WatchMatchmakingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchMatchmakingRequestDescriptor =
    $convert.base64Decode(
        'ChdXYXRjaE1hdGNobWFraW5nUmVxdWVzdBIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEh'
        'IKBG1vZGUYAiABKAlSBG1vZGUSFwoHdGllcl9pZBgDIAEoBVIGdGllcklk');

@$core.Deprecated('Use matchmakingStatusUpdateDescriptor instead')
const MatchmakingStatusUpdate$json = {
  '1': 'MatchmakingStatusUpdate',
  '2': [
    {'1': 'ticket_id', '3': 1, '4': 1, '5': 9, '10': 'ticketId'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'queue_position', '3': 3, '4': 1, '5': 5, '10': 'queuePosition'},
    {'1': 'match_id', '3': 4, '4': 1, '5': 9, '10': 'matchId'},
    {'1': 'opponent_id', '3': 5, '4': 1, '5': 9, '10': 'opponentId'},
    {'1': 'opponent_handle', '3': 6, '4': 1, '5': 9, '10': 'opponentHandle'},
  ],
};

/// Descriptor for `MatchmakingStatusUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchmakingStatusUpdateDescriptor = $convert.base64Decode(
    'ChdNYXRjaG1ha2luZ1N0YXR1c1VwZGF0ZRIbCgl0aWNrZXRfaWQYASABKAlSCHRpY2tldElkEh'
    'YKBnN0YXR1cxgCIAEoCVIGc3RhdHVzEiUKDnF1ZXVlX3Bvc2l0aW9uGAMgASgFUg1xdWV1ZVBv'
    'c2l0aW9uEhkKCG1hdGNoX2lkGAQgASgJUgdtYXRjaElkEh8KC29wcG9uZW50X2lkGAUgASgJUg'
    'pvcHBvbmVudElkEicKD29wcG9uZW50X2hhbmRsZRgGIAEoCVIOb3Bwb25lbnRIYW5kbGU=');

@$core.Deprecated('Use cancelMatchmakingRequestDescriptor instead')
const CancelMatchmakingRequest$json = {
  '1': 'CancelMatchmakingRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'ticket_id', '3': 2, '4': 1, '5': 9, '10': 'ticketId'},
  ],
};

/// Descriptor for `CancelMatchmakingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelMatchmakingRequestDescriptor =
    $convert.base64Decode(
        'ChhDYW5jZWxNYXRjaG1ha2luZ1JlcXVlc3QSGwoJcGxheWVyX2lkGAEgASgJUghwbGF5ZXJJZB'
        'IbCgl0aWNrZXRfaWQYAiABKAlSCHRpY2tldElk');

@$core.Deprecated('Use cancelMatchmakingResponseDescriptor instead')
const CancelMatchmakingResponse$json = {
  '1': 'CancelMatchmakingResponse',
  '2': [
    {'1': 'cancelled', '3': 1, '4': 1, '5': 8, '10': 'cancelled'},
    {'1': 'ticket_id', '3': 2, '4': 1, '5': 9, '10': 'ticketId'},
  ],
};

/// Descriptor for `CancelMatchmakingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelMatchmakingResponseDescriptor =
    $convert.base64Decode(
        'ChlDYW5jZWxNYXRjaG1ha2luZ1Jlc3BvbnNlEhwKCWNhbmNlbGxlZBgBIAEoCFIJY2FuY2VsbG'
        'VkEhsKCXRpY2tldF9pZBgCIAEoCVIIdGlja2V0SWQ=');
