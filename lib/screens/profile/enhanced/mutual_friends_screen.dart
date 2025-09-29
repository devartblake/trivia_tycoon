import 'package:flutter/material.dart';

class MutualFriendsScreen extends StatelessWidget {
  final String userId;
  final String currentUserId;

  const MutualFriendsScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final mutualFriends = _generateMutualFriends();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Friends'),
      ),
      body: mutualFriends.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No mutual friends yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mutualFriends.length,
        itemBuilder: (context, index) {
          final friend = mutualFriends[index];
          return _buildFriendTile(context, friend);
        },
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, Map<String, dynamic> friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            friend['name'][0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          friend['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          friend['mutualCount'] > 0
              ? '${friend['mutualCount']} mutual friends'
              : 'No mutual friends',
        ),
        trailing: OutlinedButton(
          onPressed: () {
            // View profile
          },
          child: const Text('View'),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateMutualFriends() {
    return [
      {'id': '1', 'name': 'Sarah Chen', 'mutualCount': 5},
      {'id': '2', 'name': 'Mike Johnson', 'mutualCount': 8},
      {'id': '3', 'name': 'Emma Davis', 'mutualCount': 3},
      {'id': '4', 'name': 'James Wilson', 'mutualCount': 12},
      {'id': '5', 'name': 'Lisa Anderson', 'mutualCount': 7},
      {'id': '6', 'name': 'David Brown', 'mutualCount': 4},
      {'id': '7', 'name': 'Sophie Taylor', 'mutualCount': 9},
      {'id': '8', 'name': 'Ryan Martinez', 'mutualCount': 6},
    ];
  }
}
