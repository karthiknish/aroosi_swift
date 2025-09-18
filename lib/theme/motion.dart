import 'package:flutter/animation.dart';

/// Shared animation timings used across the app.
class AppMotionDurations {
  AppMotionDurations._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration page = Duration(milliseconds: 320);
  static const Duration bounce = Duration(milliseconds: 420);
  static const Duration long = Duration(milliseconds: 600);
  static const Duration loop = Duration(milliseconds: 1200);
}

/// Common easing curves to keep motion feeling consistent.
class AppMotionCurves {
  AppMotionCurves._();

  static const Curve ease = Curves.ease;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;
  static const Curve spring = Cubic(0.68, -0.55, 0.27, 1.55);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve fadeThroughEnter = Cubic(0.35, 0.0, 0.25, 1.0);
  static const Curve fadeThroughExit = Cubic(0.4, 0.0, 1.0, 1.0);
  static const Curve sharedAxisForward = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve sharedAxisReverse = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Helpful extension for quickly chaining tweens with named curves.
extension MotionAnimationControllerX on AnimationController {
  Animation<double> driveCurve({
    double begin = 0,
    double end = 1,
    Curve curve = AppMotionCurves.easeOut,
    Curve? reverseCurve,
  }) {
    final curved = CurvedAnimation(
      parent: this,
      curve: curve,
      reverseCurve: reverseCurve,
    );
    return Tween<double>(begin: begin, end: end).animate(curved);
  }
}
