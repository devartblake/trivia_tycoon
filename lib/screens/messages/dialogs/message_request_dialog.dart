import 'package:flutter/material.dart';
import '../../../core/utils/input_validator.dart';
import '../../../core/utils/unicode_utils.dart';
import '../../messages/widgets/safe_text.dart';

class MessageRequestDialog extends StatelessWidget {
  final int requestCount;
  final Function(bool) onRequestHandled;

  const MessageRequestDialog({
    super.key,
    required this.requestCount,
    required this.onRequestHandled,
  });

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
        title: const SafeText(
          'Message Requests',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTabs(),
          _buildRequestsList(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SafeText(
                'Requests',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const SafeText(
                'Spam',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    // Clean the section header text using UnicodeUtils
    final sectionHeaderText =
        UnicodeUtils.sanitizeString('MESSAGE REQUESTS — $requestCount');

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeText(
              sectionHeaderText,
              style: const TextStyle(
                  color: Color(0xFF72767D),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildRequestTile('cameron_cancer99', 'cam1999', '>30d ago',
                    'https://discord.gg/ZNPGJ3eZ'),
                _buildRequestTile(
                    'Sofiya Yuki', // Cleaned up the problematic Unicode
                    'sofiya_...',
                    'June 9, 2023',
                    'Message contains a sticker:'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(
      String name, String username, String time, String message) {
    // Sanitize all input strings using UnicodeUtils
    final safeName = InputValidator.safeString(name);
    final safeUsername = InputValidator.safeString(username);
    final safeTime = InputValidator.safeString(time);
    final safeMessage = InputValidator.safeString(message);

    // Get safe first character for avatar
    final avatarChar = safeName.isNotEmpty
        ? UnicodeUtils.sanitizeString(safeName.substring(0, 1)).toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row with proper overflow handling
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    SafeText(
                      safeName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    SafeText(
                      safeUsername,
                      style: const TextStyle(
                          color: Color(0xFF72767D), fontSize: 12),
                    ),
                    SafeText(
                      safeTime,
                      style: const TextStyle(
                          color: Color(0xFF72767D), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SafeText(
                  safeMessage,
                  style:
                      const TextStyle(color: Color(0xFFB9BBBE), fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => onRequestHandled(true),
                icon: const Icon(Icons.check, color: Color(0xFF3BA55C)),
                tooltip: 'Accept request',
              ),
              IconButton(
                onPressed: () => onRequestHandled(false),
                icon: const Icon(Icons.close, color: Color(0xFFED4245)),
                tooltip: 'Decline request',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper class for creating safe message request data
class MessageRequest {
  final String _name;
  final String _username;
  final String _time;
  final String _message;
  final String? _avatarUrl;

  MessageRequest({
    required String name,
    required String username,
    required String time,
    required String message,
    String? avatarUrl,
  })  : _name = InputValidator.safeString(name),
        _username = InputValidator.safeString(username),
        _time = InputValidator.safeString(time),
        _message = InputValidator.safeString(message),
        _avatarUrl =
            avatarUrl != null ? InputValidator.safeString(avatarUrl) : null;

  String get name => _name;
  String get username => _username;
  String get time => _time;
  String get message => _message;
  String? get avatarUrl => _avatarUrl;

  String get safeAvatarChar {
    final safeName = UnicodeUtils.sanitizeString(_name);
    return safeName.isNotEmpty ? safeName.substring(0, 1).toUpperCase() : '?';
  }
}
