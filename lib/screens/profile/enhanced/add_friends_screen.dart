import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../core/services/social/friend_discovery_service.dart';
import '../../../game/providers/profile_providers.dart' hide currentUserIdProvider;
import '../../../game/providers/message_providers.dart';
import '../../messages/dialogs/create_dm_dialog.dart' show friendDiscoveryServiceProvider;

class AddFriendByUsernameScreen extends ConsumerStatefulWidget {
  const AddFriendByUsernameScreen({super.key});

  @override
  ConsumerState<AddFriendByUsernameScreen> createState() =>
      _AddFriendByUsernameScreenState();
}

class _AddFriendByUsernameScreenState
    extends ConsumerState<AddFriendByUsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSending = false;
  String? _resultMessage;
  bool _isSuccess = false;

  String get _currentUserId => ref.read(currentUserIdProvider);
  String get _currentUsername {
    if (Hive.isBoxOpen('settings')) {
      final name = Hive.box('settings').get('username') as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    return 'guest';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  String _normalizeHandle(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('@')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  String _userHandle(Map<String, dynamic> user) {
    return _normalizeHandle(
      user['handle']?.toString() ??
          user['username']?.toString() ??
          user['userName']?.toString() ??
          '',
    );
  }

  String _userDisplayName(Map<String, dynamic> user) {
    return user['displayName']?.toString() ??
        user['name']?.toString() ??
        _userHandle(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202225),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add by Username',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Who would you like to add as a friend?',
                style: TextStyle(
                  color: Color(0xFFB9BBBE),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildUsernameInput(),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF72767D),
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'By the way, your username is '),
                    TextSpan(
                      text: _currentUsername,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              if (_resultMessage != null) ...[
                const SizedBox(height: 24),
                _buildResultMessage(),
              ],
              const SizedBox(height: 32),
              _buildSendButton(),
              const SizedBox(height: 32),
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202225),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _resultMessage != null
              ? (_isSuccess ? const Color(0xFF3BA55C) : const Color(0xFFED4245))
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _usernameController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'Enter a username',
          hintStyle: TextStyle(color: Color(0xFF72767D)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) {
          if (_resultMessage != null) {
            setState(() {
              _resultMessage = null;
            });
          }
        },
        onSubmitted: (_) => _sendFriendRequest(),
      ),
    );
  }

  Widget _buildResultMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSuccess
            ? const Color(0xFF3BA55C).withValues(alpha: 0.1)
            : const Color(0xFFED4245).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isSuccess ? const Color(0xFF3BA55C) : const Color(0xFFED4245),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.error,
            color: _isSuccess ? const Color(0xFF3BA55C) : const Color(0xFFED4245),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _resultMessage!,
              style: TextStyle(
                color: _isSuccess ? const Color(0xFF3BA55C) : const Color(0xFFED4245),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendFriendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5865F2),
          disabledBackgroundColor: const Color(0xFF5865F2).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isSending
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Send Friend Request',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3136),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFFAA61A),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Usernames are case-sensitive'),
          _buildTipItem('Make sure to type the exact username'),
          _buildTipItem('You can find friend suggestions in the Friends tab'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.fiber_manual_record,
              color: Color(0xFF72767D),
              size: 8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB9BBBE),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    final username = _normalizeHandle(_usernameController.text);

    if (username.isEmpty) {
      setState(() {
        _resultMessage = 'Please enter a username';
        _isSuccess = false;
      });
      return;
    }

    if (username == _currentUsername) {
      setState(() {
        _resultMessage = "You can't send a friend request to yourself";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _resultMessage = null;
    });

    try {
      final backendProfileService =
          ref.read(backendProfileSocialServiceProvider);
      final friendService = ref.read(friendDiscoveryServiceProvider);

      final users = await backendProfileService.searchUsers(username);
      final targetUser = users.firstWhere(
        (user) => _userHandle(user).toLowerCase() == username.toLowerCase(),
        orElse: () => const <String, dynamic>{},
      );

      if (targetUser.isEmpty) {
        setState(() {
          _resultMessage = "User '$username' not found";
          _isSuccess = false;
          _isSending = false;
        });
        return;
      }

      final targetUserId = targetUser['id']?.toString() ??
          targetUser['userId']?.toString() ??
          '';
      final targetDisplayName = _userDisplayName(targetUser);

      if (targetUserId.isEmpty) {
        setState(() {
          _resultMessage = 'User search returned an invalid record';
          _isSuccess = false;
          _isSending = false;
        });
        return;
      }

      // Check friendship status
      final status =
          friendService.getFriendshipStatus(_currentUserId, targetUserId);

      switch (status) {
        case FriendshipStatus.friends:
          setState(() {
            _resultMessage = 'You are already friends with $targetDisplayName';
            _isSuccess = false;
            _isSending = false;
          });
          return;

        case FriendshipStatus.requestSent:
          setState(() {
            _resultMessage =
                'Friend request already sent to $targetDisplayName';
            _isSuccess = false;
            _isSending = false;
          });
          return;

        case FriendshipStatus.requestReceived:
          setState(() {
            _resultMessage =
                '$targetDisplayName already sent you a friend request. Check your pending requests!';
            _isSuccess = false;
            _isSending = false;
          });
          return;

        case FriendshipStatus.blocked:
          setState(() {
            _resultMessage = 'Unable to send friend request';
            _isSuccess = false;
            _isSending = false;
          });
          return;

        case FriendshipStatus.notFriends:
        // Send friend request
          final success = await friendService.sendFriendRequest(
            senderId: _currentUserId,
            senderName: _currentUsername,
            recipientId: targetUserId,
          );

          if (success) {
            setState(() {
              _resultMessage = 'Friend request sent to $targetDisplayName!';
              _isSuccess = true;
              _isSending = false;
            });
            _usernameController.clear();
          } else {
            setState(() {
              _resultMessage = 'Failed to send friend request';
              _isSuccess = false;
              _isSending = false;
            });
          }
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'An error occurred. Please try again.';
        _isSuccess = false;
        _isSending = false;
      });
    }
  }
}
