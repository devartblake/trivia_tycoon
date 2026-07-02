# SkillTreeVisualization Implementation Plan

**Objective:** Build interactive skill tree visualization for player analytics  
**Estimated Effort:** 3-4 hours  
**Timeline:** Single working session (Day 2 - 2026-07-01)  
**Status:** PLANNING → Ready for Implementation

---

## 📋 EXECUTIVE SUMMARY

### What We're Building
An interactive skill tree visualization screen showing player's learned skills, progression, and unlock paths. This is a core feature of the analytics dashboard that helps players understand their growth trajectory.

### Key Features
- ✅ Visual skill tree layout (multi-tier/branch structure)
- ✅ Skill node display (locked/unlocked/mastered states)
- ✅ XP progress tracking
- ✅ Interactive skill detail popup
- ✅ Prerequisite visualization
- ✅ Responsive grid layout
- ✅ Color-coded by category

### Success Criteria
- Displays all skills organized by tier/branch
- Shows unlock status (locked/unlocked/mastered)
- Displays XP progress to next level
- Shows prerequisites and unlock requirements
- Responds to tap with detail popup
- Responsive on mobile/tablet/web
- Smooth animations
- No performance issues

---

## 🎨 DESIGN SPECIFICATION

### Screen Layout

```
┌─────────────────────────────────────────────────┐
│  Skill Tree                              [↻]    │
├─────────────────────────────────────────────────┤
│                                                 │
│  TIER 1: FOUNDATION SKILLS                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Skill 1  │  │ Skill 2  │  │ Skill 3  │     │
│  │ Level 3  │  │ LOCKED   │  │ Level 5  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│       │              ↓              ↓           │
│       └──────────────┴──────────────┘          │
│  TIER 2: INTERMEDIATE SKILLS                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Skill 4  │  │ Skill 5  │  │ Skill 6  │     │
│  │ Level 2  │  │ LOCKED   │  │ LOCKED   │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│                                                 │
│  TIER 3: ADVANCED SKILLS                      │
│  ┌──────────┐  ┌──────────┐                    │
│  │ Skill 7  │  │ Skill 8  │                    │
│  │ LOCKED   │  │ LOCKED   │                    │
│  └──────────┘  └──────────┘                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Skill Node Card States

#### LOCKED State
```
┌────────────────┐
│   🔒          │
│   Skill Name  │
│   Req: Lvl 3  │
│   Req: Skill1 │
└────────────────┘
Color: Grey with lock icon
```

#### UNLOCKED State (In Progress)
```
┌────────────────┐
│   ✓            │
│   Skill Name  │
│   Level 2/10  │
│   ▓▓▓░░ 30%  │
└────────────────┘
Color: Category color (semi-active)
```

#### MASTERED State
```
┌────────────────┐
│   ⭐          │
│   Skill Name  │
│   Level 10    │
│   MASTERED    │
└────────────────┘
Color: Category color (bright)
```

---

## 📊 DATA STRUCTURE

### Input Data (From Existing Services)
```dart
// Players have a list of SkillNode objects
List<SkillNode> playerSkills;

// Structure per skill:
class SkillNode {
  String skillId;
  String name;
  String category;
  String? description;
  int level; // 1-10
  int totalXpRequired;
  int currentXp;
  List<String> prerequisites; // SKill IDs
  DateTime? unlockedAt;
  DateTime? masteredAt;
  
  bool get isMastered => level >= 10;
  double get progressPercent => (currentXp / xpToNextLevel);
}

// Skill categories for colors
enum SkillCategory {
  scholar, strategist, xp, risk, luck, combo,
  elite, timer, combat, stealth, category, wildcard
}
```

### Tree Organization
```dart
// Organize skills into tiers/branches
class SkillTreeLayout {
  List<SkillTier> tiers;
}

class SkillTier {
  int tierNumber; // 1, 2, 3...
  List<SkillNode> skills;
  String title; // "Foundation", "Intermediate", etc.
}

// OR organize by category branches
class SkillBranch {
  SkillCategory category;
  List<SkillNode> skills;
}
```

---

## 🏗️ COMPONENT ARCHITECTURE

### Main Screen Component
**File:** `lib/screens/analytics/skill_tree_visualization.dart`

```dart
class SkillTreeVisualization extends ConsumerWidget {
  // Properties:
  - playerSkills: List<SkillNode> (from provider)
  - selectedSkill: SkillNode? (current selection)
  - expandedTier: int? (which tier expanded)
  
  // Methods:
  - build() - Main layout
  - _buildTierSection() - Single tier with skills
  - _onSkillTap() - Open detail popup
  - _onSkillClose() - Close detail popup
}
```

### Sub-Components (Reusable)

#### 1. SkillNodeCard
**Purpose:** Display individual skill node  
**States:** Locked, Unlocked (In Progress), Mastered  
**Events:** On tap → show details

```dart
class SkillNodeCard extends StatelessWidget {
  final SkillNode skill;
  final VoidCallback onTap;
  final bool isSelected;
  
  // Visual elements:
  - Icon (🔒, ✓, ⭐)
  - Skill name
  - Level indicator
  - Progress bar (if unlocked)
  - Color from category
}
```

#### 2. SkillDetailPopup
**Purpose:** Show full skill details in dialog  
**Content:**
  - Skill name + category
  - Full description
  - Current level/XP progress
  - Prerequisites (with status)
  - Unlock date (if applicable)
  - Suggestion for next steps

```dart
class SkillDetailPopup extends StatelessWidget {
  final SkillNode skill;
  final VoidCallback onClose;
  
  // Sections:
  - Header (name, category, icon)
  - Progress section (level, XP bar)
  - Requirements section (prerequisites)
  - Details section (description, effects)
  - Action button (if locked: show requirements)
}
```

#### 3. SkillTierSection
**Purpose:** Display all skills in one tier  
**Layout:** Horizontal grid or vertical list

```dart
class SkillTierSection extends StatelessWidget {
  final int tierNumber;
  final String tierTitle; // "Foundation", "Advanced"
  final List<SkillNode> skills;
  final void Function(SkillNode) onSkillTap;
  
  // Layout:
  - Section header with tier name
  - GridView or Row of skill cards
  - Connection lines showing prerequisites
}
```

#### 4. PrerequisiteIndicator
**Purpose:** Show requirement status and connections  
**Shows:**
  - Required skill name
  - Whether parent skill is unlocked
  - Visual arrow/line to parent

```dart
class PrerequisiteIndicator extends StatelessWidget {
  final SkillNode requiredSkill;
  final bool isMet; // Parent skill is mastered
  
  // Visual:
  - Icon (✓ or ✗)
  - Skill name
  - Color based on status
}
```

#### 5. SkillProgressBar
**Purpose:** Visual XP progress  
**Shows:**
  - Current XP / XP needed
  - Level (1/10, 2/10, etc.)
  - Progress percentage
  - Color from category

```dart
class SkillProgressBar extends StatelessWidget {
  final SkillNode skill;
  
  // Displays:
  - LinearProgressIndicator
  - Level text ("Level 3/10")
  - XP text ("1,250 / 2,500 XP")
}
```

---

## 🎯 IMPLEMENTATION STEPS

### Step 1: Setup & Data Access (20 min)
**Task:** Create main screen and set up Riverpod provider access

```dart
// Create lib/screens/analytics/skill_tree_visualization.dart
class SkillTreeVisualization extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch skillProgressionProvider (or similar)
    final skillsAsync = ref.watch(playerSkillsProvider); // To create
    
    return Scaffold(
      appBar: AppBar(title: Text('Skill Tree')),
      body: skillsAsync.when(
        data: (skills) => _buildTree(skills),
        loading: () => LoadingWidget(),
        error: (e, st) => ErrorWidget(),
      ),
    );
  }
  
  Widget _buildTree(List<SkillNode> skills) {
    // TODO: Organize and display skills
  }
}
```

**Deliverable:** Skeleton screen with loading/error states

---

### Step 2: Organize Skills by Tier (20 min)
**Task:** Group skills into tiers/branches

```dart
// In SkillTreeVisualization
Map<int, List<SkillNode>> _groupSkillsByTier(
  List<SkillNode> skills,
) {
  final tierMap = <int, List<SkillNode>>{};
  for (final skill in skills) {
    // Determine tier (could be based on XP cost, category, etc.)
    final tier = _determineTierForSkill(skill);
    (tierMap[tier] ??= []).add(skill);
  }
  return tierMap;
}

String _getTierTitle(int tier) {
  switch (tier) {
    case 1: return 'Foundation Skills';
    case 2: return 'Intermediate Skills';
    case 3: return 'Advanced Skills';
    default: return 'Tier $tier';
  }
}
```

**Deliverable:** Skills organized and ready to display

---

### Step 3: Create SkillNodeCard Component (30 min)
**Task:** Build reusable skill card that shows different states

```dart
// Create lib/ui_components/skill_tree/skill_node_card.dart
class SkillNodeCard extends StatelessWidget {
  final SkillNode skill;
  final VoidCallback onTap;
  final bool isSelected;
  
  Color _getCardColor() {
    if (skill.isMastered) return Colors.green;
    if (skill.level > 0) return Colors.blue;
    return Colors.grey;
  }
  
  IconData _getIcon() {
    if (skill.level == 0) return Icons.lock;
    if (skill.isMastered) return Icons.star;
    return Icons.check_circle;
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: _getCardColor().withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(_getIcon(), size: 32, color: _getCardColor()),
              SizedBox(height: 8),
              Text(skill.name, textAlign: TextAlign.center),
              if (skill.level > 0) ...[
                SizedBox(height: 4),
                Text('Level ${skill.level}/10', style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

**Deliverable:** Card component working in all 3 states

---

### Step 4: Create SkillDetailPopup (30 min)
**Task:** Build dialog showing full skill details

```dart
// Create lib/ui_components/skill_tree/skill_detail_popup.dart
class SkillDetailPopup extends StatelessWidget {
  final SkillNode skill;
  final VoidCallback onClose;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(skill.name, style: Theme.of(context).textTheme.headlineSmall),
                IconButton(icon: Icon(Icons.close), onPressed: onClose),
              ],
            ),
            SizedBox(height: 16),
            
            // Category & Status
            Chip(label: Text(skill.category.toString())),
            SizedBox(height: 16),
            
            // Progress (if unlocked)
            if (skill.level > 0) ...[
              _buildProgressSection(skill),
              SizedBox(height: 16),
            ],
            
            // Description
            if (skill.description != null) ...[
              Text(skill.description!, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 16),
            ],
            
            // Prerequisites
            if (skill.prerequisites.isNotEmpty) ...[
              Text('Requirements:', style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 8),
              ...skill.prerequisites.map((prereq) => 
                Text('• $prereq', style: TextStyle(fontSize: 12))
              ),
              SizedBox(height: 16),
            ],
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressSection(SkillNode skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level ${skill.level}/10'),
            Text('${(skill.progressPercent * 100).toStringAsFixed(0)}%'),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: skill.progressPercent,
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text(
          '${skill.currentXp} / ${skill.totalXpRequired} XP',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
```

**Deliverable:** Dialog displaying skill details

---

### Step 5: Create SkillTierSection (30 min)
**Task:** Display all skills in a tier with layout

```dart
// Create lib/ui_components/skill_tree/skill_tier_section.dart
class SkillTierSection extends StatelessWidget {
  final int tierNumber;
  final String tierTitle;
  final List<SkillNode> skills;
  final void Function(SkillNode) onSkillTap;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tierTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        // Grid of skill cards
        GridView.count(
          crossAxisCount: _getColumnCount(context),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: skills.map((skill) => 
            SkillNodeCard(
              skill: skill,
              onTap: () => onSkillTap(skill),
            ),
          ).toList(),
        ),
        
        SizedBox(height: 24),
      ],
    );
  }
  
  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1000) return 6; // Desktop
    if (width > 600) return 4;  // Tablet
    return 3; // Mobile
  }
}
```

**Deliverable:** Tier section with responsive grid

---

### Step 6: Build Main Layout (30 min)
**Task:** Assemble all components into main screen

```dart
// In SkillTreeVisualization._buildTree()
Widget _buildTree(List<SkillNode> skills) {
  final tierMap = _groupSkillsByTier(skills);
  final tierNumbers = tierMap.keys.toList()..sort();
  
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Skill Tree', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshSkills, // TODO
            ),
          ],
        ),
        SizedBox(height: 24),
        
        // Summary stats
        _buildSummaryStats(skills),
        SizedBox(height: 24),
        
        // Tiers
        ...tierNumbers.map((tier) => 
          SkillTierSection(
            tierNumber: tier,
            tierTitle: _getTierTitle(tier),
            skills: tierMap[tier]!,
            onSkillTap: (skill) => _showSkillDetails(skill),
          ),
        ),
      ],
    ),
  );
}

void _showSkillDetails(SkillNode skill) {
  showDialog(
    context: context,
    builder: (context) => SkillDetailPopup(
      skill: skill,
      onClose: () => Navigator.pop(context),
    ),
  );
}

Widget _buildSummaryStats(List<SkillNode> skills) {
  final totalSkills = skills.length;
  final masteredCount = skills.where((s) => s.isMastered).length;
  final unlockedCount = skills.where((s) => s.level > 0).length;
  
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildStatCard('Total Skills', totalSkills.toString()),
      _buildStatCard('Unlocked', unlockedCount.toString()),
      _buildStatCard('Mastered', masteredCount.toString()),
    ],
  );
}

Widget _buildStatCard(String label, String value) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ),
  );
}
```

**Deliverable:** Complete working screen

---

### Step 7: Add Animations & Polish (20 min)
**Task:** Smooth animations and final touches

```dart
// Optional: Add animations
- Staggered animation on skill cards (FadeTransition, ScaleTransition)
- Smooth dialog open/close
- Progress bar animation
- Hover effects on desktop

// Optional: Add details
- Tooltip on skill icons
- "Tap to learn more" hint
- Category color coding
- Connection lines between prerequisites
```

**Deliverable:** Polish animations and UX

---

### Step 8: Testing & Verification (20 min)
**Task:** Manual testing and bug fixes

```dart
// Test scenarios:
- ✅ All skill states display correctly (locked/unlocked/mastered)
- ✅ Progress bars show accurate percentages
- ✅ Tapping skill shows detail popup
- ✅ Popup shows all required information
- ✅ Prerequisites display correctly
- ✅ Empty states handled
- ✅ Responsive on mobile/tablet/desktop
- ✅ No performance issues (smooth scrolling)
- ✅ No warnings/errors in console
```

**Deliverable:** Verified working component

---

## 📝 FILE STRUCTURE

```
lib/
├── screens/
│   └── analytics/
│       └── skill_tree_visualization.dart (400-500 lines)
│
└── ui_components/
    └── skill_tree/
        ├── skill_node_card.dart (80-100 lines)
        ├── skill_detail_popup.dart (150-200 lines)
        ├── skill_tier_section.dart (100-120 lines)
        ├── skill_progress_bar.dart (80-100 lines)
        └── prerequisite_indicator.dart (80-100 lines)

Total: ~900-1100 lines of new code
```

---

## 🔗 INTEGRATION POINTS

### Required Provider (Create if Missing)
```dart
// In game/providers/skill_progression_provider.dart
final playerSkillsProvider = FutureProvider<List<SkillNode>>((ref) async {
  // Fetch from API or local storage
  // Return player's skill list
});
```

### Route Configuration
```dart
// In core/navigation/app_router.dart
GoRoute(
  path: '/analytics/skills',
  builder: (context, state) => const SkillTreeVisualization(),
),
```

### Navigation Hook
```dart
// In PlayerAnalyticsDashboard
onCategoryTap: (category) {
  if (category == 'skills') {
    context.go('/analytics/skills');
  }
},
```

---

## ⏱️ DETAILED TIMELINE

| Step | Task | Duration | Cumulative |
|------|------|----------|-----------|
| 1 | Setup & Data Access | 20 min | 20 min |
| 2 | Organize Skills | 20 min | 40 min |
| 3 | SkillNodeCard | 30 min | 70 min |
| 4 | SkillDetailPopup | 30 min | 100 min |
| 5 | SkillTierSection | 30 min | 130 min |
| 6 | Main Layout | 30 min | 160 min |
| 7 | Animations/Polish | 20 min | 180 min |
| 8 | Testing | 20 min | 200 min |
| **TOTAL** | | **~3.3 hours** | **200 min** |

**Buffer:** 20-30 min for unexpected issues  
**Est. End Time:** 3.5-4 hours

---

## ✅ SUCCESS CRITERIA

### Functionality
- ✅ All skills display in appropriate tier
- ✅ Correct state display (locked/unlocked/mastered)
- ✅ Detail popup shows on skill tap
- ✅ All skill info visible in popup
- ✅ Progress bars accurate
- ✅ Prerequisites visible

### Quality
- ✅ No compiler errors
- ✅ No warnings
- ✅ Responsive on all screen sizes
- ✅ Smooth animations
- ✅ No performance issues

### Integration
- ✅ Route added to GoRouter
- ✅ Riverpod provider available
- ✅ Connects to existing skill data
- ✅ Ready for widget tests

---

## 🚀 AFTER COMPLETION

### Immediate Next Steps
1. Create PerformanceLineChart (2-3h next)
2. Write widget tests (8-10h after)
3. Route integration (1h during component work)

### Future Enhancements (Not Included)
- Branch/path recommendations
- Ability to spend XP to unlock skills
- Social comparison (compare with friends)
- Skill effects preview
- Category filtering
- Search functionality
- Achievement celebrations
- Skill category branches visualization

---

## 📚 REFERENCE MATERIALS

**Existing Skill Infrastructure:**
- `SkillNode` model in `lib/game/models/skill_progression_model.dart`
- `SkillCategory` enum in `lib/game/models/skill_tree_graph.dart`
- Skill data in `assets/data/skill_tree.json`
- Skill controller in `lib/game/controllers/skill_tree_controller.dart`

**Related Components:**
- CategoryPerformanceDetail (recent work)
- DifficultyBreakdownCard (recent work)
- TierNotificationService (recent work)

---

## 🎯 DECISION POINTS (Make Before Coding)

1. **Skill Organization**
   - By Tier (based on XP cost)? ✅ RECOMMENDED
   - By Category (Scholar, Strategist, etc.)?
   - By Branch (Combat, Enhancement, Utility)?
   - DECISION: Use Tier-based for MVP

2. **Visual Layout**
   - Grid (3-6 columns)? ✅ RECOMMENDED
   - Vertical list?
   - Connection lines between prerequisites?
   - DECISION: Start with grid, add lines if time

3. **Prerequisite Display**
   - In popup only?
   - As connection lines? ✅ NICE TO HAVE
   - As badges on card?
   - DECISION: In popup + optional badges

4. **Animation Level**
   - Simple (just fade)? ✅ RECOMMENDED FOR MVP
   - Moderate (staggered, progress bars)
   - Complex (3D, particle effects)
   - DECISION: Keep animations modest, focus on functionality

---

## ✨ ASSUMPTIONS

1. **SkillNode data** is already available via provider
2. **Categories** have associated colors available
3. **Tier/level determination** logic is clear (based on XP cost)
4. **No real-time updates** needed (batch refresh with icon button)
5. **Mobile-first** design approach
6. **Mock data** acceptable for initial testing

---

## 📞 IMPLEMENTATION NOTES

### Code Style
- Use const constructors where possible
- Follow project naming conventions
- Use Riverpod for state management
- Proper null safety throughout
- Clear widget separation

### Testing Approach
- Manual testing first (check all states)
- Then write 15-20 widget tests
- Test edge cases (empty, many skills, etc.)

### Performance Considerations
- GridView with shrinkWrap: true for nested scrolling
- NeverScrollableScrollPhysics to prevent nested scroll issues
- Lazy loading for detail popups
- Reusable components to avoid rebuilds

---

## 🎓 LEARNING OUTCOMES

After completing this component, you'll have:
- Experience with complex list layouts
- Multi-state UI component patterns
- Dialog/popup management
- Responsive grid design
- Riverpod provider integration
- Animation basics

---

**Status:** ✅ Plan Ready  
**Recommendation:** Start implementation immediately after approval  
**Expected Completion:** Day 2, Session End (~2:00 PM)  
**Next Component:** PerformanceLineChart (depends on this)
