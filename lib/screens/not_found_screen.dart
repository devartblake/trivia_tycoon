import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This assumes your app's theme provides a dark background.
    // If not, wrap the Center widget with a Scaffold and set its backgroundColor.
    return Scaffold(
      backgroundColor: Colors.black, // Explicitly setting background color
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Makes app bar blend with body
        elevation: 0,
        title: const Text(
          'Trivia Tycoon',
          style: TextStyle(
            fontFamily: 'Montserrat', // Example font, adjust as needed
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        // If you want a back button to appear automatically when navigated to.
        // By default, it will show if there's a previous route in the stack.
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PAGE NOT FOUND',
                style: TextStyle(
                  color: Color(0xFFC7B16A), // Gold-like color
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Shimmer.fromColors(
                baseColor: Colors.grey[700]!, // Darker grey for base
                highlightColor: Colors.white, // Lighter for shimmer effect
                child: const Text(
                  '404',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w300, // Very thin font weight
                    fontFamily: 'Montserrat', // Adjust font as needed
                    color: Colors.white, // This color is overwritten by shimmer
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'THIS PAGE HAS BEEN MOVED\nOR\nDOESN\'T EXIST.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                  fontFamily: 'Georgia', // Example serif font
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // Navigates back to the home route ('/').
                  // Ensure you have a route named '/' in your GoRouter setup.
                  context.go('/game');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Button background
                  foregroundColor: Colors.black, // Text color
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}