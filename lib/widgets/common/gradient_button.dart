// lib/widgets/common/gradient_button.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? emoji;
  final VoidCallback onPressed;
  final bool isLoading;
  final Gradient? customGradient;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isDisabled;

  const GradientButton({
    Key? key,
    required this.text,
    this.icon,
    this.emoji,
    required this.onPressed,
    this.isLoading = false,
    this.customGradient,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient = customGradient ?? AppTheme.boozeBuddyGradient;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDisabled ? Colors.grey.shade700 : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isDisabled || isLoading ? null : onPressed,
          child: Padding(
            padding: padding,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) ...[
                    Text(
                      emoji!,
                      style: const TextStyle(
                        fontSize: 20,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}