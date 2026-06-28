# Phase 2 Testing Guide

## Overview

Phase 2 introduces three reward systems to Trivia Tycoon:
- **Daily Bonus**: Daily claim system with streak tracking
- **Weekly Rewards**: 7-day progression calendar with rewards
- **Tier System**: 7-tier progression with XP tracking

This guide documents the comprehensive test suite created for Phase 2.

## Test Suite Structure

### 1. Unit Tests: Provider Tests
**File**: `test/game/providers/phase2_reward_providers_test.dart`

Tests the Riverpod providers that manage Phase 2 state and data fetching.

#### Daily Bonus Provider Tests
- `dailyBonusConfigProvider`: Configuration loading and validation
- `dailyBonusStatusProvider`: Status tracking consistency
- `dailyBonusClaimProvider`: Claim result handling

#### Weekly Rewards Provider Tests
- `weeklyScheduleProvider`: 7-day schedule validation
- `weeklyStreakProvider`: Streak status and progression
- `weeklyClaimProvider`: Weekly claim processing

#### Tier Progression Provider Tests
- `tierDefinitionsProvider`: 7-tier system validation
- `playerTierProgressProvider`: Progress calculation and XP tracking
- `awardXpProvider`: XP award handling

#### Combined Status Provider Tests
- `combinedRewardStatusProvider`: Full reward snapshot
- Computed properties (canClaimDaily, isMaxTier, etc.)

### 2. Widget Tests: Screen Tests

#### Daily Bonus Screen
**File**: `test/screens/rewards/daily_bonus_screen_test.dart`

Tests:
- Loading state rendering
- AppBar presence and centering
- RefreshIndicator functionality
- Scrollability
- AlwaysScrollableScrollPhysics enabled

#### Weekly Rewards Screen
**File**: `test/screens/rewards/weekly_rewards_screen_test.dart`

Tests:
- Scaffold and AppBar structure
- Title centering
- RefreshIndicator presence
- Scrollable content with proper physics
- Loading state display

#### Tier Progress Widget
**File**: `test/screens/rewards/tier_progress_widget_test.dart`

Tests:
- Widget rendering without errors
- Loading state display
- Scrollable container support
- Dashboard layout integration
- Responsive parent constraint handling

### 3. Integration Tests: Dashboard Integration
**File**: `test/features/synaptix_home/phase2_dashboard_integration_test.dart`

#### Individual Card Tests
- `Phase2DailyBonusCard`: Card rendering, elevation, shape
- `Phase2WeeklyRewardsCard`: Card structure and styling
- `Phase2TierProgressCard`: Card styling with gradients

#### Layout Integration Tests
- **Mobile Layout**: Stacked column layout on narrow screens (<720px)
- **Desktop Layout**: 3-column row layout on wide screens (≥720px)
- **Responsive Behavior**: LayoutBuilder and responsive adjustments

#### Spacing Tests
- Vertical spacing in mobile layout (16px between cards)
- Horizontal spacing in desktop layout (16px between cards)

#### Responsive Behavior Tests
- All cards render in responsive layouts
- Cards are scrollable when content overflows
- Proper integration with SingleChildScrollView

## Running Tests

### Run All Phase 2 Tests
```bash
flutter test test/game/providers/phase2_reward_providers_test.dart \
                test/screens/rewards/ \
                test/features/synaptix_home/phase2_dashboard_integration_test.dart
```

### Run Specific Test Groups
```bash
# Provider tests only
flutter test test/game/providers/phase2_reward_providers_test.dart

# Widget tests only
flutter test test/screens/rewards/

# Dashboard integration tests only
flutter test test/features/synaptix_home/phase2_dashboard_integration_test.dart
```

### Run Single Test File
```bash
flutter test test/screens/rewards/daily_bonus_screen_test.dart
```

### Run with Coverage
```bash
flutter test --coverage test/game/providers/phase2_reward_providers_test.dart
```

## Test Coverage Summary

| Component | Unit Tests | Widget Tests | Integration Tests |
|-----------|-----------|--------------|-------------------|
| Daily Bonus | 3 groups | ✅ | ✅ |
| Weekly Rewards | 2 groups | ✅ | ✅ |
| Tier System | 3 groups | ✅ | ✅ |
| Dashboard Cards | - | - | ✅ (3 cards) |
| Responsive Layout | - | - | ✅ |

## Test Scenarios Covered

### State Management
- ✅ Provider initialization and data loading
- ✅ Status tracking consistency
- ✅ Combined status aggregation
- ✅ Auto-disposal cleanup

### UI Rendering
- ✅ Loading states
- ✅ Success states
- ✅ Error handling
- ✅ Widget hierarchy

### Layout & Responsiveness
- ✅ Mobile layout (stacked)
- ✅ Desktop layout (row)
- ✅ Responsive transitions
- ✅ Proper spacing and alignment
- ✅ ScrollView behavior

### User Interactions
- ✅ Pull-to-refresh
- ✅ Button availability (via UI structure)
- ✅ Navigation integration

## Known Test Limitations

1. **Mock Data**: Tests use default mock implementations. Replace with real API responses when backend is ready.
2. **API Clients**: Tests assume successful API responses. Error scenarios tested separately.
3. **User Interactions**: Widget tests verify UI structure but don't simulate all user gestures.
4. **Animations**: Loading skeletons and animations not fully tested.

## Next Steps for QA

1. **Manual Testing**: Open app on mobile and desktop to verify visual appearance
2. **Integration Testing**: Test claim flows end-to-end
3. **Performance Testing**: Monitor frame rates during scrolling and transitions
4. **Responsive Testing**: Verify layouts at 360px, 720px, 1200px breakpoints
5. **API Testing**: Test with real backend responses

## Mocking Strategy

### Current Implementation
- Daily Bonus API Client: Uses default mock configuration (100 coins)
- Weekly Rewards API Client: Uses default mock schedule (7 days)
- Tier API Client: Uses mock tier definitions (7 tiers)

### To Update Mocks
1. Edit corresponding `*_api_client.dart` files
2. Update default values in `getDailyConfig()`, `getWeeklySchedule()`, `getTierDefinitions()`
3. Rerun tests to verify changes

## CI/CD Integration

Add to `.github/workflows/flutter_ci.yml`:

```yaml
- name: Run Phase 2 Tests
  run: |
    flutter test test/game/providers/phase2_reward_providers_test.dart
    flutter test test/screens/rewards/
    flutter test test/features/synaptix_home/phase2_dashboard_integration_test.dart
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Tests fail with "No element to pop" | Ensure GoRouter safeBack() is used |
| Loading states don't complete | Mock providers may need timeout adjustment |
| Card layouts look wrong | Verify LayoutBuilder constraints match breakpoints |
| Scrolling tests fail | Check AlwaysScrollableScrollPhysics is enabled |

## Debugging Tips

### Enable verbose logging
```bash
flutter test --verbose
```

### Run specific test
```bash
flutter test -k "test_name_substring"
```

### Debug in IDE
- Set breakpoints in test files
- Run "Flutter: Run tests with debugging" in VS Code
- Use dart DevTools for detailed inspection

## Related Documentation

- [Phase 2 Architecture](./PHASE2_ARCHITECTURE.md)
- [API Integration Guide](./API_ENDPOINTS_VERIFICATION.md)
- [GoRouter Safe Navigation](./implementation/GOROUTER_FIX_SUMMARY.md)

## Maintenance

- Update tests when UI components change
- Add new tests for new reward types
- Keep mock data synchronized with API changes
- Review coverage metrics regularly

---

**Last Updated**: 2026-06-27
**Status**: All tests created and verified
**Next Review**: After first manual QA pass
