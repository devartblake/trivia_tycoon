import 'package:flutter/material.dart';
import '../../ui_components/cards/slide_to_expand_card.dart';
import '../../ui_components/cards/sliding_panel_card.dart';
import '../../ui_components/cards/swipe_to_reveal_card.dart';

class SlidingCardDemoScreen extends StatefulWidget {
  const SlidingCardDemoScreen({super.key});

  @override
  State<SlidingCardDemoScreen> createState() => _SlidingCardDemoScreenState();
}

class _SlidingCardDemoScreenState extends State<SlidingCardDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _handleEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit action triggered")),
    );
  }

  void _handleDelete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Delete action triggered")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sliding Card Variants"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Swipe"),
            Tab(text: "Expand"),
            Tab(text: "Panel"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Swipe-to-Reveal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwipeToRevealCard(
                  content: const ListTile(
                    title: Text("Swipe me left or right"),
                    subtitle: Text("To trigger actions"),
                  ),
                  onEdit: _handleEdit,
                  onDelete: _handleDelete,
                ),
              ],
            ),
          ),
          // Slide-to-Expand
          Padding(
            padding: const EdgeInsets.all(16),
            child: SlideToExpandCard(
              collapsedContent: const ListTile(
                title: Text("Tap to expand"),
                subtitle: Text("More content below..."),
              ),
              expandedContent: const Text("Here is some extra expanded info."),
            ),
          ),
          // Sliding Panel
          Padding(
            padding: const EdgeInsets.all(16),
            child: SlidingPanelCard(
              mainContent: const ListTile(
                title: Text("Panel Example"),
                subtitle: Text("Click 'More' to slide up"),
              ),
              panelContent: const Text("This is the hidden sliding panel content."),
            ),
          ),
        ],
      ),
    );
  }
}