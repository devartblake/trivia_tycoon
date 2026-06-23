import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../layout/synaptix_panel.dart';

class FriendsOnlineCard extends StatelessWidget {
  final List<SynaptixFriendPreview> friends;

  const FriendsOnlineCard({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'FRIENDS ONLINE (${friends.length})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final friend in friends.take(5))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: friend.color.withValues(alpha: 0.8),
                child: Text(
                  friend.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
