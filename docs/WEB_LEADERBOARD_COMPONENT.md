# Web-Optimized Leaderboard Table Component

**Date Created:** 2026-06-30  
**Status:** ✅ Implemented  
**File:** `lib/screens/leaderboard/widgets/ranked_leaderboard_web_table.dart`

---

## Overview

The `RankedLeaderboardWebTable` is a web-optimized table component designed to display ranked leaderboard data efficiently on desktop and tablet screens. It replaces the card-based mobile layout with a proper data table that makes better use of horizontal screen space.

## Features

### Core Features
- ✅ **Full Data Table Layout** — All columns visible at once
- ✅ **Sortable Columns** — Click headers to sort (with ascending/descending toggle)
- ✅ **Alternating Row Colors** — Better readability with zebra striping
- ✅ **Responsive Pagination** — Clear page info and navigation
- ✅ **Material Design** — Consistent with Flutter Material 3

### Column Display
| Column | Width | Details |
|--------|-------|---------|
| Rank | 80px | Tier rank in current tier |
| Player | Flex 2 | Player ID (truncated) + Tier level |
| RP | 90px | Rank Points (sortable) |
| Wins | 80px | Win count (green) |
| Losses | 90px | Loss count (red) |
| Draws | 80px | Draw count (amber) |
| Matches | 100px | Total matches played |
| Global | 100px | Global season rank |

## Usage

### Basic Usage in Screen

```dart
RankedLeaderboardWebTable(
  entries: leaderboardEntries,
  currentPage: 1,
  total: 500,
  pageSize: 50,
  seasonId: 'season-123',
  onPrevPage: () => setState(() => _page--),
  onNextPage: () => setState(() => _page++),
)
```

### Integration in RankedLeaderboardScreen

The component is automatically used when screen width >= 1000px:

```dart
final width = MediaQuery.of(context).size.width;
final isWideWeb = width >= 1000;

if (isWideWeb) {
  return RankedLeaderboardWebTable(...);
} else {
  return _CardBasedMobileView(...);
}
```

## Design Specifications

### Breakpoints
- **< 1000px**: Card-based grid layout (mobile/tablet)
- **≥ 1000px**: Table layout (desktop/wide web)

### Colors
- **Header Background**: `Colors.grey[100]`
- **Row Background**: Alternating white / `Colors.grey[50]`
- **Dividers**: `Colors.grey[200]`
- **Text (Wins)**: `Colors.green[700]`
- **Text (Losses)**: `Colors.red[700]`
- **Text (Draws)**: `Colors.amber[700]`

### Spacing
- **Header Padding**: 16px (horizontal), 12px (vertical)
- **Row Padding**: 16px (horizontal), 14px (vertical)
- **Column Gap**: 24px between columns
- **Header Row Height**: Auto (fit content)
- **Data Row Height**: Auto (fit content)

### Typography
- **Column Headers**: 13px, FontWeight.w600, gray[700]
- **Active Sort Header**: Primary color, FontWeight.bold
- **Player Names**: titleSmall
- **Player Tier**: 12px, gray[600]
- **Data Values**: 14px, FontWeight.w500
- **Page Info**: bodySmall

## Sorting System

### How Sorting Works
1. Click any column header to sort by that column
2. Click again to toggle ascending/descending
3. Active sort column shows an arrow indicator (↑ or ↓)
4. Sorting updates in real-time

### Sortable Columns
- ✅ Rank (tierRank)
- ✅ Global Rank (seasonRank)
- ✅ RP (rankPoints)
- ✅ Wins
- ✅ Losses
- ✅ Draws
- ✅ Matches Played

### Sort State
- `_sortColumn`: Current sort column (null = no sort)
- `_sortAscending`: Sort direction
- `_applySorting()`: Internal method that applies sort logic

## Pagination

### Display Info
- Shows current page and total pages
- Shows range of entries (e.g., "1–50 of 500")
- Previous/Next buttons

### Button States
- **Previous**: Disabled on page 1
- **Next**: Disabled on last page

## Accessibility Features

- ✅ Sortable columns with visual indicators
- ✅ Clear visual hierarchy with alternating rows
- ✅ High contrast text on backgrounds
- ✅ Adequate spacing between data points
- ✅ Semantic row/column structure

## Customization

### To Add More Columns
1. Add new enum value to `SortColumn`
2. Add new sort case in `_applySorting()`
3. Add new header in header row
4. Add new data cell in data rows

### To Change Column Widths
Update the `width:` parameter in `_buildSortHeader()` or `SizedBox` wrapping each column.

### To Change Colors
Update the color values in `_buildSortHeader()` and row building logic.

## Performance Considerations

- **Sorting**: O(n log n) using Dart's List.sort()
- **Rendering**: Uses `SingleChildScrollView` for horizontal scrolling on narrow screens
- **Memory**: Maintains single sorted list in state
- **Rebuild**: Only rebuilds on data change or sort action

## Future Enhancements

- [ ] **Expandable Rows** — Click row to see more details
- [ ] **Column Visibility Toggle** — Hide/show columns
- [ ] **Export to CSV** — Download leaderboard data
- [ ] **Sticky Header** — Keep header visible while scrolling
- [ ] **Search Filter** — Filter by player name/ID
- [ ] **Custom Sort** — Save user's preferred sort column

## Testing

### Manual QA Checklist
- [ ] Table displays all 8 columns correctly
- [ ] Sorting works for all sortable columns
- [ ] Alternating row colors display correctly
- [ ] Pagination buttons work
- [ ] Responsive on 1000px+ screens
- [ ] Fallback to card view on < 1000px
- [ ] Win count shows in green
- [ ] Loss count shows in red
- [ ] Draw count shows in amber

## Code Quality

- ✅ Type-safe (full type annotations)
- ✅ Well-commented
- ✅ Follows Flutter best practices
- ✅ Single responsibility principle
- ✅ Reusable and modular

---

## Related Files

- `lib/screens/leaderboard/ranked_leaderboard_screen.dart` — Main screen that uses this component
- `lib/game/models/ranked_leaderboard_models.dart` — Data models
- `lib/screens/leaderboard/widgets/ranked_leaderboard_web_table.dart` — This component

---

**Status:** Production Ready ✅  
**Last Updated:** 2026-06-30
