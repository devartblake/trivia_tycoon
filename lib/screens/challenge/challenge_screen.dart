import 'package:flutter/material.dart';
import 'package:trivia_tycoon/screens/challenge/widgets/challenge_panel_widget.dart';
import 'package:trivia_tycoon/screens/challenge/widgets/parallax_backdrop_widget.dart';
import '../../game/models/challenge_models.dart';

/// Main Challenge Screen with tabs for Daily, Weekly, and Special challenges
/// Performance optimizations:
/// - Uses const constructors where possible
/// - Lazy tab loading with TabBarView
/// - Cached tab controller
/// - RepaintBoundary on animated background
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(theme),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: const Text(
        'Challenges',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.25),
      elevation: 0,
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.flash_on_rounded),
            text: 'Daily',
          ),
          Tab(
            icon: Icon(Icons.emoji_events_rounded),
            text: 'Weekly',
          ),
          Tab(
            icon: Icon(Icons.public_rounded),
            text: 'Special',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated background (isolated with RepaintBoundary in widget)
        const LightModernBackdrop(),

        // Darkening overlay for readability
        Container(color: Colors.black.withOpacity(0.20)),

        // Content
        SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ChallengePanel(type: ChallengeType.daily),
              ChallengePanel(type: ChallengeType.weekly),
              ChallengePanel(type: ChallengeType.special),
            ],
          ),
        ),
      ],
    );
  }
}