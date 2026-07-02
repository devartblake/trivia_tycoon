# Leaderboard Architecture & Flow

**Date:** 2026-06-30  
**Status:** ✅ COMPLETE

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│         ComprehensiveLeaderboardScreen                  │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  View Mode Toggle (Segmented Button)          │     │
│  │  [By Tier] [All Tiers]                        │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  LeaderboardFilterPanel                       │     │
│  │  ├─ Search Player                             │     │
│  │  ├─ Filter by Tier                            │     │
│  │  └─ Date Range Picker                         │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  Content Area (Conditional)                   │     │
│  │                                               │     │
│  │  IF "By Tier" Mode:                           │     │
│  │  ├─ Desktop (≥1000px)                         │     │
│  │  │  └─ RankedLeaderboardWebTable              │     │
│  │  │     ├─ 8 Columns (sortable)                │     │
│  │  │     ├─ Alternating rows                    │     │
│  │  │     └─ Pagination                          │     │
│  │  └─ Mobile (<1000px)                          │     │
│  │     └─ Card Grid View                         │     │
│  │        ├─ 1-2 columns                         │     │
│  │        └─ Pagination                          │     │
│  │                                               │     │
│  │  IF "All Tiers" Mode:                         │     │
│  │  └─ AllTiersLeaderboardView                   │     │
│  │     ├─ 10 Tier Sections                       │     │
│  │     ├─ Expandable Tiers                       │     │
│  │     ├─ Player Lists per Tier                  │     │
│  │     └─ Tier Iconography & Colors              │     │
│  └───────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
                    ┌─────────────────────┐
                    │ SynaptixApiClient   │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  API Endpoints      │
                    │ /leaderboards/ranked│
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼────────┐  ┌───▼──────────┐  ┌─▼──────────────┐
    │ "By Tier" Mode   │  │ "All Tiers"  │  │ Filter Actions │
    │ ─────────────    │  │ Mode         │  │ ─────────────  │
    │ Load single tier │  │ ──────────── │  │ - Search       │
    │ with pagination  │  │ Load 10 tiers│  │ - Filter tier  │
    │ Apply filters    │  │ (async)      │  │ - Date range   │
    └────────┬─────────┘  └───┬──────────┘  └─┬──────────────┘
             │                │              │
             └────────────────┼──────────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Filter & Sort      │
                    │ (Client-side)      │
                    └─────────┬──────────┘
                              │
         ┌────────────────────┴────────────────────┐
         │                                         │
    ┌────▼─────────────┐                ┌────────▼──────┐
    │ Display Tier 1-X │                │ Display All   │
    │ with Web Table   │                │ 10 Tiers      │
    │ or Card Grid     │                │ Expandable    │
    └──────────────────┘                └───────────────┘
```

---

## Component Hierarchy

```
ComprehensiveLeaderboardScreen
├── AppBar
├── ViewModeToggle
│   └── SegmentedButton (By Tier | All Tiers)
├── LeaderboardFilterPanel
│   ├── TextField (Search)
│   ├── DropdownButtonFormField (Tier)
│   ├── DateRangePicker
│   └── ActiveFiltersDisplay
└── ContentArea
    ├── TierView
    │   ├── Desktop View (≥1000px)
    │   │   └── RankedLeaderboardWebTable
    │   │       ├── HeaderRow (SortableColumns)
    │   │       ├── DataRows (Alternating)
    │   │       └── Pagination
    │   └── MobileView (<1000px)
    │       ├── CardGrid
    │       │   └── Card × N
    │       └── Pagination
    └── AllTiersView
        └── AllTiersLeaderboardView
            └── TierSection × 10
                ├── TierHeader (Expandable)
                │   ├── TierIcon
                │   ├── TierName
                │   ├── PlayerCount
                │   └── ExpandButton
                └── TierContent (Conditional)
                    └── PlayerList
                        └── PlayerRow × N
```

---

## View Mode Comparison

```
┌──────────────────────────────────────────────────────┐
│ VIEW MODE COMPARISON                                 │
├──────────────────────────────────────────────────────┤
│                                                      │
│ "BY TIER" MODE                                       │
│ ─────────────────                                    │
│ • Shows single tier (or all if unfiltered)           │
│ • Paginated (50 players per page)                    │
│ • Web table on desktop (8 columns, sortable)         │
│ • Card grid on mobile (1-2 columns)                  │
│ • Supports pagination navigation                    │
│ • Best for: Detailed tier rankings                   │
│                                                      │
│ "ALL TIERS" MODE                                     │
│ ────────────────                                     │
│ • Shows all 10 tiers at once                         │
│ • Expandable tier sections                          │
│ • Loads all 500 players (uncached)                   │
│ • Compact mobile-friendly display                    │
│ • No pagination needed                              │
│ • Best for: Overview of all tiers                    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Tier Taxonomy

```
┌───────────────────────────────────────────────────────┐
│ TIER SYSTEM (8 Tiers + 2 Hidden)                      │
├───────────────────────────────────────────────────────┤
│                                                       │
│ Tier 1 → Bronze Rookie          [Shield Icon]        │
│          Brown[400] gradient                         │
│          Entry level, first tier                     │
│                                                       │
│ Tier 2 → Silver Scholar         [Star Icon]          │
│          Grey[400] gradient                          │
│          Intermediate tier                          │
│                                                       │
│ Tier 3 → Gold Master            [Trophy Icon]        │
│          Amber[600] gradient                         │
│          Achievement unlock                         │
│                                                       │
│ Tier 4 → Platinum Elite         [Heart Icon]         │
│          Blue[300] gradient                          │
│          Premium tier                               │
│                                                       │
│ Tier 5 → Diamond Legend         [Brightness Icon]    │
│          LightBlue[300] gradient                     │
│          Prestigious tier                           │
│                                                       │
│ Tier 6 → Master Sage            [Auto Awesome Icon]  │
│          Purple[400] gradient                        │
│          Expert level                               │
│                                                       │
│ Tier 7 → Grandmaster            [Leaderboard Icon]   │
│          DeepPurple[400] gradient                    │
│          Elite status                               │
│                                                       │
│ Tier 8 → Ultimate Champion      [Verified Icon]      │
│          Pink[400] gradient                          │
│          Highest tier                               │
│                                                       │
│ Tiers 9-10 → (Reserved for future use)               │
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

## Responsive Breakpoints

```
┌─────────────────────────────────────────────────────┐
│ RESPONSIVE LAYOUT SYSTEM                             │
├─────────────────────────────────────────────────────┤
│                                                     │
│ MOBILE LAYOUT (<600px)                              │
│ ──────────────────────                              │
│ Filter Panel:                                       │
│   • Search field (100% width)                       │
│   • Tier dropdown (100% width)                      │
│   • Date picker (100% width)                        │
│   • Stacked vertically                              │
│                                                     │
│ Content:                                            │
│   • Single column card grid                         │
│   • Full width cards                                │
│   • Vertical scrolling                              │
│   • Touch-friendly buttons                          │
│                                                     │
│ ─────────────────────────────────────────────────   │
│                                                     │
│ TABLET LAYOUT (600-999px)                           │
│ ──────────────────────────                          │
│ Filter Panel:                                       │
│   • Tier and Date side by side                      │
│   • Search above                                    │
│   • Optimized spacing                               │
│                                                     │
│ Content:                                            │
│   • 2-column card grid                              │
│   • Moderate card size                              │
│   • Horizontal pagination                           │
│                                                     │
│ ─────────────────────────────────────────────────   │
│                                                     │
│ DESKTOP LAYOUT (≥1000px)                            │
│ ────────────────────────                            │
│ Filter Panel:                                       │
│   • Search, Tier, Date all in one row               │
│   • Horizontal layout                               │
│   • Clear button visible                            │
│                                                     │
│ Content:                                            │
│   • 8-column data table                             │
│   • All data visible at once                        │
│   • Sortable column headers                         │
│   • Pagination at bottom                            │
│   • Keyboard navigation ready                       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Data Model Relationships

```
RankedLeaderboardResponse
├── seasonId: String
├── page: int
├── pageSize: int
├── total: int
└── items: List<RankedLeaderboardEntry>
    └── RankedLeaderboardEntry
        ├── playerId: String
        ├── seasonRank: int (Global rank)
        ├── tier: int (1-10)
        ├── tierRank: int (Rank within tier)
        ├── rankPoints: int (RP)
        ├── wins: int
        ├── losses: int
        ├── draws: int
        └── matchesPlayed: int
```

---

## Filter Logic Flow

```
┌──────────────────────────────────┐
│ User Input (Filter Change)       │
├──────────────────────────────────┤
│  onChange events from:           │
│  • Search field                  │
│  • Tier dropdown                 │
│  • Date range picker             │
│  • Clear button                  │
└─────────────┬────────────────────┘
              │
    ┌─────────▼─────────┐
    │ Update State:     │
    │ • _selectedTier   │
    │ • _dateRange      │
    │ • _searchQuery    │
    │ • _currentPage=1  │
    └─────────┬─────────┘
              │
    ┌─────────▼──────────────────┐
    │ Rebuild Widget             │
    │ FutureBuilder re-triggers  │
    │ _loadTierLeaderboard()     │
    └─────────┬──────────────────┘
              │
    ┌─────────▼──────────────────┐
    │ API Call with Filters      │
    │ query: {                   │
    │   tier: _selectedTier,     │
    │   page: _currentPage,      │
    │   ...                      │
    │ }                          │
    └─────────┬──────────────────┘
              │
    ┌─────────▼──────────────────┐
    │ Display Results            │
    │ (Table or Cards)           │
    └────────────────────────────┘
```

---

## Color Palette Reference

```
┌──────────────────────────────────────────────────┐
│ COLOR SYSTEM                                     │
├──────────────────────────────────────────────────┤
│                                                  │
│ TIER COLORS (Gradient Backgrounds)               │
│ ────────────────────────────────                │
│ Bronze:     Brown[400]                           │
│ Silver:     Grey[400]                            │
│ Gold:       Amber[600]                           │
│ Platinum:   Blue[300]                            │
│ Diamond:    LightBlue[300]                       │
│ Master:     Purple[400]                          │
│ Grandmaster:DeepPurple[400]                      │
│ Ultimate:   Pink[400]                            │
│                                                  │
│ STAT COLORS                                      │
│ ───────────                                      │
│ Wins:       Green[700]                           │
│ Losses:     Red[700]                             │
│ Draws:      Amber[700]                           │
│                                                  │
│ UI COLORS                                        │
│ ─────────                                        │
│ Background:     White / Grey[50]                 │
│ Dividers:       Grey[200]                        │
│ Header BG:      Grey[100]                        │
│ Text Primary:   Grey[900]                        │
│ Text Secondary: Grey[600]                        │
│ Sort Active:    Theme.primaryColor               │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## State Management

```
_ComprehensiveLeaderboardScreenState
├── _selectedTier: int?
├── _dateRange: DateTimeRange?
├── _searchQuery: String?
├── _currentPage: int = 1
└── _viewMode: String ('tier' | 'all_tiers')

UI Rebuild Triggers:
├── setState() in _handleTierChange
├── setState() in _handleDateRangeChange
├── setState() in _handleSearchChange
├── setState() in _handlePageChange
└── setState() in _handleViewModeChange
```

---

## Performance Optimization Strategies

```
1. CLIENT-SIDE FILTERING
   • Search and sort happen locally
   • No extra API calls for filtering
   • Instant user feedback

2. PAGINATION
   • Only load 50 players per page
   • Reduces memory usage
   • Faster API responses

3. LAZY LOADING (All Tiers Mode)
   • Loads tiers sequentially
   • Not cached (re-fetches each time)
   • Could be optimized with caching

4. SORTING EFFICIENCY
   • O(n log n) using Dart List.sort()
   • Only re-sorts when user clicks
   • No constant re-sorting

5. RESPONSIVE RENDERING
   • Conditional widget building
   • Desktop: Complex table only at ≥1000px
   • Mobile: Simpler cards at <1000px
```

---

**Status:** ✅ COMPLETE  
**Last Updated:** 2026-06-30  
**Architecture Version:** 1.0
