import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/models/question_type.dart' as qtype;
import 'package:trivia_tycoon/game/models/question_difficulty.dart' as qdiff;

// ---------------------------------------------------------------------------
// Helper — minimal question via direct constructor
// ---------------------------------------------------------------------------

QuestionModel _q({
  String id = 'q1',
  String category = 'science',
  String question = 'What is H2O?',
  List<Answer> answers = const [],
  String correctAnswer = 'Water',
  List<String> options = const ['Water', 'Fire', 'Earth'],
  String type = 'multiple_choice',
  int difficulty = 1,
  int correctIndex = 0,
  String? imageUrl,
  String? videoUrl,
  String? audioUrl,
  String? audioTranscript,
  int? audioDuration,
  String? powerUpHint,
  String? powerUpType,
  bool showHint = false,
  List<String>? reducedOptions,
  int? multiplier,
  bool isBoostedTime = false,
  bool isShielded = false,
  List<String>? tags,
  Map<String, String>? optionIdByText,
}) {
  return QuestionModel(
    id: id,
    category: category,
    question: question,
    answers: answers,
    correctAnswer: correctAnswer,
    options: options,
    type: qtype.QuestionTypeExtension.fromString(type),
    difficulty: qdiff.QuestionDifficultyExtension.fromInt(difficulty),
    correctIndex: correctIndex,
    imageUrl: imageUrl,
    videoUrl: videoUrl,
    audioUrl: audioUrl,
    audioTranscript: audioTranscript,
    audioDuration: audioDuration,
    powerUpHint: powerUpHint,
    powerUpType: powerUpType,
    showHint: showHint,
    reducedOptions: reducedOptions,
    multiplier: multiplier,
    isBoostedTime: isBoostedTime,
    isShielded: isShielded,
    tags: tags,
    optionIdByText: optionIdByText,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // Answer — basic tests
  // -------------------------------------------------------------------------

  group('Answer — fromJson / toJson', () {
    test('fromJson parses text and isCorrect', () {
      final a = Answer.fromJson({'text': 'Paris', 'isCorrect': true});
      expect(a.text, 'Paris');
      expect(a.isCorrect, isTrue);
    });

    test('fromJson defaults isCorrect to false', () {
      final a = Answer.fromJson({'text': 'Berlin'});
      expect(a.isCorrect, isFalse);
    });

    test('toJson round-trips text and isCorrect', () {
      final a = Answer(text: 'London', isCorrect: false);
      final json = a.toJson();
      expect(json['text'], 'London');
      expect(json['isCorrect'], isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel.fromJson — answers list path
  // -------------------------------------------------------------------------

  group('QuestionModel.fromJson — answers list path', () {
    test('parses options from answer texts', () {
      final json = {
        'id': 'q1',
        'category': 'geo',
        'question': 'Capital of France?',
        'answers': [
          {'text': 'Paris', 'isCorrect': true, 'optionId': 'opt_a'},
          {'text': 'London', 'isCorrect': false, 'optionId': 'opt_b'},
          {'text': 'Berlin', 'isCorrect': false, 'optionId': 'opt_c'},
        ],
        'type': 'multiple_choice',
        'difficulty': 1,
      };

      final q = QuestionModel.fromJson(json);

      expect(q.options, ['Paris', 'London', 'Berlin']);
    });

    test('sets correctIndex from isCorrect field', () {
      final json = {
        'answers': [
          {'text': 'A', 'isCorrect': false, 'optionId': 'o1'},
          {'text': 'B', 'isCorrect': true, 'optionId': 'o2'},
          {'text': 'C', 'isCorrect': false, 'optionId': 'o3'},
        ],
      };
      final q = QuestionModel.fromJson(json);
      expect(q.correctIndex, 1);
    });

    test('sets correctIndex from correctAnswer matching optionId', () {
      final json = {
        'answers': [
          {'text': 'Water', 'isCorrect': false, 'optionId': 'opt_1'},
          {'text': 'Fire', 'isCorrect': false, 'optionId': 'opt_2'},
        ],
        'correctAnswer': 'opt_1',
      };
      final q = QuestionModel.fromJson(json);
      expect(q.correctIndex, 0);
      expect(q.correctAnswer, 'opt_1');
    });

    test('sets correctIndex from correctOptionId', () {
      final json = {
        'answers': [
          {'text': 'X', 'isCorrect': false, 'optionId': 'id_x'},
          {'text': 'Y', 'isCorrect': false, 'optionId': 'id_y'},
        ],
        'correctOptionId': 'id_y',
      };
      final q = QuestionModel.fromJson(json);
      expect(q.correctIndex, 1);
    });

    test('sets correctIndex from expectedAnswer', () {
      final json = {
        'answers': [
          {'text': 'One', 'isCorrect': false, 'optionId': 'a'},
          {'text': 'Two', 'isCorrect': false, 'optionId': 'b'},
        ],
        'expectedAnswer': 'b',
      };
      final q = QuestionModel.fromJson(json);
      expect(q.correctIndex, 1);
    });

    test('correctIndex is -1 when no match found', () {
      final json = {
        'answers': [
          {'text': 'X', 'isCorrect': false, 'optionId': 'x'},
        ],
      };
      final q = QuestionModel.fromJson(json);
      expect(q.correctIndex, -1);
    });

    test('builds optionIdByText from answers', () {
      final json = {
        'answers': [
          {'text': 'Paris', 'isCorrect': true, 'optionId': 'opt_paris'},
          {'text': 'Rome', 'isCorrect': false, 'optionId': 'opt_rome'},
        ],
      };
      final q = QuestionModel.fromJson(json);
      expect(q.optionIdByText!['Paris'], 'opt_paris');
      expect(q.optionIdByText!['Rome'], 'opt_rome');
    });

    test('uses id field as optionId fallback in answers', () {
      final json = {
        'answers': [
          {'text': 'Alpha', 'isCorrect': true, 'id': 'id_alpha'},
        ],
      };
      final q = QuestionModel.fromJson(json);
      expect(q.optionIdByText!['Alpha'], 'id_alpha');
    });

    test('parses id from questionId fallback', () {
      final json = {'questionId': 'qid_5', 'answers': []};
      final q = QuestionModel.fromJson(json);
      expect(q.id, 'qid_5');
    });

    test('parses question text from text fallback', () {
      final json = {'text': 'What is 2+2?', 'answers': []};
      final q = QuestionModel.fromJson(json);
      expect(q.question, 'What is 2+2?');
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel.fromJson — options list path (no answers key)
  // -------------------------------------------------------------------------

  group('QuestionModel.fromJson — options list path', () {
    test('parses options from string list', () {
      final json = {
        'id': 'q2',
        'options': ['One', 'Two', 'Three'],
        'correctAnswer': 'Two',
      };
      final q = QuestionModel.fromJson(json);
      expect(q.options, ['One', 'Two', 'Three']);
      expect(q.correctIndex, 1);
    });

    test('parses options from map list (text/label fields)', () {
      final json = {
        'id': 'q3',
        'options': [
          {'text': 'Alpha', 'optionId': 'a'},
          {'label': 'Beta', 'optionId': 'b'},
        ],
        'correctAnswer': 'b',
      };
      final q = QuestionModel.fromJson(json);
      expect(q.options, ['Alpha', 'Beta']);
      expect(q.correctIndex, 1);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel.fromJson — optional fields
  // -------------------------------------------------------------------------

  group('QuestionModel.fromJson — optional fields', () {
    test('parses imageUrl from mediaKey fallback', () {
      final json = {'mediaKey': 'img_001.png', 'answers': []};
      final q = QuestionModel.fromJson(json);
      expect(q.imageUrl, 'img_001.png');
    });

    test('parses audioUrl', () {
      final json = {'audioUrl': 'audio/q1.mp3', 'answers': []};
      final q = QuestionModel.fromJson(json);
      expect(q.audioUrl, 'audio/q1.mp3');
    });

    test('parses tags list', () {
      final json = {
        'tags': ['science', 'biology'],
        'answers': []
      };
      final q = QuestionModel.fromJson(json);
      expect(q.tags, ['science', 'biology']);
    });

    test('tags is null when absent', () {
      final q = QuestionModel.fromJson({'answers': []});
      expect(q.tags, isNull);
    });

    test('parses reducedOptions', () {
      final json = {
        'reducedOptions': ['A', 'C'],
        'answers': []
      };
      final q = QuestionModel.fromJson(json);
      expect(q.reducedOptions, ['A', 'C']);
    });

    test('parses isBoostedTime and isShielded booleans', () {
      final json = {'isBoostedTime': true, 'isShielded': true, 'answers': []};
      final q = QuestionModel.fromJson(json);
      expect(q.isBoostedTime, isTrue);
      expect(q.isShielded, isTrue);
    });

    test('defaults category to General when absent', () {
      final q = QuestionModel.fromJson({'answers': []});
      expect(q.category, 'General');
    });

    test('defaults type to multiple_choice when absent', () {
      final q = QuestionModel.fromJson({'answers': []});
      expect(q.type, 'multiple_choice');
    });
  });

  // -------------------------------------------------------------------------
  // _parseDifficulty
  // -------------------------------------------------------------------------

  group('QuestionModel.fromJson — _parseDifficulty', () {
    test('numeric value is preserved as-is', () {
      final q = QuestionModel.fromJson({'difficulty': 3, 'answers': []});
      expect(q.difficulty, 3);
    });

    test('"easy" string maps to 1', () {
      final q = QuestionModel.fromJson({'difficulty': 'easy', 'answers': []});
      expect(q.difficulty, 1);
    });

    test('"medium" string maps to 2', () {
      final q = QuestionModel.fromJson({'difficulty': 'medium', 'answers': []});
      expect(q.difficulty, 2);
    });

    test('"hard" string maps to 3', () {
      final q = QuestionModel.fromJson({'difficulty': 'hard', 'answers': []});
      expect(q.difficulty, 3);
    });

    test('"expert" string maps to 4', () {
      final q = QuestionModel.fromJson({'difficulty': 'expert', 'answers': []});
      expect(q.difficulty, 4);
    });

    test('numeric string "3" parses to 3', () {
      final q = QuestionModel.fromJson({'difficulty': '3', 'answers': []});
      expect(q.difficulty, 3);
    });

    test('unrecognised string defaults to 1', () {
      final q =
          QuestionModel.fromJson({'difficulty': 'unknown', 'answers': []});
      expect(q.difficulty, 1);
    });

    test('null difficulty defaults to 1', () {
      final q = QuestionModel.fromJson({'answers': []});
      expect(q.difficulty, 1);
    });

    test('case-insensitive matching for Easy', () {
      final q = QuestionModel.fromJson({'difficulty': 'Easy', 'answers': []});
      expect(q.difficulty, 1);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel — computed properties
  // -------------------------------------------------------------------------

  group('QuestionModel — hasAudio / hasVideo / hasImage / mediaType', () {
    test('hasAudio is true when audioUrl is non-empty', () {
      expect(_q(audioUrl: 'audio.mp3').hasAudio, isTrue);
    });

    test('hasAudio is false when audioUrl is null', () {
      expect(_q().hasAudio, isFalse);
    });

    test('hasAudio is false when audioUrl is empty string', () {
      expect(_q(audioUrl: '').hasAudio, isFalse);
    });

    test('hasVideo is true when videoUrl is non-empty', () {
      expect(_q(videoUrl: 'video.mp4').hasVideo, isTrue);
    });

    test('hasImage is true when imageUrl is non-empty', () {
      expect(_q(imageUrl: 'img.png').hasImage, isTrue);
    });

    test('mediaType is "audio" when audioUrl is set', () {
      expect(_q(audioUrl: 'a.mp3').mediaType, 'audio');
    });

    test('mediaType is "video" when videoUrl is set (no audio)', () {
      expect(_q(videoUrl: 'v.mp4').mediaType, 'video');
    });

    test('mediaType is "image" when imageUrl is set (no audio/video)', () {
      expect(_q(imageUrl: 'i.png').mediaType, 'image');
    });

    test('mediaType is "text" when no media is set', () {
      expect(_q().mediaType, 'text');
    });

    test('audio takes priority over video in mediaType', () {
      expect(_q(audioUrl: 'a.mp3', videoUrl: 'v.mp4').mediaType, 'audio');
    });

    test('isMultimedia is true when any media url is set', () {
      expect(_q(audioUrl: 'a.mp3').isMultimedia, isTrue);
      expect(_q(videoUrl: 'v.mp4').isMultimedia, isTrue);
      expect(_q(imageUrl: 'i.png').isMultimedia, isTrue);
    });

    test('isMultimedia is false when no media urls', () {
      expect(_q().isMultimedia, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel — checkAnswer / isCorrectAnswer
  // -------------------------------------------------------------------------

  group('QuestionModel — checkAnswer', () {
    test('returns true when selectedIndex equals correctIndex', () {
      expect(_q(correctIndex: 2).checkAnswer(2), isTrue);
    });

    test('returns false when selectedIndex differs from correctIndex', () {
      expect(_q(correctIndex: 0).checkAnswer(1), isFalse);
    });
  });

  group('QuestionModel — isCorrectAnswer', () {
    test('returns true when selectedAnswer equals correctAnswer', () {
      expect(_q(correctAnswer: 'Water').isCorrectAnswer('Water'), isTrue);
    });

    test('returns false when selectedAnswer differs', () {
      expect(_q(correctAnswer: 'Water').isCorrectAnswer('Fire'), isFalse);
    });

    test('is case-sensitive', () {
      expect(_q(correctAnswer: 'Water').isCorrectAnswer('water'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel — optionIdForAnswer / answerTextForOptionId
  // -------------------------------------------------------------------------

  group('QuestionModel — optionIdForAnswer', () {
    test('returns mapped optionId when found', () {
      final q = _q(optionIdByText: {'Water': 'opt_w', 'Fire': 'opt_f'});
      expect(q.optionIdForAnswer('Water'), 'opt_w');
    });

    test('returns selectedAnswer as-is when not in map', () {
      final q = _q(optionIdByText: {'Water': 'opt_w'});
      expect(q.optionIdForAnswer('Unknown'), 'Unknown');
    });

    test('returns selectedAnswer when optionIdByText is null', () {
      final q = _q();
      expect(q.optionIdForAnswer('Anything'), 'Anything');
    });
  });

  group('QuestionModel — answerTextForOptionId', () {
    test('returns text for known optionId', () {
      final q = _q(optionIdByText: {'Paris': 'opt_p', 'Rome': 'opt_r'});
      expect(q.answerTextForOptionId('opt_r'), 'Rome');
    });

    test('returns optionId when text not found in map', () {
      final q = _q(optionIdByText: {'Paris': 'opt_p'});
      expect(q.answerTextForOptionId('opt_unknown'), 'opt_unknown');
    });

    test('returns optionId when optionIdByText is null', () {
      final q = _q();
      expect(q.answerTextForOptionId('anything'), 'anything');
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel.toJson
  // -------------------------------------------------------------------------

  group('QuestionModel.toJson', () {
    test('serializes all scalar fields', () {
      final q = _q(
        id: 'q_json',
        category: 'math',
        question: '1+1?',
        correctAnswer: '2',
        type: 'true_false',
        difficulty: 2,
        correctIndex: 0,
        showHint: true,
        isBoostedTime: true,
        isShielded: false,
      );
      final json = q.toJson();

      expect(json['id'], 'q_json');
      expect(json['category'], 'math');
      expect(json['question'], '1+1?');
      expect(json['correctAnswer'], '2');
      expect(json['type'], 'true_false');
      expect(json['difficulty'], 2);
      expect(json['correctIndex'], 0);
      expect(json['showHint'], isTrue);
      expect(json['isBoostedTime'], isTrue);
      expect(json['isShielded'], isFalse);
    });

    test('serializes answers list', () {
      final q = _q(answers: [Answer(text: 'Yes', isCorrect: true)]);
      final json = q.toJson();
      final answers = json['answers'] as List;
      expect(answers.length, 1);
      expect(answers[0]['text'], 'Yes');
      expect(answers[0]['isCorrect'], isTrue);
    });

    test('serializes null optional fields', () {
      final json = _q().toJson();
      expect(json['imageUrl'], isNull);
      expect(json['videoUrl'], isNull);
      expect(json['audioUrl'], isNull);
      expect(json['tags'], isNull);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel.copyWith
  // -------------------------------------------------------------------------

  group('QuestionModel.copyWith', () {
    test('copies category', () {
      final updated = _q(category: 'science').copyWith(category: 'math');
      expect(updated.category, 'math');
    });

    test('copies correctAnswer', () {
      final updated = _q(correctAnswer: 'A').copyWith(correctAnswer: 'B');
      expect(updated.correctAnswer, 'B');
    });

    test('copies difficulty', () {
      final updated = _q(difficulty: 1)
          .copyWith(difficulty: qdiff.QuestionDifficultyExtension.fromInt(4));
      expect(updated.difficulty.value, 4);
    });

    test('copies showHint', () {
      final updated = _q(showHint: false).copyWith(showHint: true);
      expect(updated.showHint, isTrue);
    });

    test('copies isBoostedTime', () {
      final updated = _q(isBoostedTime: false).copyWith(isBoostedTime: true);
      expect(updated.isBoostedTime, isTrue);
    });

    test('copies audioUrl', () {
      final updated = _q().copyWith(audioUrl: 'track.mp3');
      expect(updated.audioUrl, 'track.mp3');
    });

    test('copies tags', () {
      final updated = _q().copyWith(tags: ['tag1', 'tag2']);
      expect(updated.tags, ['tag1', 'tag2']);
    });

    test('copies optionIdByText map', () {
      final updated = _q().copyWith(optionIdByText: {'Water': 'opt_w'});
      expect(updated.optionIdByText!['Water'], 'opt_w');
    });

    test('preserves unchanged fields', () {
      final original = _q(
        id: 'orig',
        category: 'science',
        difficulty: 3,
        type: 'true_false',
      );
      final updated = original.copyWith(category: 'math');
      expect(updated.id, 'orig');
      expect(updated.difficulty.value, 3);
      expect(updated.type.value, 'true_false');
    });
  });

  // -------------------------------------------------------------------------
  // QuestionModel.fromGameplayDto
  // -------------------------------------------------------------------------

  group('QuestionModel.fromGameplayDto', () {
    test('delegates to fromJson', () {
      final json = {
        'id': 'gplay_q1',
        'category': 'history',
        'question': 'Who?',
        'answers': [],
        'difficulty': 'hard',
      };
      final q = QuestionModel.fromGameplayDto(json);
      expect(q.id, 'gplay_q1');
      expect(q.category, 'history');
      expect(q.difficulty, 3);
    });
  });
}
