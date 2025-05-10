// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import './home_screen.dart';
import '../widgets/common/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to BoozeBuddy 🍻',
      'description': 'Your personal drink tracker for health awareness and fun insights.',
      'image': '🥂',
      'hints': [
        'Track your drink consumption',
        'See patterns in your drinking habits',
        'Keep a record of your favorite spots'
      ]
    },
    {
      'title': 'Track Any Drink 🍹',
      'description': 'Beer, wine, cocktails, shots - log any type of drink with customizable details.',
      'image': '🍺',
      'hints': [
        'Set accurate standard drink measures',
        'Add notes and locations',
        'Optional cost tracking'
      ]
    },
    {
      'title': 'Create Custom Drinks 🧪',
      'description': 'Make your own drink types with custom names, emojis, and colors for easy tracking.',
      'image': '🧪',
      'hints': [
        'Perfect for your favorite cocktails',
        'Choose any emoji and color',
        'Personalize your drinking log'
      ]
    },
    {
      'title': 'Explore Your Stats 📊',
      'description': 'Gain valuable insights about your drinking patterns and habits.',
      'image': '📈',
      'hints': [
        'View daily, weekly, and monthly trends',
        'Track spending if enabled',
        'Identify patterns by location and drink type'
      ]
    },
    {
      'title': 'Health & Awareness 💪',
      'description': 'Stay mindful of your alcohol consumption for better health decisions.',
      'image': '❤️',
      'hints': [
        'See your consumption against guidelines',
        'Track sober days automatically',
        'Make informed choices about drinking'
      ]
    }
  ];

  void _completeOnboarding() async {
    // Mark onboarding as completed in preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      // Navigate to home screen and prevent going back
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: CupertinoButton(
                child: const Text('Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onPressed: _completeOnboarding,
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),

            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => _buildPageIndicator(index == _currentPage),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GradientButton(
                text: _currentPage == _pages.length - 1
                    ? "Let's Get Started!"
                    : "Next",
                emoji: _currentPage == _pages.length - 1 ? "🚀" : null,
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _completeOnboarding();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated emoji image
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Text(
                  page['image'],
                  style: const TextStyle(
                    fontSize: 80,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            page['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page['description'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[300],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Feature hints
          ...page['hints'].map<Widget>((hint) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor : Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// To update the main.dart to show the onboarding screen on first launch:

/*
// In main.dart, modify your SipTrackApp class:
*/