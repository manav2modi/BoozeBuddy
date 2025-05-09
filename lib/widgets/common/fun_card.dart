// lib/widgets/common/fun_card.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/theme.dart';

class FunCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double tiltAngle;
  final EdgeInsets padding;
  final double elevation;
  final VoidCallback? onTap;
  final bool hasShadow;

  const FunCard({
    Key? key,
    required this.child,
    this.color,
    this.tiltAngle = 0.01, // Subtle default tilt
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
    this.onTap,
    this.hasShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a random but consistent tilt direction between -1 and 1
    final randomSeed = (child.hashCode % 100) / 100;
    final tiltDirection = (randomSeed - 0.5) * 2; // Range between -1 and 1
    final actualTilt = tiltDirection * tiltAngle;

    return Transform.rotate(
      angle: actualTilt, // Very subtle tilt
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: color ?? AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dividerColor,
              width: 1,
            ),
            boxShadow: hasShadow ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: elevation * 4,
                offset: Offset(0, elevation),
              )
            ] : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Specialized version for drink cards that includes a colored left border
class DrinkFunCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DrinkFunCard({
    Key? key,
    required this.child,
    required this.accentColor,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate a random angle for tilt effect, but keep it consistent for the same card
    final randomSeed = (child.hashCode % 100) / 100;
    final tiltDirection = (randomSeed - 0.5) * 2; // Range between -1 and 1
    final tiltAngle = tiltDirection * 0.015; // Very subtle tilt

    return Transform.rotate(
      angle: tiltAngle,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dividerColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11), // Just inside the outer border
              border: Border(
                left: BorderSide(
                  color: accentColor,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}