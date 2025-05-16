// Create a new file: lib/widgets/common/confetti_overlay.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class ConfettiOverlay extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const ConfettiOverlay({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Create confetti pieces
    for (int i = 0; i < 50; i++) {
      _confetti.add(_ConfettiPiece(
        color: _getRandomColor(),
        position: _getRandomPosition(),
        size: _random.nextDouble() * 10 + 5,
        rotation: _random.nextDouble() * pi,
      ));
    }

    // Start animation
    _controller.forward().then((_) {
      // Wait a bit before calling onAnimationComplete
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onAnimationComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRandomColor() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.blue,
      Colors.green,
      Colors.pink,
      Colors.orange,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Offset _getRandomPosition() {
    return Offset(
      _random.nextDouble() * 400 - 200,
      _random.nextDouble() * -300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            confetti: _confetti,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ConfettiPiece {
  final Color color;
  final Offset position;
  final double size;
  final double rotation;

  _ConfettiPiece({
    required this.color,
    required this.position,
    required this.size,
    required this.rotation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> confetti;
  final double progress;

  _ConfettiPainter({
    required this.confetti,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final piece in confetti) {
      final paint = Paint()..color = piece.color;

      // Calculate current position based on animation progress
      final currentPos = Offset(
        center.dx + piece.position.dx,
        center.dy + piece.position.dy + 500 * progress * progress,
      );

      // Apply rotation
      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(piece.rotation + progress * 2 * pi);

      // Draw the confetti piece (a small rectangle)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}