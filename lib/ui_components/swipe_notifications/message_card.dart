import 'package:flutter/material.dart';
import 'demo_data.dart';
import '../../screens/app_shell/app_shell.dart';
import '../../ui_components/swipe_notifications/swipe_item.dart';

// Content for the list items.
class EmailCard extends StatelessWidget {
  final Email email;
  final Color backgroundColor;

  const EmailCard({
    super.key, 
    required this.email, 
    this.backgroundColor = const Color(0xfff5f5f5),
  });

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    // Extract initials from the user's name
    String getInitials(String name) {
      List<String> names = name.split(' ');
      String initials = names.isNotEmpty
        ? names.map((name) => name[0]).take(2).join().toUpperCase() : '';
      return initials;
    }

    // Determine if `profileImageUrl` is a local asset or a network image
    ImageProvider getProfileImage(String? profileImageUrl) {
      if (profileImageUrl == null || profileImageUrl.isEmpty) {
        return AssetImage('images/avatars/default-avatar.jpg'); // Default image
      } else if (Uri.tryParse(profileImageUrl)?.hasAbsolutePath ?? false) {
        return NetworkImage(profileImageUrl); // Valid URL
      } else {
        return AssetImage(profileImageUrl); // Local asset image
      }
    }

    return Container(
      width: w + 0.1,
      height: SwipeItem.nominalHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 8.0,
            color: Colors.black.withOpacity(0.1), // Subtle shadow
          ),
        ],
        borderRadius: BorderRadius.circular(10), // Slightly rounded corners
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Circular image near the name
              CircleAvatar(
                radius: 18, // Adjust size as needed
                backgroundColor: Colors.grey[300], // Fallback color
                foregroundImage: getProfileImage(email.profileImageUrl),
                onForegroundImageError: (exception, stackTrace) {
                  debugPrint("Image load error: $exception");
                },
                child: email.profileImageUrl == null
                    ? Text(
                        getInitials(email.from),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      )
                    : null, // Show initials if no image is available
              ),
              const SizedBox(width: 10.0), // Space between image and text
              Expanded(
                child: Text(
                  email.from,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                    package: AppShell.pkg,
                  ),
                ),
              ),
              // Dynamic time display
              Text(
                email.time, // Assuming `email.time` holds the dynamic time string
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.3,
                  package: AppShell.pkg,
                  color: Colors.grey[200], // Subtle grey color
                ),
              ),
            ],
          ),
          const SizedBox(height: 5.0), // Spacing between rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                email.subject,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.3,
                  package: AppShell.pkg,
                  color: Colors.grey[500],
                ),
              ),
              if (email.isFavorite)
                const Icon(
                  Icons.star,
                  size: 18.0,
                  color: Color(0xff55c8d4),
                ),
            ],
          ),
          const SizedBox(height: 2.0), // Spacing before email body
          Text(
            email.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.3,
              color: const Color(0xff9293bf),
              package: AppShell.pkg,
            ),
          ),
        ],
      ),
    );
  }
}
