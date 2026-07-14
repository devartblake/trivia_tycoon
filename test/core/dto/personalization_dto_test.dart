import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/dto/personalization_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // PlayerMindProfileDto
  // -------------------------------------------------------------------------

  group('PlayerMindProfileDto defaults', () {
    test('fromJson empty map: playerId empty', () {
      final p = PlayerMindProfileDto.fromJson({});
      expect(p.playerId, '');
    });

    test('fromJson empty map: confidenceLevel 0.5', () {
      expect(PlayerMindProfileDto.fromJson({}).confidenceLevel, 0.5);
    });

    test('fromJson empty map: preferredPace steady', () {
      expect(PlayerMindProfileDto.fromJson({}).preferredPace, 'steady');
    });

    test('fromJson empty map: archetype steady_learner', () {
      expect(PlayerMindProfileDto.fromJson({}).archetype, 'steady_learner');
    });

    test('fromJson empty map: personalizationEnabled true', () {
      expect(PlayerMindProfileDto.fromJson({}).personalizationEnabled, isTrue);
    });

    test('fromJson empty map: sidecarScoringEnabled true', () {
      expect(PlayerMindProfileDto.fromJson({}).sidecarScoringEnabled, isTrue);
    });

    test('fromJson empty map: churnRiskScore 0.0', () {
      expect(PlayerMindProfileDto.fromJson({}).churnRiskScore, 0.0);
    });

    test('fromJson empty map: categoryStrengths empty', () {
      expect(PlayerMindProfileDto.fromJson({}).categoryStrengths, isEmpty);
    });

    test('fromJson empty map: categoryWeaknesses empty', () {
      expect(PlayerMindProfileDto.fromJson({}).categoryWeaknesses, isEmpty);
    });

    test('fromJson empty map: lastCalculatedAt null', () {
      expect(PlayerMindProfileDto.fromJson({}).lastCalculatedAt, isNull);
    });
  });

  group('PlayerMindProfileDto.fromJson values', () {
    test('parses playerId', () {
      final p = PlayerMindProfileDto.fromJson({'playerId': 'p1'});
      expect(p.playerId, 'p1');
    });

    test('parses confidenceLevel', () {
      final p = PlayerMindProfileDto.fromJson({'confidenceLevel': 0.8});
      expect(p.confidenceLevel, closeTo(0.8, 0.001));
    });

    test('parses categoryStrengths as Map<String,double>', () {
      final p = PlayerMindProfileDto.fromJson({
        'categoryStrengths': {'math': 0.9, 'science': 0.7},
      });
      expect(p.categoryStrengths['math'], closeTo(0.9, 0.001));
    });

    test('categoryStrengths empty when non-Map', () {
      final p =
          PlayerMindProfileDto.fromJson({'categoryStrengths': 'not-a-map'});
      expect(p.categoryStrengths, isEmpty);
    });

    test('lastCalculatedAt stored when present', () {
      final p =
          PlayerMindProfileDto.fromJson({'lastCalculatedAt': '2025-01-01'});
      expect(p.lastCalculatedAt, '2025-01-01');
    });
  });

  group('PlayerMindProfileDto computed properties', () {
    test('shouldShowRetentionNudge true for churnRiskScore = 0.8', () {
      final p = PlayerMindProfileDto.fromJson({'churnRiskScore': 0.8});
      expect(p.shouldShowRetentionNudge, isTrue);
    });

    test('shouldShowRetentionNudge true for churnRiskScore > 0.8', () {
      final p = PlayerMindProfileDto.fromJson({'churnRiskScore': 0.95});
      expect(p.shouldShowRetentionNudge, isTrue);
    });

    test('shouldShowRetentionNudge false for churnRiskScore = 0.79', () {
      final p = PlayerMindProfileDto.fromJson({'churnRiskScore': 0.79});
      expect(p.shouldShowRetentionNudge, isFalse);
    });

    test('shouldDisableHardMode true for frustrationRiskScore = 0.75', () {
      final p = PlayerMindProfileDto.fromJson({'frustrationRiskScore': 0.75});
      expect(p.shouldDisableHardMode, isTrue);
    });

    test('shouldDisableHardMode false for frustrationRiskScore = 0.74', () {
      final p = PlayerMindProfileDto.fromJson({'frustrationRiskScore': 0.74});
      expect(p.shouldDisableHardMode, isFalse);
    });

    test('shouldReducePushBadges true for notificationFatigueScore = 0.7', () {
      final p =
          PlayerMindProfileDto.fromJson({'notificationFatigueScore': 0.7});
      expect(p.shouldReducePushBadges, isTrue);
    });

    test('shouldReducePushBadges false for notificationFatigueScore = 0.69',
        () {
      final p =
          PlayerMindProfileDto.fromJson({'notificationFatigueScore': 0.69});
      expect(p.shouldReducePushBadges, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // CoachBriefDto
  // -------------------------------------------------------------------------

  group('CoachBriefDto', () {
    test('fromJson parses title and message', () {
      final b = CoachBriefDto.fromJson(
          {'title': 'Keep going!', 'message': 'You are doing great.'});
      expect(b.title, 'Keep going!');
      expect(b.message, 'You are doing great.');
    });

    test('fromJson id null when absent', () {
      final b = CoachBriefDto.fromJson({'title': 'X', 'message': 'Y'});
      expect(b.id, isNull);
    });

    test('fromJson tone defaults encouraging when absent', () {
      final b = CoachBriefDto.fromJson({'title': 'X', 'message': 'Y'});
      expect(b.tone, 'encouraging');
    });

    test('fromJson explicit tone stored', () {
      final b = CoachBriefDto.fromJson(
          {'title': 'X', 'message': 'Y', 'tone': 'urgent'});
      expect(b.tone, 'urgent');
    });
  });

  // -------------------------------------------------------------------------
  // PlayerRecommendationDto
  // -------------------------------------------------------------------------

  group('PlayerRecommendationDto', () {
    test('fromJson parses id and type', () {
      final r = PlayerRecommendationDto.fromJson({'id': 'r1', 'type': 'quiz'});
      expect(r.id, 'r1');
      expect(r.type, 'quiz');
    });

    test('fromJson source defaults sidecar', () {
      final r = PlayerRecommendationDto.fromJson({'id': 'r1', 'type': 'x'});
      expect(r.source, 'sidecar');
    });

    test('fromJson priority defaults 1', () {
      final r = PlayerRecommendationDto.fromJson({'id': 'r1', 'type': 'x'});
      expect(r.priority, 1);
    });

    test('fromJson score defaults 0.0', () {
      final r = PlayerRecommendationDto.fromJson({'id': 'r1', 'type': 'x'});
      expect(r.score, 0.0);
    });

    test('fromJson payload defaults empty', () {
      final r = PlayerRecommendationDto.fromJson({'id': 'r1', 'type': 'x'});
      expect(r.payload, isEmpty);
    });

    test('fromJson expiresAt null when absent', () {
      final r = PlayerRecommendationDto.fromJson({'id': 'r1', 'type': 'x'});
      expect(r.expiresAt, isNull);
    });

    test('fromJson explicit priority stored', () {
      final r = PlayerRecommendationDto.fromJson(
          {'id': 'r1', 'type': 'x', 'priority': 5});
      expect(r.priority, 5);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerHomePersonalizationDto
  // -------------------------------------------------------------------------

  group('PlayerHomePersonalizationDto', () {
    test('fromJson recommendedMode defaults solo', () {
      final d = PlayerHomePersonalizationDto.fromJson({'playerId': 'p1'});
      expect(d.recommendedMode, 'solo');
    });

    test('fromJson recommendedDifficulty defaults medium', () {
      final d = PlayerHomePersonalizationDto.fromJson({'playerId': 'p1'});
      expect(d.recommendedDifficulty, 'medium');
    });

    test('fromJson recommendations empty when absent', () {
      final d = PlayerHomePersonalizationDto.fromJson({'playerId': 'p1'});
      expect(d.recommendations, isEmpty);
    });

    test('fromJson recommendations deserialized', () {
      final d = PlayerHomePersonalizationDto.fromJson({
        'playerId': 'p1',
        'recommendations': [
          {'id': 'r1', 'type': 'quiz'},
          {'id': 'r2', 'type': 'lesson'},
        ],
      });
      expect(d.recommendations.length, 2);
      expect(d.recommendations.first, isA<PlayerRecommendationDto>());
    });

    test('fromJson coachBrief null when absent', () {
      final d = PlayerHomePersonalizationDto.fromJson({'playerId': 'p1'});
      expect(d.coachBrief, isNull);
    });

    test('fromJson coachBrief deserialized when present', () {
      final d = PlayerHomePersonalizationDto.fromJson({
        'playerId': 'p1',
        'coachBrief': {'title': 'Go!', 'message': 'Keep it up'},
      });
      expect(d.coachBrief, isA<CoachBriefDto>());
      expect(d.coachBrief!.title, 'Go!');
    });
  });

  group('PlayerHomePersonalizationDto.topRecommendations', () {
    test('empty recommendations → empty topRecommendations', () {
      final d = PlayerHomePersonalizationDto.fromJson({'playerId': 'p1'});
      expect(d.topRecommendations, isEmpty);
    });

    test('5 recommendations → top 3 by priority', () {
      final d = PlayerHomePersonalizationDto.fromJson({
        'playerId': 'p1',
        'recommendations': [
          {'id': 'r5', 'type': 'x', 'priority': 5},
          {'id': 'r2', 'type': 'x', 'priority': 2},
          {'id': 'r1', 'type': 'x', 'priority': 1},
          {'id': 'r3', 'type': 'x', 'priority': 3},
          {'id': 'r4', 'type': 'x', 'priority': 4},
        ],
      });
      final top = d.topRecommendations;
      expect(top.length, 3);
      expect(top[0].priority, 1);
      expect(top[1].priority, 2);
      expect(top[2].priority, 3);
    });

    test('2 recommendations → returns both', () {
      final d = PlayerHomePersonalizationDto.fromJson({
        'playerId': 'p1',
        'recommendations': [
          {'id': 'r1', 'type': 'x', 'priority': 2},
          {'id': 'r2', 'type': 'x', 'priority': 1},
        ],
      });
      expect(d.topRecommendations.length, 2);
      expect(d.topRecommendations.first.priority, 1);
    });
  });

  // -------------------------------------------------------------------------
  // ExperimentAssignmentDto
  // -------------------------------------------------------------------------

  group('ExperimentAssignmentDto', () {
    test('fromJson parses experimentKey', () {
      final e = ExperimentAssignmentDto.fromJson(
          {'experimentKey': 'exp_A', 'variantKey': 'v1'});
      expect(e.experimentKey, 'exp_A');
    });

    test('fromJson variantKey defaults control', () {
      final e = ExperimentAssignmentDto.fromJson({'experimentKey': 'x'});
      expect(e.variantKey, 'control');
    });

    test('fromJson isControl defaults true', () {
      final e = ExperimentAssignmentDto.fromJson({'experimentKey': 'x'});
      expect(e.isControl, isTrue);
    });

    test('fromJson config defaults empty', () {
      final e = ExperimentAssignmentDto.fromJson({'experimentKey': 'x'});
      expect(e.config, isEmpty);
    });

    test('getBool returns bool from config', () {
      final e = ExperimentAssignmentDto.fromJson({
        'experimentKey': 'x',
        'config': {'flag': true},
      });
      expect(e.getBool('flag'), isTrue);
    });

    test('getBool returns fallback when key absent', () {
      final e = ExperimentAssignmentDto.fromJson(
          {'experimentKey': 'x', 'config': {}});
      expect(e.getBool('missing', fallback: true), isTrue);
    });

    test('getBool returns fallback when wrong type', () {
      final e = ExperimentAssignmentDto.fromJson({
        'experimentKey': 'x',
        'config': {'flag': 'not-a-bool'},
      });
      expect(e.getBool('flag', fallback: false), isFalse);
    });

    test('getString returns string from config', () {
      final e = ExperimentAssignmentDto.fromJson({
        'experimentKey': 'x',
        'config': {'label': 'hello'},
      });
      expect(e.getString('label'), 'hello');
    });

    test('getString returns fallback when wrong type', () {
      final e = ExperimentAssignmentDto.fromJson({
        'experimentKey': 'x',
        'config': {'label': 42},
      });
      expect(e.getString('label', fallback: 'default'), 'default');
    });

    test('getInt returns int from config', () {
      final e = ExperimentAssignmentDto.fromJson({
        'experimentKey': 'x',
        'config': {'count': 5},
      });
      expect(e.getInt('count'), 5);
    });

    test('getInt returns fallback when wrong type', () {
      final e = ExperimentAssignmentDto.fromJson({
        'experimentKey': 'x',
        'config': {'count': 'five'},
      });
      expect(e.getInt('count', fallback: 99), 99);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerExperimentsDto
  // -------------------------------------------------------------------------

  group('PlayerExperimentsDto', () {
    test('fromJson parses playerId', () {
      final d =
          PlayerExperimentsDto.fromJson({'playerId': 'p1', 'assignments': []});
      expect(d.playerId, 'p1');
    });

    test('fromJson assignments empty when absent', () {
      final d = PlayerExperimentsDto.fromJson({'playerId': 'p1'});
      expect(d.assignments, isEmpty);
    });

    test('fromJson assignments deserialized', () {
      final d = PlayerExperimentsDto.fromJson({
        'playerId': 'p1',
        'assignments': [
          {'experimentKey': 'exp1', 'variantKey': 'v1'},
        ],
      });
      expect(d.assignments.length, 1);
      expect(d.assignments.first, isA<ExperimentAssignmentDto>());
    });
  });

  // -------------------------------------------------------------------------
  // SingleExperimentResultDto
  // -------------------------------------------------------------------------

  group('SingleExperimentResultDto', () {
    test('fromJson enrolled defaults false', () {
      final d = SingleExperimentResultDto.fromJson({'experimentKey': 'x'});
      expect(d.enrolled, isFalse);
    });

    test('fromJson parses experimentKey', () {
      final d = SingleExperimentResultDto.fromJson({'experimentKey': 'exp_B'});
      expect(d.experimentKey, 'exp_B');
    });

    test('fromJson assignment null when absent', () {
      final d = SingleExperimentResultDto.fromJson({'experimentKey': 'x'});
      expect(d.assignment, isNull);
    });

    test('fromJson assignment deserialized when present', () {
      final d = SingleExperimentResultDto.fromJson({
        'experimentKey': 'x',
        'enrolled': true,
        'assignment': {'experimentKey': 'x', 'variantKey': 'treatment'},
      });
      expect(d.assignment, isA<ExperimentAssignmentDto>());
      expect(d.assignment!.variantKey, 'treatment');
    });
  });

  // -------------------------------------------------------------------------
  // BehaviourEventDto
  // -------------------------------------------------------------------------

  group('BehaviourEventDto', () {
    test('constructor auto-sets occurredAt when not provided', () {
      final e = BehaviourEventDto(eventType: 'quiz_start');
      expect(e.occurredAt, isNotEmpty);
    });

    test('constructor stores explicit occurredAt', () {
      final e = BehaviourEventDto(
        eventType: 'quiz_end',
        occurredAt: '2025-01-01T00:00:00.000Z',
      );
      expect(e.occurredAt, '2025-01-01T00:00:00.000Z');
    });

    test('toJson contains eventType', () {
      final j = BehaviourEventDto(eventType: 'session_start').toJson();
      expect(j['eventType'], 'session_start');
    });

    test('toJson contains eventSource', () {
      final j = BehaviourEventDto(eventType: 'x').toJson();
      expect(j.containsKey('eventSource'), isTrue);
    });

    test('toJson contains occurredAt', () {
      final j = BehaviourEventDto(eventType: 'x').toJson();
      expect(j.containsKey('occurredAt'), isTrue);
    });

    test('toJson category omitted when null', () {
      final j = BehaviourEventDto(eventType: 'x').toJson();
      expect(j.containsKey('category'), isFalse);
    });

    test('toJson category included when non-null', () {
      final j = BehaviourEventDto(eventType: 'x', category: 'science').toJson();
      expect(j['category'], 'science');
    });

    test('toJson difficulty omitted when null', () {
      final j = BehaviourEventDto(eventType: 'x').toJson();
      expect(j.containsKey('difficulty'), isFalse);
    });

    test('toJson mode omitted when null', () {
      final j = BehaviourEventDto(eventType: 'x').toJson();
      expect(j.containsKey('mode'), isFalse);
    });

    test('toJson metadata omitted when empty', () {
      final j = BehaviourEventDto(eventType: 'x').toJson();
      expect(j.containsKey('metadata'), isFalse);
    });

    test('toJson metadata included when non-empty', () {
      final j = BehaviourEventDto(
        eventType: 'x',
        metadata: {'score': 100},
      ).toJson();
      expect(j['metadata'], {'score': 100});
    });
  });
}
