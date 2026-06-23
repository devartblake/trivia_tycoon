/// Barrel export for Synaptix home dashboard widgets.
///
/// This file re-exports all dashboard widgets organized by responsibility:
/// - Layout: Container widgets and structural components
/// - Navigation: Top bar, drawer, rail, compact nav
/// - Cards: Feature cards (hero, game modes, profile, etc.)
/// - Tiles: Small reusable components (achievements, etc.)
/// - Components: Base UI components (progress bar, panel header, etc.)
///
/// Implementation details (private widgets) are not re-exported.
/// Consumers import from this file to access all public widgets.
library;

// Layout widgets
export 'layout/synaptix_panel.dart';
export 'layout/synaptix_dashboard_footer.dart';
export 'layout/news_reward_row.dart';

// Navigation widgets
export 'navigation/synaptix_top_navigation_bar.dart';
export 'navigation/synaptix_compact_nav.dart';
export 'navigation/synaptix_left_rail.dart';
export 'navigation/synaptix_home_drawer.dart';

// Right panel (used in adaptive scaffold)
export 'navigation/synaptix_rail_content.dart' show SynaptixRightPanel;

// Card widgets (features, stats, recommendations, etc.)
export 'cards/hero_tournament_card.dart';
export 'cards/game_mode_grid.dart';
export 'cards/progression_card.dart';
export 'cards/featured_event_card.dart';
export 'cards/profile_summary_card.dart';
export 'cards/daily_missions_card.dart';
export 'cards/leaderboard_preview_card.dart';
export 'cards/recent_activity_card.dart';
export 'cards/recommendations_card.dart';
export 'cards/news_card.dart';
export 'cards/daily_reward_card.dart';
export 'cards/friends_online_card.dart';
export 'cards/complete_profile_card.dart';

// Tile widgets (small, repeatable components)
export 'tiles/achievement_tile.dart';

// Base UI components (used across multiple widgets)
export 'components/synaptix_progress_bar.dart';
