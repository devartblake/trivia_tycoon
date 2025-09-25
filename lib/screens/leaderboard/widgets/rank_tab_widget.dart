import 'package:flutter/material.dart';

class TierData {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  TierData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color
  });
}

final List<TierData> tierList = [
  TierData(id: 1, name: "Bronze", icon: Icons.emoji_events, color: Colors.brown),
  TierData(id: 2, name: "Silver", icon: Icons.star_border, color: Colors.grey),
  TierData(id: 3, name: "Gold", icon: Icons.star, color: Colors.amber),
  TierData(id: 4, name: "Platinum", icon: Icons.shield, color: Colors.cyan),
  TierData(id: 5, name: "Diamond", icon: Icons.diamond, color: Colors.blueAccent),
  TierData(id: 6, name: "Master", icon: Icons.workspace_premium, color: Colors.deepPurple),
  TierData(id: 7, name: "Grandmaster", icon: Icons.military_tech, color: Colors.redAccent),
  TierData(id: 8, name: "Champion", icon: Icons.emoji_events_outlined, color: Colors.orangeAccent),
  TierData(id: 9, name: "Elite", icon: Icons.workspace_premium_outlined, color: Colors.pinkAccent),
  TierData(id: 10, name: "Tycoon", icon: Icons.monetization_on_outlined, color: Colors.teal),
];

class RankTabBarWidget extends StatefulWidget {
  final int initialTier;
  final ValueChanged<int> onTierSelected;

  const RankTabBarWidget({
    super.key,
    required this.initialTier,
    required this.onTierSelected,
  });

  @override
  State<RankTabBarWidget> createState() => _RankTabBarWidgetState();
}

class _RankTabBarWidgetState extends State<RankTabBarWidget> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tierList.length, vsync: this, initialIndex: widget.initialTier);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      widget.onTierSelected(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          tabs: tierList.map((tier) {
            return Tab(
              icon: Icon(tier.icon),
              text: tier.name,
            );
          }).toList(),
        ),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _tabController,
            children: tierList.map((tier) {
              return Center(
                child: Text(
                  "Leaderboard for ${tier.name} Tier",
                  style: TextStyle(fontSize: 20, color: tier.color),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}