# Assets Directory Organization Guide

## Current Structure Overview

```
assets/
├── 3d/                          → 3D models and related files
├── avatarPackages/              → User avatar packages
├── config/                      → Configuration files (.env, JSON configs)
├── data/                        → Game data files (mini-games, JSON)
├── icons/                       → UI icons and icon index
├── images/                      → Images (backgrounds, logos, collections)
├── models/                      → Data model definitions
├── questions/                   → Question datasets (by category)
├── screenshots/                 → App screenshots
├── seeds/                       → Seed data for initialization
├── sfx/                         → Sound effects (8 categories)
├── shaders/                     → GLSL shader files
├── songs/                       → Background music
├── sounds/                      → Audio files
├── splash_previews/             → Splash screen previews
└── zip/                         → Compressed asset bundles
```

## Current Status: Good Organization ✅

The assets directory is **reasonably well-organized** with clear category separation. However, there are opportunities for optimization.

## Recommended Improvements

### 1. **Consolidate Audio Assets** 🔊

**Current State**:
```
assets/
├── sounds/      (General audio files)
├── songs/       (Background music)
├── sfx/         (Sound effects - 8 subdirectories)
└── [scattered in other directories]
```

**Recommended Structure**:
```
assets/
└── audio/
    ├── music/       (Background music, songs)
    ├── sfx/         (Sound effects by category)
    │   ├── ui/      (Button clicks, menu sounds)
    │   ├── game/    (Game-play sounds)
    │   ├── rewards/ (Reward/achievement sounds)
    │   ├── ambient/ (Background ambience)
    │   └── ...
    └── voiceover/   (If needed in future)
```

**Benefits**:
- Single source of truth for all audio
- Easier to manage audio permissions and loading
- Clear categorization by use-case
- Simplified pubspec.yaml asset references

**Migration Steps**:
```bash
# Create new audio structure
mkdir -p assets/audio/music
mkdir -p assets/audio/sfx/ui
mkdir -p assets/audio/sfx/game
mkdir -p assets/audio/sfx/rewards

# Move files (update in code after)
mv assets/songs/* assets/audio/music/
mv assets/sounds/* assets/audio/music/  # Or sfx based on type
mv assets/sfx/* assets/audio/sfx/

# Remove old directories
rmdir assets/songs
rmdir assets/sounds
rmdir assets/sfx
```

### 2. **Organize Images by Purpose** 🖼️

**Current State**:
```
assets/images/
├── backgrounds/     (Game backgrounds)
├── collections/     (Collection item images)
├── logo/            (App logos)
├── quiz/            (Quiz-related images)
├── rewards/         (Reward images)
├── welcome_images/  (Onboarding images)
└── avatars/         (User avatars)
```

**Recommended Additions**:
```
assets/images/
├── backgrounds/
│   ├── game/        (Gameplay backgrounds)
│   ├── ui/          (UI backgrounds)
│   └── patterns/    (Repeating patterns)
├── brand/           (Logo, branding assets)
│   ├── logo/        (App logos)
│   ├── wordmark/    (Text logos)
│   └── icons/       (Brand icon variations)
├── collections/
├── ui/              (NEW - Generic UI elements)
│   ├── buttons/
│   ├── cards/
│   ├── badges/
│   └── decorations/
├── quiz/
├── rewards/
├── user/            (NEW - User-related images)
│   ├── avatars/     (Move here from root)
│   └── backgrounds/
├── onboarding/      (Rename from welcome_images)
└── game/            (NEW - Gameplay images)
    ├── characters/
    ├── items/
    └── effects/
```

**Benefits**:
- Clear purpose-based organization
- Easier to find and update related images
- Better separation of concerns
- Simpler asset loading logic

### 3. **Consolidate Configuration Files** ⚙️

**Current State**:
```
assets/config/
├── .env.prod
├── .env.staging
├── config.json
├── localization_strings.json
└── segments.json
```

**Recommended Enhancement**:
```
assets/config/
├── environments/        (NEW - Environment-specific configs)
│   ├── development.env
│   ├── staging.env
│   └── production.env
├── app/                 (NEW - App-wide configuration)
│   ├── app-config.json
│   ├── feature-flags.json
│   └── version.json
├── localization/        (NEW - Language files)
│   ├── localization_strings.json
│   └── [other language files]
├── segments.json        (Keep for now, consider moving to app/)
└── README.md           (NEW - Config documentation)
```

**Benefits**:
- Environment configs easily identifiable
- Feature flags organized separately
- Internationalization files grouped
- Easier to add new configurations

### 4. **Organize Game Data** 🎮

**Current State**:
```
assets/data/
└── mini-games/
    └── word_search_easy.json

assets/questions/  (Category-organized question sets)
```

**Recommended Structure**:
```
assets/data/
├── game-content/        (Game-specific content)
│   ├── mini-games/
│   │   ├── word-search/
│   │   ├── trivia/
│   │   └── [other games]/
│   └── challenges/
├── seeds/               (Move from root - Seed/initialization data)
│   ├── user/
│   ├── rewards/
│   └── leaderboard/
└── README.md
```

**Benefits**:
- Game content clearly separated
- Easy to add new mini-games
- Seed data organized by type
- Clearer data hierarchy

### 5. **Create a Visual Assets Subdirectory** 🎨

**New Directory**:
```
assets/visual/          (NEW - All visual-only assets)
├── screenshots/        (Move from root)
├── previews/           (Move splash_previews here)
├── mockups/            (NEW - UI mockups)
└── design-reference/   (NEW - Design guidelines, color palettes)
```

**Benefits**:
- Separates documentation assets from functional assets
- Easier to identify what's needed for builds vs. reference
- Can be excluded from app builds if needed

## Step-by-Step Migration Plan

### Phase 1: Low-Risk Consolidation (No Code Changes)
1. Consolidate audio files (minimal code references)
2. Consolidate visual/preview assets
3. Create new structure in parallel

### Phase 2: Update pubspec.yaml References
1. Update assets list with new paths
2. Ensure all old paths still work (soft migration)
3. Run tests to verify no asset loading errors

### Phase 3: Update Code References
1. Update all asset loading code for renamed paths
2. Update image asset references
3. Update audio loading logic

### Phase 4: Cleanup
1. Remove old directory structures
2. Update documentation
3. Update asset loading utilities

## File Size Analysis

Before reorganizing, understand what's large:

```bash
# Find largest directories
du -sh assets/*/ | sort -hr

# Find largest files
find assets -type f -exec du -h {} \; | sort -hr | head -20
```

**Current Large Assets**:
- `avatarPackages/` - User avatar collections
- `images/` - Image assets
- `sounds/`, `songs/`, `sfx/` - Audio files
- `questions/` - Question datasets

## pubspec.yaml Updates

**Current**:
```yaml
assets:
  - assets/config/
  - assets/images/
  - assets/sounds/
  - assets/songs/
  - assets/sfx/
  - [many specific files]
```

**After Reorganization**:
```yaml
assets:
  - assets/audio/
  - assets/config/
  - assets/data/
  - assets/images/
  - assets/models/
  - assets/questions/
  - assets/seeds/
  - assets/shaders/
  - assets/visual/
  - [any remaining specific files]
```

## Asset Loading Utilities

**Create or update**: `lib/core/services/asset_loader.dart`

```dart
class AssetLoader {
  // Images
  static const String logoPath = 'assets/images/brand/logo/synaptix_logo.png';
  static const String bgGamePath = 'assets/images/backgrounds/game/';
  
  // Audio
  static const String musicPath = 'assets/audio/music/';
  static const String sfxPath = 'assets/audio/sfx/';
  
  // Config
  static const String configPath = 'assets/config/';
  
  // Data
  static const String questionsPath = 'assets/questions/';
  static const String dataPath = 'assets/data/';
}
```

**Benefits**:
- Centralized asset path management
- Easier to update paths when reorganizing
- Type-safe asset references
- Documentation of available assets

## Implementation Priority

### 🔴 High Priority
1. Consolidate audio assets (sfx, songs, sounds → audio/)
2. Organize images by purpose (backgrounds/game, backgrounds/ui, etc.)
3. Create visual/ directory for non-functional assets

### 🟡 Medium Priority
4. Reorganize configuration files
5. Organize game data and seeds
6. Create asset loading utilities

### 🟢 Low Priority
7. Create mockups/design-reference directories
8. Add documentation to each directory
9. Optimize asset sizes

## Before/After Comparison

### Before
```
assets/                    (17 top-level directories)
├── sounds/
├── songs/
├── sfx/
├── splash_previews/
├── screenshots/
└── [others]
```

### After
```
assets/                    (9 top-level directories)
├── audio/
│   ├── music/
│   └── sfx/
├── images/
├── config/
├── data/
├── visual/
│   ├── previews/
│   └── screenshots/
└── [others]
```

**Reduction**: 17 → 9 directories at root level (-47% directories)

## Testing Checklist

After reorganization:
- [ ] All asset paths updated in code
- [ ] pubspec.yaml references correct
- [ ] App builds successfully (Android, iOS, Web)
- [ ] No missing asset errors at runtime
- [ ] Images load correctly
- [ ] Audio plays correctly
- [ ] No performance regression
- [ ] Test all platforms

## Documentation

Update these files after migration:
- [ ] This file (ASSETS_ORGANIZATION_GUIDE.md)
- [ ] pubspec.yaml (asset references)
- [ ] README.md (asset documentation)
- [ ] New README.md files in each major directory
- [ ] Code comments referencing asset paths

## Additional Resources

- [Flutter Assets Documentation](https://flutter.dev/docs/development/ui/assets-and-images)
- [Asset Caching Best Practices](https://flutter.dev/docs/cookbook/images/cached-images)
- [Performance Tips for Large Assets](https://flutter.dev/docs/perf/rendering-performance)

## Questions?

- **Asset Loading Issues**: Check `lib/core/services/asset_resolver.dart`
- **Image Performance**: See optimization guide in assets README
- **Audio Management**: Check audio service implementation

---

**Document Status**: Recommendation  
**Last Updated**: 2026-06-23  
**Recommended Implementation**: Next major version bump
