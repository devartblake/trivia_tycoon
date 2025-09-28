import 'package:flutter/material.dart';

class CreateDMDialog extends StatefulWidget {
  const CreateDMDialog({super.key});

  @override
  State<CreateDMDialog> createState() => _CreateDMDialogState();
}

class _CreateDMDialogState extends State<CreateDMDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUsers = [];
  final List<Map<String, String>> _allUsers = [
    {'name': 'CavemanYeti', 'username': 'cavemanyeti'},
    {'name': 'EVOJAY27', 'username': 'evejay27'},
    {'name': 'javien', 'username': 'javien'},
    {'name': 'Just1KillPlz', 'username': '_callmejay_'},
    {'name': 'MAK XVI', 'username': 'yaboinsf'},
  ];
  List<Map<String, String>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _allUsers;
    _searchController.addListener(() {
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          final name = user['name']!.toLowerCase();
          final username = user['username']!.toLowerCase();
          final query = _searchController.text.toLowerCase();
          return name.contains(query) || username.contains(query);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildQuickActions(),
          _buildSuggestedSection(),
          _buildUsersList(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Text(
            'To: ',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search your friends',
                hintStyle: TextStyle(color: Color(0xFF72767D)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.group_add, color: Colors.white, size: 20),
            ),
            title: const Text(
              'New Group',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {},
          ),
          const Divider(color: Color(0xFF36393F), height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
            title: const Text(
              'Add a Friend',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF40444B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF5865F2),
                  child: Text('C', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CavemanYeti',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'cavemanyeti',
                        style: TextStyle(color: Color(0xFF72767D), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Group users by first letter
    final groupedUsers = <String, List<Map<String, String>>>{};
    for (final user in _filteredUsers) {
      final firstLetter = user['name']![0].toUpperCase();
      groupedUsers.putIfAbsent(firstLetter, () => []).add(user);
    }

    return Expanded(
      child: ListView.builder(
        itemCount: groupedUsers.length,
        itemBuilder: (context, index) {
          final letter = groupedUsers.keys.elementAt(index);
          final users = groupedUsers[letter]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  letter,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              ...users.map((user) => _buildUserTile(user)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(Map<String, String> user) {
    final name = user['name']!;
    final username = user['username']!;
    final isSelected = _selectedUsers.contains(name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5865F2),
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(username, style: const TextStyle(color: Color(0xFF72767D))),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF3BA55C))
            : null,
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUsers.remove(name);
            } else {
              _selectedUsers.add(name);
            }
          });
        },
      ),
    );
  }
}
