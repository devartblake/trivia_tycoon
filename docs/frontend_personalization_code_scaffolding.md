# Synaptix Unified Personalization — Flutter Integration Scaffolding

## 1. Purpose

This document provides code-ready Flutter scaffolding for integrating the Unified Personalization Layer into the Synaptix / Trivia Tycoon frontend.

It covers:

- Data models
- API service methods
- Riverpod providers
- UI widgets
- Home screen integration
- Coach card
- Recommendation card
- "Why am I seeing this?" UX
- Trust controls
- Accept/dismiss tracking
- Error handling and fallback behavior

---

## 2. Frontend Rule

```text
Frontend = renderer and interaction collector
Backend = personalization decision maker
```

The frontend should not implement Theory of Mind rules directly.

The frontend should:

- fetch backend-approved recommendations
- display coach messages
- show reason/explainability copy
- allow accept/dismiss
- provide trust controls
- gracefully fallback if personalization fails

---

## 3. Suggested Folder Structure

```text
lib/
  personalization/
    models/
      coach_brief.dart
      personalization_home.dart
      personalization_recommendation.dart
      personalization_guardrails.dart
    services/
      personalization_api_service.dart
    providers/
      personalization_providers.dart
      personalization_settings_provider.dart
    widgets/
      coach_brief_card.dart
      recommendation_card.dart
      recommendation_reason_sheet.dart
      personalization_toggle_tile.dart
      recommended_for_you_section.dart
    screens/
      personalization_settings_screen.dart
```

---

# Part A — Models

---

## 4. `coach_brief.dart`

```dart
class CoachBrief {
  final String title;
  final String message;
  final String recommendedAction;
  final String? targetRoute;
  final String tone;

  const CoachBrief({
    required this.title,
    required this.message,
    required this.recommendedAction,
    required this.targetRoute,
    required this.tone,
  });

  factory CoachBrief.fromJson(Map<String, dynamic> json) {
    return CoachBrief(
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      recommendedAction: json['recommendedAction']?.toString() ?? '',
      targetRoute: json['targetRoute']?.toString(),
      tone: json['tone']?.toString() ?? 'encouraging',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'recommendedAction': recommendedAction,
      'targetRoute': targetRoute,
      'tone': tone,
    };
  }
}
```

---

## 5. `personalization_recommendation.dart`

```dart
class PersonalizationRecommendation {
  final String id;
  final String type;
  final int priority;
  final double score;
  final String reason;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> guardrails;
  final DateTime? expiresAt;

  const PersonalizationRecommendation({
    required this.id,
    required this.type,
    required this.priority,
    required this.score,
    required this.reason,
    required this.payload,
    required this.guardrails,
    this.expiresAt,
  });

  factory PersonalizationRecommendation.fromJson(Map<String, dynamic> json) {
    return PersonalizationRecommendation(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '') ?? 0.0,
      reason: json['reason']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      guardrails: Map<String, dynamic>.from(json['guardrails'] as Map? ?? {}),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'].toString()),
    );
  }

  String get title {
    return payload['title']?.toString() ?? _fallbackTitle();
  }

  String? get route {
    return payload['route']?.toString();
  }

  String get tone {
    return payload['tone']?.toString() ?? 'encouraging';
  }

  String _fallbackTitle() {
    switch (type) {
      case 'learning_module':
        return 'Recommended Lesson';
      case 'study_set':
        return 'Recommended Study Set';
      case 'mission':
        return 'Recommended Mission';
      case 'store_offer':
        return 'Suggested Offer';
      case 'coach_tip':
        return 'Coach Tip';
      default:
        return 'Recommended for You';
    }
  }
}
```

---

## 6. `personalization_home.dart`

```dart
import 'coach_brief.dart';
import 'personalization_recommendation.dart';

class PersonalizationHome {
  final String playerId;
  final String recommendedMode;
  final String? recommendedCategory;
  final String? recommendedDifficulty;
  final List<PersonalizationRecommendation> recommendations;
  final CoachBrief? coachBrief;
  final Map<String, dynamic> guardrails;

  const PersonalizationHome({
    required this.playerId,
    required this.recommendedMode,
    required this.recommendedCategory,
    required this.recommendedDifficulty,
    required this.recommendations,
    required this.coachBrief,
    required this.guardrails,
  });

  factory PersonalizationHome.empty(String playerId) {
    return PersonalizationHome(
      playerId: playerId,
      recommendedMode: 'play',
      recommendedCategory: null,
      recommendedDifficulty: null,
      recommendations: const [],
      coachBrief: null,
      guardrails: const {},
    );
  }

  factory PersonalizationHome.fromJson(Map<String, dynamic> json) {
    final rawRecommendations = json['recommendations'];

    return PersonalizationHome(
      playerId: json['playerId']?.toString() ?? '',
      recommendedMode: json['recommendedMode']?.toString() ?? 'play',
      recommendedCategory: json['recommendedCategory']?.toString(),
      recommendedDifficulty: json['recommendedDifficulty']?.toString(),
      recommendations: rawRecommendations is List
          ? rawRecommendations
              .whereType<Map>()
              .map((item) => PersonalizationRecommendation.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      coachBrief: json['coachBrief'] is Map
          ? CoachBrief.fromJson(Map<String, dynamic>.from(json['coachBrief']))
          : null,
      guardrails: Map<String, dynamic>.from(json['guardrails'] as Map? ?? {}),
    );
  }
}
```

---

# Part B — API Service

---

## 7. `personalization_api_service.dart`

This example assumes your app already has an authenticated HTTP client similar to `AuthHttpClient` or `HttpClient`.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/personalization_home.dart';
import '../models/personalization_recommendation.dart';
import '../models/coach_brief.dart';

class PersonalizationApiException implements Exception {
  final String message;
  final int? statusCode;

  const PersonalizationApiException(this.message, {this.statusCode});

  @override
  String toString() => 'PersonalizationApiException($statusCode): $message';
}

class PersonalizationApiService {
  final http.Client _client;
  final String baseUrl;
  final Future<String?> Function()? accessTokenProvider;

  PersonalizationApiService({
    required http.Client client,
    required this.baseUrl,
    this.accessTokenProvider,
  }) : _client = client;

  Future<Map<String, String>> _headers() async {
    final token = await accessTokenProvider?.call();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalizedBase$path');
  }

  Future<PersonalizationHome> getHome(String playerId) async {
    final response = await _client.get(
      _uri('/personalization/home/$playerId'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizationApiException(
        'Failed to fetch personalization home.',
        statusCode: response.statusCode,
      );
    }

    return PersonalizationHome.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<List<PersonalizationRecommendation>> getRecommendations(
    String playerId,
  ) async {
    final response = await _client.get(
      _uri('/personalization/recommendations/$playerId'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizationApiException(
        'Failed to fetch recommendations.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((item) => PersonalizationRecommendation.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<CoachBrief?> getDailyBrief(String playerId) async {
    final response = await _client.get(
      _uri('/coach/$playerId/daily-brief'),
      headers: await _headers(),
    );

    if (response.statusCode == 404 || response.body.trim().isEmpty) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizationApiException(
        'Failed to fetch coach brief.',
        statusCode: response.statusCode,
      );
    }

    return CoachBrief.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<void> acceptRecommendation({
    required String recommendationId,
    required String playerId,
  }) async {
    final response = await _client.post(
      _uri('/personalization/recommendations/$recommendationId/accept?playerId=$playerId'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizationApiException(
        'Failed to accept recommendation.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> dismissRecommendation({
    required String recommendationId,
    required String playerId,
  }) async {
    final response = await _client.post(
      _uri('/personalization/recommendations/$recommendationId/dismiss?playerId=$playerId'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizationApiException(
        'Failed to dismiss recommendation.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> recordBehaviorEvent({
    required String playerId,
    required String eventType,
    required String eventSource,
    String? category,
    String? difficulty,
    String? mode,
    Map<String, dynamic> metadata = const {},
  }) async {
    final response = await _client.post(
      _uri('/personalization/profile/$playerId/event'),
      headers: await _headers(),
      body: jsonEncode({
        'eventType': eventType,
        'eventSource': eventSource,
        'category': category,
        'difficulty': difficulty,
        'mode': mode,
        'metadata': metadata,
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PersonalizationApiException(
        'Failed to record behavior event.',
        statusCode: response.statusCode,
      );
    }
  }
}
```

---

# Part C — Riverpod Providers

---

## 8. `personalization_settings_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalizationSettings {
  final bool enabled;
  final bool reduceSuggestions;
  final bool showReasons;

  const PersonalizationSettings({
    required this.enabled,
    required this.reduceSuggestions,
    required this.showReasons,
  });

  PersonalizationSettings copyWith({
    bool? enabled,
    bool? reduceSuggestions,
    bool? showReasons,
  }) {
    return PersonalizationSettings(
      enabled: enabled ?? this.enabled,
      reduceSuggestions: reduceSuggestions ?? this.reduceSuggestions,
      showReasons: showReasons ?? this.showReasons,
    );
  }

  static const defaults = PersonalizationSettings(
    enabled: true,
    reduceSuggestions: false,
    showReasons: true,
  );
}

class PersonalizationSettingsNotifier
    extends StateNotifier<PersonalizationSettings> {
  PersonalizationSettingsNotifier() : super(PersonalizationSettings.defaults);

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  void setReduceSuggestions(bool value) {
    state = state.copyWith(reduceSuggestions: value);
  }

  void setShowReasons(bool value) {
    state = state.copyWith(showReasons: value);
  }
}

final personalizationSettingsProvider = StateNotifierProvider<
    PersonalizationSettingsNotifier, PersonalizationSettings>((ref) {
  return PersonalizationSettingsNotifier();
});
```

> Later, back this with your existing settings/cache services.

---

## 9. `personalization_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/env.dart';
import '../../core/manager/service_manager.dart';
import '../models/personalization_home.dart';
import '../services/personalization_api_service.dart';
import 'personalization_settings_provider.dart';

final personalizationApiServiceProvider =
    Provider<PersonalizationApiService>((ref) {
  final manager = ref.watch(serviceManagerProvider);

  return PersonalizationApiService(
    client: http.Client(),
    baseUrl: EnvConfig.apiBaseUrl,
    accessTokenProvider: () async {
      // Adjust this to your real token store.
      return manager.synaptixApiClient.httpClient.accessToken;
    },
  );
});

final personalizationHomeProvider =
    FutureProvider.family<PersonalizationHome, String>((ref, playerId) async {
  final settings = ref.watch(personalizationSettingsProvider);

  if (!settings.enabled) {
    return PersonalizationHome.empty(playerId);
  }

  final api = ref.watch(personalizationApiServiceProvider);

  try {
    return await api.getHome(playerId);
  } catch (_) {
    // Personalization must never block core app flow.
    return PersonalizationHome.empty(playerId);
  }
});
```

If your `SynaptixApiClient` does not expose `accessToken`, replace the `accessTokenProvider` with your existing `AuthTokenStore` lookup.

---

# Part D — Widgets

---

## 10. `coach_brief_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/coach_brief.dart';

class CoachBriefCard extends StatelessWidget {
  final CoachBrief brief;
  final VoidCallback? onDismiss;

  const CoachBriefCard({
    super.key,
    required this.brief,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(brief.tone);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.16),
              color.withOpacity(0.04),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_alt, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    brief.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              brief.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (brief.targetRoute != null && brief.targetRoute!.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go(brief.targetRoute!),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Try it'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'low_pressure':
        return Colors.teal;
      case 'competitive':
        return Colors.deepOrange;
      case 'encouraging':
      default:
        return Colors.indigo;
    }
  }
}
```

---

## 11. `recommendation_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/personalization_recommendation.dart';
import 'recommendation_reason_sheet.dart';

class RecommendationCard extends StatelessWidget {
  final PersonalizationRecommendation recommendation;
  final bool showReason;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.showReason = true,
    this.onAccept,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final route = recommendation.route;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: route == null
            ? onAccept
            : () {
                onAccept?.call();
                context.go(route);
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(_iconForType(recommendation.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (showReason && recommendation.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        recommendation.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => showRecommendationReasonSheet(
                        context,
                        recommendation,
                      ),
                      child: const Text('Why am I seeing this?'),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'learning_module':
        return Icons.school;
      case 'study_set':
        return Icons.style;
      case 'mission':
        return Icons.flag;
      case 'store_offer':
        return Icons.storefront;
      case 'coach_tip':
        return Icons.psychology;
      default:
        return Icons.recommend;
    }
  }
}
```

---

## 12. `recommendation_reason_sheet.dart`

```dart
import 'package:flutter/material.dart';
import '../models/personalization_recommendation.dart';

void showRecommendationReasonSheet(
  BuildContext context,
  PersonalizationRecommendation recommendation,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why am I seeing this?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.reason.isEmpty
                  ? 'This was recommended based on your recent activity.'
                  : recommendation.reason,
            ),
            const SizedBox(height: 16),
            if (recommendation.guardrails.isNotEmpty)
              Text(
                'Safety checks were applied to keep recommendations fair and non-intrusive.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
    },
  );
}
```

---

## 13. `recommended_for_you_section.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/personalization_home.dart';
import '../models/personalization_recommendation.dart';
import '../providers/personalization_providers.dart';
import '../providers/personalization_settings_provider.dart';
import 'coach_brief_card.dart';
import 'recommendation_card.dart';

class RecommendedForYouSection extends ConsumerWidget {
  final String playerId;

  const RecommendedForYouSection({
    super.key,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHome = ref.watch(personalizationHomeProvider(playerId));
    final settings = ref.watch(personalizationSettingsProvider);

    if (!settings.enabled) {
      return const SizedBox.shrink();
    }

    return asyncHome.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (home) {
        if (home.coachBrief == null && home.recommendations.isEmpty) {
          return const SizedBox.shrink();
        }

        final visibleRecommendations = settings.reduceSuggestions
            ? home.recommendations.take(2).toList()
            : home.recommendations;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (home.coachBrief != null)
              CoachBriefCard(brief: home.coachBrief!),
            if (visibleRecommendations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Recommended for You',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final recommendation in visibleRecommendations)
                _RecommendationTile(
                  playerId: playerId,
                  recommendation: recommendation,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _RecommendationTile extends ConsumerWidget {
  final String playerId;
  final PersonalizationRecommendation recommendation;

  const _RecommendationTile({
    required this.playerId,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(personalizationApiServiceProvider);
    final settings = ref.watch(personalizationSettingsProvider);

    return RecommendationCard(
      recommendation: recommendation,
      showReason: settings.showReasons,
      onAccept: () async {
        await api.acceptRecommendation(
          recommendationId: recommendation.id,
          playerId: playerId,
        );
        ref.invalidate(personalizationHomeProvider(playerId));
      },
      onDismiss: () async {
        await api.dismissRecommendation(
          recommendationId: recommendation.id,
          playerId: playerId,
        );
        ref.invalidate(personalizationHomeProvider(playerId));
      },
    );
  }
}
```

---

# Part E — Trust Controls

---

## 14. `personalization_settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/personalization_settings_provider.dart';

class PersonalizationSettingsScreen extends ConsumerWidget {
  const PersonalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(personalizationSettingsProvider);
    final notifier = ref.read(personalizationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalization'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Personalized recommendations'),
            subtitle: const Text(
              'Use gameplay activity to suggest modes, lessons, missions, and tips.',
            ),
            value: settings.enabled,
            onChanged: notifier.setEnabled,
          ),
          SwitchListTile(
            title: const Text('Reduce suggestions'),
            subtitle: const Text('Show fewer recommendation cards.'),
            value: settings.reduceSuggestions,
            onChanged: notifier.setReduceSuggestions,
          ),
          SwitchListTile(
            title: const Text('Show recommendation reasons'),
            subtitle: const Text('Display “Why am I seeing this?” details.'),
            value: settings.showReasons,
            onChanged: notifier.setShowReasons,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset recommendations'),
            subtitle: const Text(
              'Clears local recommendation preferences. Backend reset can be wired next.',
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recommendation preferences reset.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

# Part F — Screen Integration

---

## 15. Example Home Screen Integration

Wherever your logged-in home or game menu screen is built:

```dart
import 'package:trivia_tycoon/personalization/widgets/recommended_for_you_section.dart';

class GameHomeScreen extends ConsumerWidget {
  const GameHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerId = 'TODO_GET_REAL_PLAYER_ID';

    return Scaffold(
      appBar: AppBar(title: const Text('Synaptix')),
      body: ListView(
        children: [
          RecommendedForYouSection(playerId: playerId),

          // Existing home/menu content goes below.
          // ...
        ],
      ),
    );
  }
}
```

---

## 16. Example Behavior Event Tracking

After a question answer:

```dart
await ref.read(personalizationApiServiceProvider).recordBehaviorEvent(
  playerId: playerId,
  eventType: 'question_answered',
  eventSource: 'quiz',
  category: question.category,
  difficulty: question.difficulty,
  mode: 'practice',
  metadata: {
    'correct': isCorrect,
    'answerTimeMs': answerTime.inMilliseconds,
    'usedHint': usedHint,
  },
);
```

After a recommendation tap:

```dart
await api.acceptRecommendation(
  recommendationId: recommendation.id,
  playerId: playerId,
);
```

After dismissal:

```dart
await api.dismissRecommendation(
  recommendationId: recommendation.id,
  playerId: playerId,
);
```

---

# Part G — Error Handling

---

## 17. Required Behavior

Personalization must never block gameplay.

If these fail:

```text
GET /personalization/home/{playerId}
GET /coach/{playerId}/daily-brief
POST accept/dismiss
POST behavior event
```

Then the frontend should:

- hide recommendation UI
- continue default gameplay
- log debug output in development
- never show scary error messages to players

---

## 18. Recommended UX Rules

Do:

- show short coach messages
- show reason/explainability
- allow dismiss
- allow reducing suggestions
- keep store suggestions subtle
- use low-pressure language

Avoid:

- “You are bad at Science”
- “Buy this to stop losing”
- forced recommendations
- blocking the player from continuing
- excessive popups

---

# Part H — Integration Checklist

## 19. Frontend Checklist

- [ ] Add personalization models.
- [ ] Add personalization API service.
- [ ] Add Riverpod providers.
- [ ] Add CoachBriefCard.
- [ ] Add RecommendationCard.
- [ ] Add “Why am I seeing this?” sheet.
- [ ] Add settings/trust controls.
- [ ] Add RecommendedForYouSection to home/game menu.
- [ ] Add behavior event tracking to question answer flow.
- [ ] Add accept/dismiss tracking.
- [ ] Add local fallback behavior.
- [ ] Confirm CORS works on Flutter Web.
- [ ] Confirm auth token is attached.
- [ ] Confirm recommendations do not block UI.

---

## 20. Final Frontend Principle

```text
Personalization should feel like a helpful guide, not a controlling system.
```
