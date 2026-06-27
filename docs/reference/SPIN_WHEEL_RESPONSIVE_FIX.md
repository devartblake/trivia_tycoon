# Spin Wheel Responsive Layout Fix

## Issue Summary

The spin wheel layout is inconsistent between mobile and web:
- ❌ **Web**: Wheel is too large, takes up most of viewport
- ❌ **Mobile**: Wheel appears smaller than on web proportionally
- ❌ **Controls**: Buttons and stats are cramped on mobile
- ❌ **Layout**: Uses fixed flex ratios that don't adapt to screen size

## Root Cause Analysis

### Problem 1: Hardcoded Wheel Size
**File**: `lib/ui_components/spin_wheel/ui/screen/wheel_screen.dart` (line 643)
```dart
WheelWidget(
  size: 300,  // Fixed size, doesn't adapt to screen
)
```

### Problem 2: Fixed Flex Ratios
**Line 595-596**:
```dart
Expanded(
  flex: 2,  // Always 2/3 of available space - same on mobile and web
  child: Container(...)
)
```

### Problem 3: No Responsive Layout
- No `LayoutBuilder` or `MediaQuery` based layout switching
- No max width constraints for web
- Padding/margins are fixed regardless of screen size

### Problem 4: No Orientation Handling
- Layout doesn't adapt for landscape mode
- Stats cards will wrap on narrow screens

## Solution Design

### Desktop (Web) Layout
```
┌─────────────────────────────────────────┐
│ AppBar with title and status indicator  │
├─────────────────────────────────────────┤
│  ┌────────────┐  ┌────────────────┐    │
│  │   Wheel    │  │  Stats Cards   │    │
│  │  (350px)   │  │  (stacked vert)│    │
│  └────────────┘  └────────────────┘    │
│                                         │
│  Cooldown Timer - Spin Button - Rewards│
└─────────────────────────────────────────┘
```

### Mobile Layout
```
┌─────────────────────┐
│ AppBar (compact)    │
├─────────────────────┤
│  ┌───────────────┐  │
│  │     Wheel     │  │
│  │    (280px)    │  │
│  └───────────────┘  │
│                     │
│  Cooldown Timer     │
│  Spin Button        │
│                     │
│  ┌──────┬──────┐    │
│  │Stats │Stats │    │
│  ├──────┼──────┤    │
│  │Stats │Stats │    │
│  └──────┴──────┘    │
└─────────────────────┘
```

## Implementation Plan

### Step 1: Add Responsive Helper
Create utilities for responsive wheel sizing:
```dart
class WheelResponsive {
  static double getWheelSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    
    if (isDesktop) {
      return 350; // Larger on desktop
    } else if (screenWidth > 600) {
      return 300; // Medium on tablet
    } else {
      return 280; // Smaller on mobile
    }
  }
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 900;
  
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
}
```

### Step 2: Update Wheel Screen Layout

**Option A: Desktop-optimized Layout (Recommended)**
- Use `Row` on desktop (wheel + stats side-by-side)
- Use `Column` on mobile (stacked vertically)
- Implement with `LayoutBuilder`

**Option B: Responsive Column
- Keep `Column` layout but adjust flex ratios
- Simpler implementation
- Still provides responsive experience

### Step 3: Fix Wheel Container
```dart
// Before: Fixed sizing
WheelWidget(size: 300)

// After: Responsive sizing
WheelWidget(size: WheelResponsive.getWheelSize(context))
```

### Step 4: Adjust Stats Cards
- On mobile: Show 2 columns
- On desktop: Show 3 columns side-by-side
- Use `Wrap` or `GridView` for responsive grid

### Step 5: Add Max Width Constraints
```dart
// Prevent wheel from being too large on ultra-wide screens
Container(
  constraints: BoxConstraints(
    maxWidth: WheelResponsive.isDesktop(context) ? 900 : double.infinity,
  ),
  child: ...
)
```

## Code Changes Required

### 1. Create Responsive Utility
**File**: `lib/ui_components/spin_wheel/utils/wheel_responsive.dart`
- Wheel size calculations
- Breakpoint definitions
- Layout mode detection

### 2. Update WheelScreen
**File**: `lib/ui_components/spin_wheel/ui/screen/wheel_screen.dart`
- Replace fixed `Expanded(flex: 2)` with responsive layout
- Add `LayoutBuilder` for conditional layouts
- Use `WheelResponsive.getWheelSize()` for wheel size
- Implement desktop layout with `Row` when appropriate

### 3. Update StatCard Layout
- Change from fixed `Row` to responsive grid
- Use `GridView` or `Wrap` for flexible wrapping
- Adjust card sizes for different screen sizes

## Responsive Breakpoints

| Device | Width | Wheel Size | Layout |
|--------|-------|-----------|--------|
| Phone | < 600px | 280px | Column (stacked) |
| Tablet | 600-900px | 300px | Column (optimized) |
| Desktop | > 900px | 350px | Row (side-by-side) |

## Implementation Priority

1. **High Priority**: Get responsive wheel sizing working
2. **High Priority**: Fix mobile layout (stats cards, spacing)
3. **Medium Priority**: Implement desktop side-by-side layout
4. **Low Priority**: Landscape orientation support

## Testing Checklist

### Mobile (< 600px)
- [ ] Wheel size: 280px
- [ ] Stats cards: 2 columns (or stacked)
- [ ] No horizontal scrolling
- [ ] Buttons fully visible
- [ ] Proper spacing

### Tablet (600-900px)
- [ ] Wheel size: 300px
- [ ] Stats cards: 3 columns
- [ ] Good proportions
- [ ] No cramping

### Desktop (> 900px)
- [ ] Wheel size: 350px max
- [ ] Stats cards: side-by-side with wheel
- [ ] Balanced layout
- [ ] Max width constraint prevents excessive stretching

### Landscape
- [ ] Works without horizontal scroll
- [ ] Wheel and controls fit side-by-side if possible
- [ ] Touch targets remain adequate

## Performance Impact

- **No performance regression** - Responsive layout doesn't add computation
- **Slight memory improvement** - Smaller wheel on mobile reduces canvas memory
- **No network overhead** - All changes are local layout

## Browser/Device Compatibility

- ✅ All browsers (responsive design)
- ✅ All Flutter platforms (mobile, tablet, web)
- ✅ All screen orientations (portrait, landscape)
- ✅ All pixel densities (density-independent)

---

**Status**: Ready for Implementation
**Effort**: 2-3 hours
**Complexity**: Medium (layout restructuring)
