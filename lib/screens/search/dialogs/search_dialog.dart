import 'package:flutter/material.dart';

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
        title: const Text(
          'Message Requests',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
              child: const Text(
                'Requests',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Spam',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'MESSAGE REQUESTS — 2',
              style: TextStyle(color: Color(0xFF72767D), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          _buildRequestTile('cameron_cancer99', 'cam1999', '>30d ago', 'https://discord.gg/ZNPGJ3eZ'),
          _buildRequestTile('🎀Sofiya Yuki🎀', 'sofiya_...', 'June 9, 2023', 'Message contains a sticker:'),
        ],
      ),
    );
  }

  Widget _buildRequestTile(String name, String username, String time, String message) {
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
            child: Text(
              name[0],
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
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      username,
                      style: const TextStyle(color: Color(0xFF72767D), fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(color: Color(0xFF72767D), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFFB9BBBE), fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onRequestHandled(true),
            icon: const Icon(Icons.check, color: Color(0xFF3BA55C)),
          ),
          IconButton(
            onPressed: () => onRequestHandled(false),
            icon: const Icon(Icons.close, color: Color(0xFFED4245)),
          ),
        ],
      ),
    );
  }
}
