import 'package:flutter/material.dart';

class OnboardingAvatarStep extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onUserDataChanged;
  final VoidCallback onComplete;

  const OnboardingAvatarStep({
    super.key,
    required this.onUserDataChanged,
    required this.onComplete,
  });

  @override
  State<OnboardingAvatarStep> createState() => _OnboardingAvatarStepState();
}

class _OnboardingAvatarStepState extends State<OnboardingAvatarStep> {
  String? _selectedAvatar;

  final List<String> avatars = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
    'assets/avatars/avatar7.png',
    'assets/avatars/avatar8.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.greenAccent.shade100,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text("Pick an Avatar",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage(avatar),
                    radius: 30,
                    foregroundColor: _selectedAvatar == avatar
                        ? Colors.blueAccent
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selectedAvatar != null) {
                widget.onUserDataChanged({'avatar': _selectedAvatar});
                widget.onComplete();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select an avatar.")),
                );
              }
            },
            child: const Text("Finish"),
          )
        ],
      ),
    );
  }
}
