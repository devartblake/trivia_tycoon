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

  final List<Map<String, dynamic>> avatars = [
    {'id': 'person', 'icon': Icons.person, 'color': Colors.blue},
    {'id': 'face', 'icon': Icons.face, 'color': Colors.green},
    {'id': 'account_circle', 'icon': Icons.account_circle, 'color': Colors.orange},
    {'id': 'sentiment_satisfied', 'icon': Icons.sentiment_satisfied, 'color': Colors.purple},
    {'id': 'child_care', 'icon': Icons.child_care, 'color': Colors.red},
    {'id': 'psychology', 'icon': Icons.psychology, 'color': Colors.teal},
    {'id': 'sports_esports', 'icon': Icons.sports_esports, 'color': Colors.indigo},
    {'id': 'school', 'icon': Icons.school, 'color': Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.greenAccent.shade100,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            "Pick an Avatar",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
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
                final isSelected = _selectedAvatar == avatar['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar['id'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.blueAccent, width: 3)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                      color: isSelected
                          ? avatar['color'].withOpacity(0.8)
                          : avatar['color'].withOpacity(0.6),
                    ),
                    child: Icon(
                      avatar['icon'],
                      size: 40,
                      color: Colors.white,
                    ),
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