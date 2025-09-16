import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'daily_quiz_widget.dart';
import 'monthly_quiz_widget.dart';

class CarouselSection extends StatefulWidget {
  const CarouselSection({super.key});

  @override
  State<CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<CarouselSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Auto-advance carousel every 5 seconds
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % 3; // Changed to 3 pages
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoAdvance();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Daily Quiz Widget
              const DailyQuizWidget(),

              // Monthly Quiz Widget
              const MonthlyQuizWidget(),

              // Featured Challenge Widget
              const FeaturedChallengeWidget(),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) { // Changed to 3 indicators
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 20 : 8,
              height: 10, // Made consistent with your code
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Colors.purple
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Featured Challenge Widget
class FeaturedChallengeWidget extends StatelessWidget {
  const FeaturedChallengeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center the content
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.yellow.shade300,
                      size: 18, // Slightly smaller
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Featured Challenge",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15, // Slightly smaller
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  "Science Masters Quiz",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13, // Slightly smaller
                  ),
                ),
                const SizedBox(height: 6), // Reduced spacing
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "2x XP Bonus",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11, // Slightly smaller
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Reduced spacing
                ElevatedButton(
                  onPressed: () {
                    context.push('/featured-challenge');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
                    minimumSize: const Size(0, 32), // Set minimum height
                  ),
                  child: const Text(
                    "Accept Challenge",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11, // Slightly smaller
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // Add some space between content and icon
          Stack(
            children: [
              Container(
                width: 70, // Slightly smaller
                height: 70, // Slightly smaller
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 35, // Slightly smaller
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3), // Slightly smaller
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.indigo.shade600,
                    size: 14, // Slightly smaller
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
