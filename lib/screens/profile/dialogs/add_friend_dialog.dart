import 'package:flutter/material.dart';

import '../../../core/utils/input_validator.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final List<FriendRequest> _friendRequests = [
    FriendRequest(name: '☆StarZone☆', username: 'clergyman0038', avatar: ''),
    FriendRequest(name: '🎀Sofiya Yuki🎀', username: 'sofiya_yuki1', avatar: ''),
    FriendRequest(name: 'Annie', username: 'ruby0o0', tag: '🍑 TOF', avatar: ''),
    FriendRequest(name: 'cameron_cancer99', username: 'cam1999', tag: '🟢 NFE', avatar: ''),
    FriendRequest(name: 'Eleanor', username: 'eleanor1k', avatar: ''),
    FriendRequest(name: 'EvelynRadiance', username: 'evelynradiance', tag: '💎 永劫无间', avatar: ''),
    FriendRequest(name: 'Ѕσllσωֆ', username: 'wall83939', avatar: ''),
    FriendRequest(name: 'Ingrid', username: 'ingrid_4khhg', avatar: ''),
    FriendRequest(name: 'Jaxter', username: 'jaxterdb0985', avatar: ''),
  ];

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
        title: const Text(
          'Add Friends',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildShareOptions(),
          _buildQuickActions(),
          _buildIncomingRequests(),
        ],
      ),
    );
  }

  Widget _buildShareOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildShareButton(Icons.share, 'Share Invite', Colors.grey),
          _buildShareButton(Icons.link, 'Copy Link', Colors.grey),
          _buildShareButton(Icons.qr_code, 'QR Code', Colors.grey),
          _buildShareButton(Icons.message, 'Messages', Colors.green),
          _buildShareButton(Icons.email, 'Email', Colors.blue),
          _buildShareButton(Icons.facebook, 'Messenger', Colors.blue),
          _buildShareButton(Icons.mail, 'Gmail', Colors.red),
        ],
      ),
    );
  }

  Widget _buildShareButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
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
              child: const Icon(Icons.people, color: Colors.white, size: 20),
            ),
            title: const Text(
              'Find Your Friends',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {},
          ),
          const Divider(color: Color(0xFF36393F), height: 1),
          ListTile(
            leading: const Icon(Icons.alternate_email, color: Colors.white70, size: 24),
            title: const Text(
              'Add by Username',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequests() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Incoming Friend Requests',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _friendRequests.length,
              itemBuilder: (context, index) {
                final request = _friendRequests[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF40444B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF5865F2),
                        child: Text(
                          request.name[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    request.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (request.tag != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    request.tag!,
                                    style: const TextStyle(color: Color(0xFF3BA55C), fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              request.username,
                              style: const TextStyle(color: Color(0xFFB9BBBE), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _declineRequest(index),
                        icon: const Icon(Icons.close, color: Color(0xFF72767D)),
                      ),
                      IconButton(
                        onPressed: () => _acceptRequest(index),
                        icon: const Icon(Icons.check, color: Color(0xFF3BA55C)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(int index) {
    setState(() {
      _friendRequests.removeAt(index);
    });
  }

  void _declineRequest(int index) {
    setState(() {
      _friendRequests.removeAt(index);
    });
  }
}

class FriendRequest {
  final String _name;
  final String _username;
  final String avatar;
  final String? _tag;

  FriendRequest({
    required String name,
    required String username,
    required this.avatar,
    String? tag,
  }) : _name = InputValidator.safeString(name),
        _username = InputValidator.safeString(username),
        _tag = tag != null ? InputValidator.safeString(tag) : null;

  String get name => _name;
  String get username => _username;
  String? get tag => _tag;
}
