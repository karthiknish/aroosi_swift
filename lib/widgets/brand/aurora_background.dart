import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:aroosi_flutter/theme/colors.dart';

/// Decorative background used across primary surfaces to give Aroosi a
/// distinctive "aurora" identity. It renders a layered gradient canvas with
/// softly blurred blobs and hand-drawn arcs so that screens immediately feel
/// bespoke compared with boilerplate dating layouts.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.enableTexture = false,
  });

  /// The foreground content to paint on top of the aurora canvas.
  final Widget child;

  /// When true, paints additional dot textures for hero screens (used sparingly).
  final bool enableTexture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.auroraBackground, Colors.white],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _GradientHalo(
            alignment: Alignment(-1.0, -0.9),
            size: 340,
            colors: [AppColors.auroraRose, Colors.transparent],
          ),
          const _GradientHalo(
            alignment: Alignment(0.9, -0.6),
            size: 280,
            colors: [AppColors.auroraIris, Colors.transparent],
          ),
          const _GradientHalo(
            alignment: Alignment(-0.4, 0.95),
            size: 360,
            colors: [AppColors.auroraSunset, Colors.transparent],
          ),
          const _GradientHalo(
            alignment: Alignment(0.7, 0.8),
            size: 220,
            colors: [AppColors.auroraSky, Colors.transparent],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ArcStripesPainter(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          if (enableTexture)
            const Positioned.fill(child: IgnorePointer(child: _DotTexture())),
          child,
        ],
      ),
    );
  }
}

class _GradientHalo extends StatelessWidget {
  const _GradientHalo({
    required this.alignment,
    required this.size,
    required this.colors,
  });

  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: pi / 12,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: size * 0.12,
            sigmaY: size * 0.12,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: colors,
                stops: const [0.0, 0.65],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcStripesPainter extends CustomPainter {
  const _ArcStripesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color,
        color.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    Path makePath(double startY, double controlDy) {
      final path = Path();
      path.moveTo(-40, size.height * startY);
      path.quadraticBezierTo(
        size.width * 0.4,
        size.height * controlDy,
        size.width + 40,
        size.height * (startY + 0.18),
      );
      return path;
    }

    final paths = <Path>[
      makePath(0.25, 0.05),
      makePath(0.45, 0.28),
      makePath(0.65, 0.48),
    ];

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotTexture extends StatelessWidget {
  const _DotTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotTexturePainter(
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
    );
  }
}

class _DotTexturePainter extends CustomPainter {
  const _DotTexturePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 42.0;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        final radius = 1.4 + ((x + y) % spacing) / spacing;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
