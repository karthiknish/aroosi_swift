import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:aroosi_flutter/theme/motion.dart';

/// Lightweight shimmer effect using a moving linear gradient applied via ShaderMask.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = AppMotionDurations.loop,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final width = rect.width;
            final dx = (width * 2) * _controller.value - width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: GradientTranslation(dx, 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class GradientTranslation extends GradientTransform {
  const GradientTranslation(this.dx, this.dy);
  final double dx;
  final double dy;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final m = Matrix4.identity();
    m.translateByVector3(vm.Vector3(dx, dy, 0));
    return m;
  }
}
