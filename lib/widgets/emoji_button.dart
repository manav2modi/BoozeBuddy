// lib/widgets/emoji_button.dart
import 'package:flutter/cupertino.dart';
import '../models/drink.dart';

class EmojiButton extends StatelessWidget {
  final DrinkType type;
  final bool isSelected;
  final VoidCallback onPressed;

  const EmojiButton({
    required this.type,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemGrey5,
        ),
        child: Text("", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}