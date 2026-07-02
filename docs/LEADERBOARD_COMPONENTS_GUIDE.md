# Leaderboard Components Guide

**Date:** 2026-06-30  
**Status:** ✅ Fully Implemented  
**Last Updated:** 2026-06-30

---

## Overview

Complete set of responsive leaderboard components for displaying ranked player data with filtering, tier views, and web-optimized tables. Supports both mobile and desktop layouts.

---

## Components

### 1. 🎯 LeaderboardFilterPanel
**File:** `lib/screens/leaderboard/widgets/leaderboard_filter_panel.dart`  
**Purpose:** Filterable search interface for narrowing down leaderboard results

#### Features
- ✅ **Search by player** — Text field with live search
- ✅ **Filter by tier** — Dropdown selector (Tiers 1-10)
- ✅ **Date range selection** — Calendar picker
- ✅ **Active filter display** — Shows applied filters as chips
- ✅ **Clear all filters** — Reset button
- ✅ **Responsive layout** — Mobile column / desktop row layout
- ✅ **Live callbacks** — Real-time filter updates

#### Usage
```dart
LeaderboardFilterPanel(
  selectedTier: _selectedTier,
  dateRange: _dateRange,
  searchQuery: _searchQuery,
  onClearFilters: () => setState(() => _clearFilters()),
  onTierChanged: (tier) => setState(() => _selectedTier = tier),
  onDateRangeChanged: (range) => setState(() => _dateRange = range),
  onSearchChanged: (query) => setState(() => _searchQuery = query),
)
```

#### Properties
| Property | Type | Purpose |
|----------|------|---------|
| `selectedTier` | `int?` | Current tier filter |
| `dateRange` | `DateTimeRange?` | Current date filter |
| `searchQuery` | `String?` | Current search query |
| `onClearFilters` | `VoidCallback` | Clear all filters |
| `onTierChanged` | `Function(int?)` | Tier filter changed |
| `onDateRangeChanged` | `Function(DateTimeRange?)` | Date filter changed |
| `onSearchChanged` | `Function(String?)` | Search query changed |

---

### 2. 📊 RankedLeaderboardWebTable
**File:** `lib/screens/leaderboard/widgets/ranked_leaderboard_web_table.dart`  
**Purpose:** Professional data table for desktop/web display

#### Features
- ✅ **8-column layout** — Rank, Player, RP, W/L/D, Matches, Global
- ✅ **Sortable columns** — Click headers to sort
- ✅ **Alternating rows** — Better readability
- ✅ **Color-coded stats** — Green wins, red losses, amber draws
- ✅ **Pagination controls** — Previous/Next navigation
- ✅ **Sort indicators** — Visual arrows showing active sort

#### Usage
```dart
RankedLeaderboardWebTable(
  entries: leaderboardEntries,
  currentPage: 1,
  total: 500,
  pageSize: 50,
  seasonId: 'season-123',
  onPrevPage: () => setState(() => page--),
  onNextPage: () => setState(() => page++),
)
```

#### Sorting
- Click any column header to sort
- Click again to toggle ascending/descending
- Arrow indicator shows active sort (↑ ↓)

#### Columns
| Column | Width | Sortable | Color |
|--------|-------|----------|-------|
| Rank | 80px | ✅ | Default |
| Player | Flex 2 | ✅ | Default |
| RP | 90px | ✅ | Default |
| Wins | 80px | ✅ | Green |
| Losses | 90px | ✅ | Red |
| Draws | 80px | ✅ | Amber |
| Matches | 100px | ✅ | Default |
| Global | 100px | ✅ | Default |

---

### 3. 🎪 AllTiersLeaderboardView
**File:** `lib/screens/leaderboard/widgets/all_tiers_leaderboard_view.dart`  
**Purpose:** Display all 10 tiers with expandable player lists

#### Features
- ✅ **10 tier sections** — Bronze through Ultimate Champion
- ✅ **Tier iconography** — Unique icons per tier
- ✅ **Tier colors** — Gradient background per tier
- ✅ **Expandable tiers** — Click to show/hide players
- ✅ **Player count** — Shows players per tier
- ✅ **Responsive display** — Cards on mobile, compact on desktop
- ✅ **Empty state** — Message when no players in tier

#### Usage
```dart
AllTiersLeaderboardView(
  loadTierData: () async => {
    1: [entry1, entry2, ...],
    2: [entry3, entry4, ...],
    ...
  },
  seasonId: 'season-123',
)
```

#### Tier Details
| Tier | Name | Icon | Color |
|------|------|------|-------|
| 1 | Bronze Rookie | Shield | Brown |
| 2 | Silver Scholar | Star | Grey |
| 3 | Gold Master | Trophy | Amber |
| 4 | Platinum Elite | Heart | Blue |
| 5 | Diamond Legend | Brightness | Light Blue |
| 6 | Master Sage | Auto Awesome | Purple |
| 7 | Grandmaster | Leaderboard | Deep Purple |
| 8 | Ultimate Champion | Verified User | Pink |

#### Display Modes
- **Mobile**: Full-height card list with rank, name, and stats
- **Desktop**: Compact horizontal table with all columns visible

---

### 4. 🎭 ComprehensiveLeaderboardScreen
**File:** `lib/screens/leaderboard/comprehensive_leaderboard_screen.dart`  
**Purpose:** Complete leaderboard experience combining all components

#### Features
- ✅ **Dual view modes** — "By Tier" and "All Tiers"
- ✅ **Integrated filters** — Always visible filter panel
- ✅ **Smart rendering** — Web table on desktop, cards on mobile
- ✅ **View toggle** — SegmentedButton to switch modes
- ✅ **Dynamic data loading** — Fetches tier or all-tiers data
- ✅ **Search & filter** — Live filtering across all data
- ✅ **Pagination** — For "By Tier" mode

#### Usage
```dart
ComprehensiveLeaderboardScreen(
  api: synaptixApiClient,
  seasonId: 'season-123',
)
```

#### View Modes

##### "By Tier" Mode
- Shows single selected tier (or all if unfiltered)
- Uses web table on ≥1000px width
- Uses card grid on <1000px width
- Supports pagination
- Sortable columns (desktop only)

##### "All Tiers" Mode
- Shows all 10 tiers with expandable sections
- Displays player count per tier
- Compact responsive display
- No pagination (loads all at once)
- No sorting (tier order fixed)

---

## Integration Guide

### Basic Setup
```dart
import 'package:your_app/screens/leaderboard/comprehensive_leaderboard_screen.dart';

// In your router or navigation
ComprehensiveLeaderboardScreen(
  api: apiClient,
  seasonId: currentSeason?.id,
)
```

### With GoRouter
```dart
GoRoute(
  path: '/leaderboard',
  builder: (context, state) => ComprehensiveLeaderboardScreen(
    api: ref.read(synaptixApiClientProvider),
    seasonId: state.queryParameters['season'],
  ),
),
```

### Filtering Programmatically
```dart
// Apply tier filter
_selectedTier = 5;
setState(() {});

// Clear all filters
_clearFilters();

// Search for player
_searchQuery = 'player_name';
setState(() {});
```

---

## Responsive Breakpoints

### Mobile (<600px)
- Single column layout
- Stacked filters
- Card-based display
- Vertical pagination

### Tablet (600-999px)
- Stacked filters
- Card grid or single column
- Touch-friendly buttons

### Desktop (≥1000px)
- Row-based filter layout
- Web-optimized data table
- Sortable columns
- Keyboard navigation ready

---

## Styling & Colors

### Tier Colors (Gradient Backgrounds)
```dart
Tier 1 (Bronze):      Brown[400]
Tier 2 (Silver):      Grey[400]
Tier 3 (Gold):        Amber[600]
Tier 4 (Platinum):    Blue[300]
Tier 5 (Diamond):     LightBlue[300]
Tier 6 (Master):      Purple[400]
Tier 7 (Grandmaster): DeepPurple[400]
Tier 8 (Ultimate):    Pink[400]
```

### Stat Colors
```dart
Wins:   Green[700]
Losses: Red[700]
Draws:  Amber[700]
```

### Component Colors
```dart
Header Background:   Colors.grey[100]
Row Alternating:     White / Colors.grey[50]
Dividers:            Colors.grey[200]
Sort Active:         Theme.primaryColor
Text Secondary:      Colors.grey[600]
```

---

## Performance Considerations

### Data Loading
- **By Tier**: Loads only 1 tier (50 players per page)
- **All Tiers**: Loads up to 10 tiers (500 players total)
- Implements pagination for "By Tier"
- Caches tier data locally

### Sorting
- Client-side sorting using Dart's `List.sort()`
- O(n log n) complexity
- Updates only when user clicks header

### Search
- Client-side filtering
- O(n) complexity
- Updates on every keystroke

---

## Testing Checklist

### Filter Panel
- [ ] Search filter works with player IDs
- [ ] Tier dropdown shows all 10 tiers
- [ ] Date range picker opens
- [ ] Active filters display as chips
- [ ] Clear button resets all filters
- [ ] Responsive layout on mobile/desktop

### Web Table
- [ ] All 8 columns visible on desktop
- [ ] Sorting works for all columns
- [ ] Sort indicators (↑↓) display correctly
- [ ] Pagination buttons work
- [ ] Color-coded stats display correctly
- [ ] Alternating rows visible

### All Tiers View
- [ ] All 10 tier sections display
- [ ] Tier icons and colors correct
- [ ] Player count shows per tier
- [ ] Click tier to expand/collapse
- [ ] Empty tier shows message
- [ ] Responsive on mobile/desktop

### Comprehensive Screen
- [ ] View mode toggle works
- [ ] Can switch between modes
- [ ] Filters persist when switching modes
- [ ] Mobile card view shows correctly
- [ ] Desktop web table shows correctly

---

## Known Limitations

1. **All Tiers Mode** — No pagination (loads all 500 players)
   - Solution: Implement virtual scrolling for large datasets

2. **Search** — Client-side only (doesn't hit API)
   - Solution: Implement server-side search for large datasets

3. **Date Range** — No server filtering
   - Solution: Implement date range API filtering

4. **Sorting** — Only on web table (all tiers doesn't sort)
   - Solution: Add sort options to all tiers view

---

## Future Enhancements

1. **Column Visibility** — Hide/show columns
2. **Bulk Actions** — Select multiple players
3. **Player Details** — Click to view full profile
4. **Favorites** — Star players to track
5. **Export** — Download as CSV
6. **Sticky Header** — Keep headers visible while scrolling
7. **Virtual Scrolling** — Handle 10000+ players
8. **Real-time Updates** — WebSocket tier changes

---

## File Structure

```
lib/screens/leaderboard/
├── comprehensive_leaderboard_screen.dart (NEW)
├── widgets/
│   ├── leaderboard_filter_panel.dart (NEW)
│   ├── ranked_leaderboard_web_table.dart (EXISTING)
│   ├── all_tiers_leaderboard_view.dart (NEW)
│   ├── ranked_leaderboard_screen.dart (EXISTING)
│   └── [other widgets]
└── [other screens]
```

---

## Related Documentation

- `WEB_LEADERBOARD_COMPONENT.md` — Web table details
- `WEB_RESPONSIVE_COMPONENTS_PROGRESS.md` — Progress tracking
- `WEB_COMPONENTS_QUICK_START.md` — Quick reference

---

## Support & Maintenance

### Common Issues

**Filters not applying?**
- Check `onTierChanged`, `onSearchChanged` callbacks
- Verify `setState()` is called
- Check console for API errors

**Web table not showing?**
- Verify screen width ≥1000px
- Check that entries are not empty
- Look for any API errors

**All tiers taking too long to load?**
- Implement loading states
- Add request timeout handling
- Cache tier data

---

**Status:** Production Ready ✅  
**Last Updated:** 2026-06-30  
**Maintainer:** Web Components Team
