# Synaptix Play Question System Recommendations

**Project:** Synaptix Play / TycoonTycoon Backend / Trivia Frontend  
**Primary Focus:** Frontend Question Renderer Refactor  
**Reference Website:** http://app.synaptixplay.com  
**Reference Backend Repository:** https://github.com/devartblake/TycoonTycoon_Backend.git  
**Prepared For:** Devart Blake  

---

## 1. Executive Recommendation

The question system should not be treated as only a single question screen improvement. For Synaptix Play, the stronger long-term direction is to build a modular **Question System Module** composed of three layers:

1. **Question Bank / Admin Manager**
2. **Question Rendering / Player Experience**
3. **Question Metadata / Progression Integration**

The immediate next step should focus on the **frontend question renderer refactor**. This gives the project a cleaner rendering architecture before the admin question bank, advanced question types, and progression hooks are expanded.

The frontend should move away from placing too much gameplay, display, state, and answer handling logic directly inside `question_screen.dart`. Instead, `question_screen.dart` should become a route/page shell that delegates rendering, state, answer handling, timers, feedback, and media display to smaller reusable components.

---

## 2. Directional Answer to the Team

The recommended direction is:

> We should move toward a full Question System Module rather than only patching the current question screen. The priority should be a reusable question renderer, a shared question model, and support for categories, difficulty, tags, media, and progression metadata.
>
> A question editor/manager screen is still important, but it should be treated as an admin/operator feature. The player-facing side should focus first on rendering questions cleanly and supporting multiple question types. The admin side should focus later on managing the question bank, previewing questions, filtering, importing/exporting, and publishing content.
>
> For custom UI elements, we should build both app-wide Synaptix components and question-specific gameplay components. These should follow the Synaptix home theme, but the question screen should stay cleaner and more focused for readability and fast interaction.
>
> For integration, this should work with the existing `question_screen.dart`, but the preferred approach is to refactor it into smaller widgets/providers instead of adding more logic directly into that file. The system should also be reusable by arcade, mini-games, learning mode, daily challenges, and the tier/progression system.

---

# 3. Question System Scope

## 3.1 New Question Editor / Manager Screen

### Recommendation

Yes, a new question editor/manager screen should exist, but it should not be the first implementation priority. It should be built after the frontend renderer and shared question model are stable.

The question manager should be admin/operator-facing and should not be mixed into the player question flow.

### Recommended Admin Features

The admin/editor screen should allow authorized users to:

- Create questions
- Edit questions
- Preview question rendering
- Assign category
- Assign age group or grade band
- Assign difficulty
- Add tags
- Select question type
- Upload or attach media
- Add hints
- Add explanations
- Mark questions as draft, active, archived, or needs review
- Import and export question batches
- Validate bad or incomplete questions before publishing

### Recommended Status Values

```text
Draft
Needs Review
Approved
Published
Archived
Rejected
```

### Why This Should Come After Renderer Refactor

The admin editor depends on the question model and renderer. If the renderer changes later, the admin preview system may need to be reworked. Building the player renderer and shared model first creates a stable foundation.

---

## 3.2 Existing Question Display / Rendering

### Recommendation

Yes, the existing question display should be enhanced immediately. This should be the next active implementation focus.

The frontend should move toward a reusable `QuestionRenderer` pattern that can handle multiple question types without turning `question_screen.dart` into a large conditional widget.

### Supported MVP Question Types

The first version should support:

- Multiple choice
- True / false
- Image-based questions

### Later Question Types

After the MVP renderer is stable, add:

- Video-based questions
- Drag-and-drop
- Sorting
- Matching
- Classification
- Labeling
- Timed challenge questions
- Boss questions

---

## 3.3 Question Bank / Library System

### Recommendation

Yes, a question bank/library should become the backend source of truth.

The frontend should prepare for this by using a clean question model that can receive backend data, local fallback data, or cached question data.

### Question Bank Should Store

- Question text
- Question type
- Category
- Difficulty
- Tags
- Age group or grade band
- Media references
- Answer options
- Correct answer key
- Explanation text
- Hint text
- Skill tree linkage
- XP reward values
- Coin reward values
- Usage statistics
- Review status
- Created/updated metadata

---

## 3.4 Categories and Filtering

### Recommendation

Categories and filtering are required.

Filtering should exist in two different experiences:

1. **Admin filtering** for content management
2. **Player filtering/recommendation** for gameplay personalization

### Admin Filters

Admins should be able to filter by:

- Category
- Difficulty
- Age group
- Status
- Question type
- Tags
- Created by
- Missing media
- Needs review
- Recently updated

### Player Filters

Players should be able to interact with:

- Category selection
- Recommended categories
- Weak-area practice
- Daily challenge categories
- Skill-tree-aligned categories
- Event or seasonal categories

---

## 3.5 Difficulty Levels and Tags

### Recommendation

Difficulty and tags should be part of the core model, not optional decoration.

Difficulty should affect:

- XP payout
- Coin reward
- Timer duration
- Streak multiplier
- Unlock eligibility
- Leaderboard scoring
- Skill tree progression
- Player mastery analytics

### Recommended Difficulty Values

```text
easy
medium
hard
expert
boss
```

### Recommended Initial Tags

```text
math
science
history
sports
logic
image_question
speed_round
memory
grade_3
grade_4
daily_challenge
skill_tree_node
```

---

## 3.6 Missing or Needed Improvements

| Feature | Priority | Reason |
|---|---:|---|
| Unified question model | High | Prevents frontend/backend mismatch |
| Frontend question renderer | High | Needed before more question types are added |
| Multiple choice renderer | High | Core gameplay requirement |
| True/false renderer | High | Simple and useful MVP type |
| Image question renderer | High | Supports richer question content |
| Category/difficulty/tag metadata | High | Required for filtering and progression |
| API service and fallback cache | High | Prevents frontend failure if backend endpoint is unavailable |
| Admin question manager | Medium-High | Needed for scaling content management |
| Question preview renderer | Medium-High | Lets admins see what players will see |
| Draft/review/publish workflow | Medium | Prevents bad content going live |
| Question analytics | Medium | Helps identify broken, too easy, or too hard questions |
| Bulk import/export | Medium | Speeds up content creation |
| AI-assisted question generation | Later | Useful but not MVP-critical |

---

# 4. Custom UI Element Priorities

The custom UI work should be split into two groups:

1. **General app-wide Synaptix components**
2. **Question-specific gameplay components**

---

## 4.1 App-Wide Synaptix UI Components

These components should become part of the reusable Synaptix design system.

Recommended components:

- `SynaptixCard`
- `SynaptixButton`
- `SynaptixDialog`
- `SynaptixBottomSheet`
- `SynaptixProgressBar`
- `SynaptixBadge`
- `SynaptixChip`
- `SynaptixTabBar`
- `SynaptixLoadingState`
- `SynaptixEmptyState`
- `SynaptixErrorState`
- `SynaptixRewardToast`
- `SynaptixGlassPanel`
- `SynaptixDepthPanel`

These should be reusable across:

- Home
- Profile
- Leaderboard
- Question screens
- Store
- Rewards
- Missions
- Admin tools
- Arcade modes
- Mini-games

---

## 4.2 Question-Specific Gameplay Components

Recommended question components:

- `QuestionRenderer`
- `QuestionCard`
- `QuestionTimer`
- `AnswerOptionCard`
- `AnswerFeedbackPanel`
- `HintRevealPanel`
- `QuestionMediaFrame`
- `DifficultyBadge`
- `CategoryBadge`
- `XPRewardPreview`
- `StreakMeter`
- `CorrectAnswerAnimation`
- `WrongAnswerAnimation`
- `QuestionProgressRail`
- `PowerUpOverlay`
- `SkillTreeRewardBanner`

---

## 4.3 Theme Direction

### Recommendation

Yes, the question system should integrate with the Synaptix home theme.

The question system should use the same:

- Color tokens
- Gradient language
- Rounded card style
- Depth/shadow language
- Typography
- Icon style
- Motion style
- Reward feedback style

However, the question screen should remain more focused and less visually busy than the home screen. During active gameplay, readability and tap accuracy are more important than visual density.

---

## 4.4 Performance Requirements

Recommended performance rules:

- Avoid heavy animations during timed questions
- Keep answer taps immediate
- Use lightweight widgets for answer choices
- Cache image/media assets
- Lazy-load question media
- Avoid rebuilding the full screen on timer ticks
- Use Riverpod selectors or isolated providers for timer state
- Support offline/fallback question data when the API is unavailable
- Keep question rendering deterministic and testable

---

## 4.5 Accessibility Requirements

Recommended accessibility requirements:

- Large readable text
- Minimum tap target around 44px
- High contrast support
- Reduced motion support
- Screen-reader labels for answer choices
- Do not use color alone for correct/wrong states
- Add icon/text labels such as `Correct`, `Incorrect`, or `Try Again`
- Timer warning should have visual feedback and optional audio/haptic feedback
- Ensure answer order is understandable by screen readers

---

# 5. Integration Points

## 5.1 Existing `question_screen.dart`

### Recommendation

Yes, the new renderer should work with the existing `question_screen.dart`, but `question_screen.dart` should be refactored rather than expanded.

The goal is to make `question_screen.dart` a page shell that delegates actual rendering and gameplay UI to smaller components.

### Recommended Structure

```text
lib/
  features/
    questions/
      models/
        question_model.dart
        answer_option_model.dart
        question_type.dart
        question_difficulty.dart
      providers/
        question_controller.dart
        question_state.dart
        question_repository_provider.dart
      services/
        question_api_service.dart
        question_cache_service.dart
      widgets/
        question_renderer.dart
        question_card.dart
        answer_option_card.dart
        question_timer.dart
        question_feedback_panel.dart
        question_media_frame.dart
        hint_reveal_panel.dart
        question_progress_rail.dart
      screens/
        question_screen.dart
```

If the current repo does not use `features/questions/`, adapt the same structure to the existing folder convention.

---

## 5.2 Arcade / Mini-Games System

### Recommendation

Yes, the question system should eventually work with arcade and mini-games, but through shared contracts only.

Arcade and mini-games should not own question logic directly. They should request question sets from a shared question service.

### Example Integration Pattern

```text
Arcade Mode
  -> requests question set by category, difficulty, and time limit

Mini-game Mode
  -> requests question set by mechanic type

Learning Mode
  -> requests question set by mastery weakness

Daily Challenge
  -> requests curated daily question pack
```

The same question bank can power all of these modes.

---

## 5.3 Tier / Progression System

### Recommendation

Yes, the question system should connect to the tier and progression system.

Question results should feed progression through:

- XP rewards
- Coin rewards
- Streaks
- Category mastery
- Skill tree unlocks
- Daily missions
- Weekly missions
- Leaderboards
- Player weakness analytics

### Example Progression Links

| Question Event | Progression Impact |
|---|---|
| Correct answer | Award XP and coins |
| Hard question correct | Bonus XP multiplier |
| Streak milestone | Trigger streak reward |
| Category improvement | Increase category mastery |
| Repeated wrong answers | Update learning recommendations |
| Boss question correct | Unlock special challenge or tournament |
| Daily question complete | Update daily mission progress |

---

# 6. Recommended MVP Scope

## Phase 1 — Frontend Question Renderer Foundation

This is the next active focus.

Build:

- Unified frontend `QuestionModel`
- `QuestionRenderer`
- Multiple choice renderer
- True/false renderer
- Image question renderer
- Difficulty/category/tag support
- API service interface
- Local fallback questions
- Refactor existing `question_screen.dart`
- Basic loading, error, and empty states

---

## Phase 2 — Admin / Content Management

Build after the renderer foundation:

- Question bank list
- Question create/edit form
- Draft/publish/archive status
- Preview renderer
- Filters
- Bulk import/export
- Basic validation

---

## Phase 3 — Progression Integration

Build after stable rendering and backend contracts:

- XP reward calculation
- Coin reward calculation
- Skill tree hooks
- Category mastery
- Daily/weekly mission hooks
- Player weakness analytics
- Streak-based rewards

---

## Phase 4 — Advanced Question Types

Build after MVP gameplay is stable:

- Drag-and-drop
- Sorting
- Matching
- Classification
- Labeling
- Video questions
- Timed challenge questions
- Boss questions

---

# 7. Primary Next Step: Frontend Question Renderer Refactor

The confirmed next focus is the **frontend question renderer refactor**.

## 7.1 Refactor Goal

The goal is to transform the current question screen into a modular, scalable player-facing system that can support multiple question types without duplicating UI logic or creating a large, fragile screen file.

The refactor should create:

- A shared question model
- A renderer dispatcher
- Type-specific renderers
- Reusable answer option components
- Reusable timer and feedback components
- Clear Riverpod state boundaries
- Local fallback support
- Compatibility with future backend contracts

---

## 7.2 Recommended Frontend Architecture

### Top-Level Screen

`question_screen.dart` should handle:

- Page scaffold
- Route parameters
- Provider subscription
- High-level loading/error/empty states
- Passing state into `QuestionRenderer`

It should not directly own:

- Answer layout details
- Question type branching
- Timer tick internals
- Feedback animation internals
- Media rendering internals
- XP/progression calculation internals

---

## 7.3 Recommended File Breakdown

```text
lib/
  features/
    questions/
      models/
        question_model.dart
        answer_option_model.dart
        question_type.dart
        question_difficulty.dart
        question_result_model.dart

      providers/
        question_controller.dart
        question_state.dart
        question_repository_provider.dart

      repositories/
        question_repository.dart
        remote_question_repository.dart
        fallback_question_repository.dart

      services/
        question_api_service.dart
        question_cache_service.dart

      widgets/
        question_renderer.dart
        multiple_choice_question_view.dart
        true_false_question_view.dart
        image_question_view.dart
        question_card.dart
        answer_option_card.dart
        question_timer.dart
        question_feedback_panel.dart
        question_media_frame.dart
        hint_reveal_panel.dart
        difficulty_badge.dart
        category_badge.dart

      screens/
        question_screen.dart
```

If the project currently uses a different folder structure, keep the same concept but adapt the paths.

---

## 7.4 Recommended Data Model

### `QuestionType`

```dart
enum QuestionType {
  multipleChoice,
  trueFalse,
  imageChoice,
  videoChoice,
  dragDrop,
  sorting,
  matching,
  classification,
  labeling,
}
```

### `QuestionDifficulty`

```dart
enum QuestionDifficulty {
  easy,
  medium,
  hard,
  expert,
  boss,
}
```

### `AnswerOptionModel`

```dart
class AnswerOptionModel {
  const AnswerOptionModel({
    required this.id,
    required this.label,
    this.mediaUrl,
    this.semanticLabel,
  });

  final String id;
  final String label;
  final String? mediaUrl;
  final String? semanticLabel;
}
```

### `QuestionModel`

```dart
class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.prompt,
    required this.type,
    required this.difficulty,
    required this.category,
    required this.options,
    required this.correctOptionId,
    this.tags = const [],
    this.mediaUrl,
    this.hint,
    this.explanation,
    this.timeLimitSeconds,
    this.xpReward,
    this.coinReward,
  });

  final String id;
  final String prompt;
  final QuestionType type;
  final QuestionDifficulty difficulty;
  final String category;
  final List<String> tags;
  final List<AnswerOptionModel> options;
  final String correctOptionId;
  final String? mediaUrl;
  final String? hint;
  final String? explanation;
  final int? timeLimitSeconds;
  final int? xpReward;
  final int? coinReward;
}
```

---

## 7.5 Recommended Renderer Pattern

`QuestionRenderer` should dispatch to the correct renderer based on `QuestionType`.

```dart
class QuestionRenderer extends StatelessWidget {
  const QuestionRenderer({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onAnswerSelected,
    required this.isAnswered,
  });

  final QuestionModel question;
  final String? selectedOptionId;
  final ValueChanged<String> onAnswerSelected;
  final bool isAnswered;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestionView(
          question: question,
          selectedOptionId: selectedOptionId,
          onAnswerSelected: onAnswerSelected,
          isAnswered: isAnswered,
        );
      case QuestionType.trueFalse:
        return TrueFalseQuestionView(
          question: question,
          selectedOptionId: selectedOptionId,
          onAnswerSelected: onAnswerSelected,
          isAnswered: isAnswered,
        );
      case QuestionType.imageChoice:
        return ImageQuestionView(
          question: question,
          selectedOptionId: selectedOptionId,
          onAnswerSelected: onAnswerSelected,
          isAnswered: isAnswered,
        );
      default:
        return UnsupportedQuestionTypeView(questionType: question.type);
    }
  }
}
```

---

## 7.6 Recommended State Shape

`QuestionState` should keep gameplay state separate from rendering widgets.

```dart
class QuestionState {
  const QuestionState({
    required this.questions,
    required this.currentIndex,
    required this.selectedOptionId,
    required this.isAnswered,
    required this.isLoading,
    required this.errorMessage,
    required this.remainingSeconds,
  });

  final List<QuestionModel> questions;
  final int currentIndex;
  final String? selectedOptionId;
  final bool isAnswered;
  final bool isLoading;
  final String? errorMessage;
  final int? remainingSeconds;

  QuestionModel? get currentQuestion {
    if (questions.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }
}
```

---

## 7.7 Recommended Controller Responsibilities

`QuestionController` should handle:

- Loading questions
- Selecting answers
- Checking correctness
- Moving to the next question
- Timer expiration
- Resetting state
- Reporting result events to future progression services

It should not handle:

- Widget layout
- Colors
- Animations
- Direct backend parsing inside widgets

---

## 7.8 Frontend Refactor Implementation Order

### Step 1 — Inventory Current Question Screen

Review the existing `question_screen.dart` and identify:

- Current state management approach
- Current question model shape
- Existing API calls
- Existing local fallback questions
- Existing answer checking logic
- Existing timer logic
- Existing UI components that can be reused

### Step 2 — Add Question Models

Create:

```text
question_model.dart
answer_option_model.dart
question_type.dart
question_difficulty.dart
question_result_model.dart
```

### Step 3 — Add Renderer Shell

Create:

```text
question_renderer.dart
multiple_choice_question_view.dart
true_false_question_view.dart
image_question_view.dart
unsupported_question_type_view.dart
```

### Step 4 — Extract Reusable Widgets

Create or refactor:

```text
question_card.dart
answer_option_card.dart
question_timer.dart
question_feedback_panel.dart
question_media_frame.dart
hint_reveal_panel.dart
difficulty_badge.dart
category_badge.dart
```

### Step 5 — Refactor `question_screen.dart`

Make it responsible for:

- Watching provider state
- Handling page scaffold
- Rendering loading/error/empty states
- Calling `QuestionRenderer`

### Step 6 — Add Repository Boundary

Create a repository interface so the UI does not care whether questions come from:

- Backend API
- Local fallback data
- Cached data
- Mock data for tests

### Step 7 — Add Fallback Question Data

Add local fallback questions for development and offline safety.

Recommended minimum fallback set:

- 3 multiple choice questions
- 3 true/false questions
- 3 image questions

### Step 8 — Add Widget Tests

Test:

- Multiple choice rendering
- True/false rendering
- Image question rendering
- Answer selection
- Correct/wrong feedback display
- Unsupported question type fallback

---

# 8. Acceptance Criteria for Frontend Refactor

The refactor should be considered complete when:

- `question_screen.dart` is no longer a large monolithic gameplay file
- `QuestionRenderer` supports multiple question types
- Multiple choice questions render correctly
- True/false questions render correctly
- Image questions render correctly
- Answer selection works consistently
- Feedback state is visually clear
- Question metadata displays category and difficulty
- Timer state does not rebuild the full question screen unnecessarily
- API/fallback repository boundary exists
- Local fallback question data works
- Basic widget tests exist
- The system can be reused by future arcade, mini-game, and learning modes

---

# 9. Suggested Developer Task List

## Task 1 — Create Question Models

Create the shared frontend data model for questions, answer options, types, difficulty, and result metadata.

**Priority:** High  
**Owner:** Frontend  
**Output:** Model files and serialization helpers if needed  

---

## Task 2 — Create Question Renderer

Create `QuestionRenderer` and initial type-specific renderers.

**Priority:** High  
**Owner:** Frontend  
**Output:** Renderer dispatch system  

---

## Task 3 — Extract Answer Components

Create reusable answer card components with selected, correct, incorrect, and disabled states.

**Priority:** High  
**Owner:** Frontend/UI  
**Output:** `AnswerOptionCard` and related visual states  

---

## Task 4 — Refactor `question_screen.dart`

Reduce `question_screen.dart` to page shell responsibilities.

**Priority:** High  
**Owner:** Frontend  
**Output:** Cleaner screen connected to renderer/controller  

---

## Task 5 — Add Repository Interface

Add a question repository boundary with remote and fallback implementations.

**Priority:** High  
**Owner:** Frontend/API  
**Output:** Repository abstraction and fallback data  

---

## Task 6 — Add Question Metadata UI

Display category, difficulty, and optional tags in a clean way.

**Priority:** Medium  
**Owner:** Frontend/UI  
**Output:** Metadata badges and tags  

---

## Task 7 — Add Tests

Add widget and controller tests for basic question rendering and answer selection.

**Priority:** Medium  
**Owner:** Frontend  
**Output:** Test coverage for renderer and state behavior  

---

# 10. Recommended Implementation Sequence

The next work should proceed in this order:

1. Inspect current `question_screen.dart`
2. Create shared frontend question models
3. Create `QuestionRenderer`
4. Add multiple choice renderer
5. Add true/false renderer
6. Add image question renderer
7. Extract `AnswerOptionCard`
8. Extract `QuestionCard`
9. Extract timer/feedback widgets
10. Add fallback question repository
11. Wire screen to controller/provider
12. Add tests
13. Then plan backend contract alignment
14. Then plan admin question bank/editor

---

# 11. Recommended Not-To-Do Items Right Now

Do not start with:

- Full admin question editor
- AI question generation
- Advanced drag-and-drop questions
- Video question pipeline
- Complex analytics dashboard
- Full skill tree integration
- Heavy animation polish
- Marketplace/content creator tooling

Those features are valuable, but they should come after the renderer foundation is stable.

---

# 12. Final Recommendation

The best next step is to start with the **frontend question renderer refactor**.

This gives Synaptix Play a stronger foundation for:

- Cleaner question gameplay
- More question types
- Better reuse across modes
- Easier backend integration
- Future admin preview tools
- Progression and skill tree hooks
- Arcade and mini-game support

The highest-value first implementation should be:

```text
QuestionModel
QuestionRenderer
MultipleChoiceQuestionView
TrueFalseQuestionView
ImageQuestionView
AnswerOptionCard
QuestionScreen refactor
FallbackQuestionRepository
```

Once those are stable, the project can move into the admin question bank/editor with much less rework.
