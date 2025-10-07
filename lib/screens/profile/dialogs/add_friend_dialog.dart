import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/input_validator.dart';
import '../../../core/utils/unicode_utils.dart';
import '../../messages/widgets/safe_text.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final List<FriendRequest> _friendRequests = [
    FriendRequest(name: 'StarZone', username: 'clergyman0038', avatar: ''),
    FriendRequest(name: 'Sofiya Yuki', username: 'sofiya_yuki1', avatar: ''),
    FriendRequest(name: 'Annie', username: 'ruby0o0', tag: '🍑 TOF', avatar: ''),
    FriendRequest(name: 'cameron_cancer99', username: 'cam1999', tag: '🟢 NFE', avatar: ''),
    FriendRequest(name: 'Eleanor', username: 'eleanor1k', avatar: ''),
    FriendRequest(name: 'EvelynRadiance', username: 'evelynradiance', tag: '💎 Game', avatar: ''),
    FriendRequest(name: 'Sollow', username: 'wall83939', avatar: ''),
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
        title: const SafeText(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildShareButton(Icons.share, 'Share Invite', Colors.grey),
            const SizedBox(width: 8),
            _buildShareButton(Icons.link, 'Copy Link', Colors.grey),
            const SizedBox(width: 8),
            _buildShareButton(Icons.qr_code, 'QR Code', Colors.grey),
            const SizedBox(width: 8),
            _buildShareButton(Icons.message, 'Messages', Colors.green),
            const SizedBox(width: 8),
            _buildShareButton(Icons.email, 'Email', Colors.blue),
            const SizedBox(width: 8),
            _buildShareButton(Icons.facebook, 'Messenger', Colors.blue),
            const SizedBox(width: 8),
            _buildShareButton(Icons.mail, 'Gmail', Colors.red),
          ],
        ),
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
        SizedBox(
          width: 60,
          child: SafeText(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
            title: const SafeText(
              'Find Your Friends',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {},
          ),
          const Divider(color: Color(0xFF36393F), height: 1),
          ListTile(
            leading: const Icon(Icons.alternate_email, color: Colors.white70, size: 24),
            title: const SafeText(
              'Add by Username',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.pop(context);
              context.push('/friends/add-username');
            },
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
            child: SafeText(
              'Incoming Friend Requests',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _friendRequests.length,
              itemBuilder: (context, index) {
                final request = _friendRequests[index];
                return _buildFriendRequestTile(request, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestTile(FriendRequest request, int index) {
    // Get safe avatar character using UnicodeUtils
    final avatarChar = request.safeAvatarChar;

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
            child: SafeText(
              avatarChar,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and tag row with proper overflow handling
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    SafeText(
                      request.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (request.tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3BA55C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SafeText(
                          request.tag!,
                          style: const TextStyle(color: Color(0xFF3BA55C), fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                SafeText(
                  request.username,
                  style: const TextStyle(color: Color(0xFFB9BBBE), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _declineRequest(index),
                icon: const Icon(Icons.close, color: Color(0xFF72767D)),
                tooltip: 'Decline request',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                onPressed: () => _acceptRequest(index),
                icon: const Icon(Icons.check, color: Color(0xFF3BA55C)),
                tooltip: 'Accept request',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptRequest(int index) {
    if (index >= 0 && index < _friendRequests.length) {
      setState(() {
        _friendRequests.removeAt(index);
      });

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SafeText('Friend request accepted!'),
          backgroundColor: Color(0xFF3BA55C),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _declineRequest(int index) {
    if (index >= 0 && index < _friendRequests.length) {
      setState(() {
        _friendRequests.removeAt(index);
      });

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SafeText('Friend request declined'),
          backgroundColor: Color(0xFF72767D),
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  // Safe avatar character getter using UnicodeUtils
  String get safeAvatarChar {
    final safeName = UnicodeUtils.sanitizeString(_name);
    if (safeName.isEmpty) return '?';

    final firstChar = safeName.substring(0, 1).toUpperCase();
    return UnicodeUtils.sanitizeString(firstChar).isNotEmpty
        ? UnicodeUtils.sanitizeString(firstChar)
        : '?';
  }
}
