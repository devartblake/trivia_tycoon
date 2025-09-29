import 'package:flutter/material.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36393F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF202225),
            borderRadius: BorderRadius.circular(18),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: Color(0xFF72767D)),
              prefixIcon: Icon(Icons.search, color: Color(0xFF72767D), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF36393F),
      child: TabBar(
        controller: _tabController,
        tabAlignment: TabAlignment.start,
        isScrollable: true,
        indicatorColor: const Color(0xFF5865F2),
        indicatorWeight: 2,
        labelColor: const Color(0xFF5865F2),
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Recent'),
          Tab(text: 'People'),
          Tab(text: 'Media'),
          Tab(text: 'Pins'),
          Tab(text: 'Links'),
          Tab(text: 'Files'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRecentTab(),
        _buildPeopleTab(),
        _buildMediaTab(),
        _buildPinsTab(),
        _buildLinksTab(),
        _buildFilesTab(),
      ],
    );
  }

  Widget _buildRecentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF5865F2),
              child: Text('C', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('CavemanYeti', style: TextStyle(color: Colors.white)),
            subtitle: const Text('cavemanyeti', style: TextStyle(color: Color(0xFF72767D))),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photos & Media',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View all',
                  style: TextStyle(color: Color(0xFF5865F2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMediaGrid(),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF40444B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.image, color: Colors.white70, size: 40),
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.white70, size: 64),
          SizedBox(height: 16),
          Text(
            'No people found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            'Try searching for a different name',
            style: TextStyle(color: Color(0xFF72767D), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, color: Colors.white70, size: 64),
          SizedBox(height: 16),
          Text(
            'No media found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            'Photos and videos will appear here',
            style: TextStyle(color: Color(0xFF72767D), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPinsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.push_pin_outlined, color: Colors.white70, size: 64),
          SizedBox(height: 16),
          Text(
            'No pinned messages',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            'Pinned messages will appear here',
            style: TextStyle(color: Color(0xFF72767D), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link, color: Colors.white70, size: 64),
          SizedBox(height: 16),
          Text(
            'No links found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            'Shared links will appear here',
            style: TextStyle(color: Color(0xFF72767D), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, color: Colors.white70, size: 64),
          SizedBox(height: 16),
          Text(
            'No files found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            'Shared files will appear here',
            style: TextStyle(color: Color(0xFF72767D), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
