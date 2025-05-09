import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'gradient_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String emoji;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool isAnimated;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.emoji,
    required this.buttonText,
    required this.onButtonPressed,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isAnimated)
            _buildAnimatedEmoji()
          else
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 72,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GradientButton(
              text: buttonText,
              onPressed: onButtonPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedEmoji() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),  // Subtle pulse between 0.8 and 1.0
          child: Transform.rotate(
            angle: (value - 0.5) * 0.1, // Subtle tilt
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 72,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Specialized versions for common empty states
class NoDrinksEmptyState extends StatelessWidget {
  final DateTime date;
  final VoidCallback onAddDrink;

  const NoDrinksEmptyState({
    Key? key,
    required this.date,
    required this.onAddDrink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return EmptyState(
      emoji: '🍹',
      title: isToday
          ? "No drinks logged today"
          : "No drinks logged for this day",
      message: isToday
          ? "Staying sober or just getting started? Add your first drink when you're ready."
          : "Looks like you didn't log any drinks for this day. Either a sober day or you forgot to log?",
      buttonText: "Add Your First Drink",
      onButtonPressed: onAddDrink,
    );
  }
}

class NoStatsEmptyState extends StatelessWidget {
  final VoidCallback onStartTracking;

  const NoStatsEmptyState({
    Key? key,
    required this.onStartTracking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '📊',
      title: "No stats to show yet",
      message: "Start tracking your drinks to see interesting patterns and insights about your habits.",
      buttonText: "Start Tracking",
      onButtonPressed: onStartTracking,
    );
  }
}

class NoCustomDrinksEmptyState extends StatelessWidget {
  final VoidCallback onCreateDrink;

  const NoCustomDrinksEmptyState({
    Key? key,
    required this.onCreateDrink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '🧪',
      title: "No custom drinks yet",
      message: "Create your favorite custom drinks to track them more easily and accurately.",
      buttonText: "Create Custom Drink",
      onButtonPressed: onCreateDrink,
    );
  }
}