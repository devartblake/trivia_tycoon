# Animation Manager Guide

## Overview

`AnimationManager` is the centralized animation helper for the Flutter app.

Current file:
- `lib/core/animations/animation_manager.dart`

It now supports both:
- controller-based helpers for existing `StatefulWidget` animation flows
- one-line widget wrappers for common enter, pulse, spin, shimmer, and transition effects

---

## Available APIs

### Controller helpers

```dart
final controller = AnimationManager.createController(
  vsync: this,
  duration: const Duration(milliseconds: 500),
);

final fade = AnimationManager.createFadeAnimation(
  controller: controller,
);
```

Also available:
- `createStaggeredControllers(...)`
- `startStaggered(...)`
- `disposeControllers(...)`

### One-line widget wrappers

```dart
AnimationManager.fadeIn(
  child: const Text('Hello'),
  delay: 100,
)

AnimationManager.fadeSlideIn(
  child: MyCard(),
)

AnimationManager.slideFromLeft(
  child: DrawerItem(),
)

AnimationManager.slideFromBottom(
  child: SheetContent(),
)

AnimationManager.scaleIn(
  child: Badge(),
)

AnimationManager.pulse(
  child: StatusDot(),
)

AnimationManager.bounce(
  child: RewardIcon(),
)

AnimationManager.rotate(
  child: const Icon(Icons.refresh),
)

AnimationManager.spin(
  child: const CircularProgressIndicator(),
)
```

### Special widgets

```dart
AnimationManager.typingDots()

AnimationManager.shimmer(
  child: Placeholder(),
)

AnimationManager.progressBar(
  progress: 0.75,
  color: Colors.green,
)
```

### Page transitions

```dart
Navigator.push(
  context,
  AnimationManager.fadeTransition(page: const NextScreen()),
);

Navigator.push(
  context,
  AnimationManager.slideTransition(
    page: const NextScreen(),
    direction: SlideDirection.right,
  ),
);

Navigator.push(
  context,
  AnimationManager.scaleTransition(page: const NextScreen()),
);
```

---

## Migration Examples

### Replace `ShowUpAnimation`

Before:

```dart
ShowUpAnimation(
  delay: 300,
  child: MyWidget(),
)
```

After:

```dart
AnimationManager.fadeSlideIn(
  delay: 300,
  child: MyWidget(),
)
```

### Replace `DrawerAnimations.slideFromLeft`

Before:

```dart
DrawerAnimations.slideFromLeft(
  animation: controller,
  child: DrawerItem(),
)
```

After:

```dart
AnimationManager.slideFromLeft(
  animation: controller,
  child: DrawerItem(),
)
```

### Replace manual staggered startup

Before:

```dart
_controllers = List.generate(
  6,
  (index) => AnimationController(
    duration: Duration(milliseconds: 600 + (index * 100)),
    vsync: this,
  ),
);
```

After:

```dart
_controllers = AnimationManager.createStaggeredControllers(
  vsync: this,
  count: 6,
);

AnimationManager.startStaggered(
  controllers: _controllers,
  mounted: mounted,
);
```

### Replace pulse animation

Before:

```dart
return ScaleTransition(
  scale: _pulseAnimation,
  child: indicator,
);
```

After:

```dart
return AnimationManager.pulse(
  child: indicator,
  minScale: 0.8,
  maxScale: 1.0,
);
```

---

## Migration Status Matrix

This matrix reflects the actual repository status after verification.

| Checklist item | Status | Notes |
|---|---|---|
| Replace `ShowUpAnimation` with `AnimationManager.fadeSlideIn()` | Partial | No active `ShowUpAnimation(` usages were found in app code, but `lib/core/utils/animation.dart` still exists as a legacy utility file. |
| Replace `DrawerAnimations.slideFromLeft()` with `AnimationManager.slideFromLeft()` | Partial | No active `DrawerAnimations.` usages were found in app code, but `lib/game/utils/drawer_animations.dart` still exists as a deprecated compatibility shim. |
| Replace manual staggered animations with `AnimationManager.createStaggeredControllers()` | Partial | Confirmed in key files like `main_menu_screen.dart` and `app_drawer.dart`, but not audited as complete across the whole repo. |
| Replace pulse animations with `AnimationManager.pulse()` | Partial | Confirmed in `presence_status_widget.dart` and seasonal UI usage. |
| Replace typing dots with `AnimationManager.typingDots()` | Complete for primary target | Confirmed in `typing_indicator_widget.dart`. |
| Replace page transitions with `AnimationManager.fadeTransition()` etc. | Not yet migrated | The APIs now exist, but migration usage still needs to be applied where desired. |
| Update imports to use `animation_manager.dart` | Partial | Key migrated files use it, but legacy wrapper files still import and re-expose related behavior. |
| Remove old animation utility files (optional) | Not complete | `lib/core/utils/animation.dart` and `lib/game/utils/drawer_animations.dart` are still present. |

---

## Recommended Next Steps

1. Delete `lib/core/utils/animation.dart` after one final repo-wide confirmation that `ShowUpAnimation` is unused.
2. Delete `lib/game/utils/drawer_animations.dart` after one final repo-wide confirmation that `DrawerAnimations` is unused.
3. Migrate any remaining custom page-route transitions to `AnimationManager.fadeTransition()`, `slideTransition()`, or `scaleTransition()`.
4. Update this matrix once the cleanup pass is complete.

---

## Notes

- The manager now supports both implicit one-line wrappers and the older controller-driven style.
- This lets the repo migrate incrementally instead of forcing a single large animation refactor.
- Legacy compatibility files still exist, so the migration should be treated as in progress rather than fully closed.
