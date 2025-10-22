// ignore_for_file: prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aroosi_flutter/theme/motion.dart';

class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = AppMotionDurations.short,
    this.delay = Duration.zero,
    this.curve = AppMotionCurves.easeOut,
    this.onEnd,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final VoidCallback? onEnd;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late Animation<double> _opacity = _controller.driveCurve(curve: widget.curve);
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatus);
    _start();
  }

  @override
  void didUpdateWidget(FadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _opacity = _controller.driveCurve(curve: widget.curve);
    }
    if (oldWidget.delay != widget.delay) {
      _start(restart: true);
    }
  }

  void _start({bool restart = false}) {
    if (restart) {
      _delayTimer?.cancel();
      _controller
        ..reset()
        ..stop();
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onEnd?.call();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = AppMotionDurations.medium,
    this.delay = Duration.zero,
    this.fadeCurve = AppMotionCurves.easeOut,
    this.slideCurve = AppMotionCurves.easeOut,
    this.beginOffset = const Offset(0, 0.12),
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve fadeCurve;
  final Curve slideCurve;
  final Offset beginOffset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late Animation<double> _opacity = _controller.driveCurve(
    curve: widget.fadeCurve,
  );
  late Animation<Offset> _offset = Tween<Offset>(
    begin: widget.beginOffset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.slideCurve));
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(FadeSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.fadeCurve != widget.fadeCurve) {
      _opacity = _controller.driveCurve(curve: widget.fadeCurve);
    }
    if (oldWidget.slideCurve != widget.slideCurve ||
        oldWidget.beginOffset != widget.beginOffset) {
      _offset = Tween<Offset>(
        begin: widget.beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.slideCurve));
    }
    if (oldWidget.delay != widget.delay) {
      _start(restart: true);
    }
  }

  void _start({bool restart = false}) {
    if (restart) {
      _delayTimer?.cancel();
      _controller
        ..reset()
        ..stop();
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class FadeScaleIn extends StatefulWidget {
  const FadeScaleIn({
    super.key,
    required this.child,
    this.duration = AppMotionDurations.medium,
    this.delay = Duration.zero,
    this.fadeCurve = AppMotionCurves.easeOut,
    this.scaleCurve = AppMotionCurves.spring,
    this.beginScale = 0.92,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve fadeCurve;
  final Curve scaleCurve;
  final double beginScale;

  @override
  State<FadeScaleIn> createState() => _FadeScaleInState();
}

class _FadeScaleInState extends State<FadeScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late Animation<double> _opacity = _controller.driveCurve(
    curve: widget.fadeCurve,
  );
  late Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.scaleCurve));
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(FadeScaleIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.fadeCurve != widget.fadeCurve) {
      _opacity = _controller.driveCurve(curve: widget.fadeCurve);
    }
    if (oldWidget.scaleCurve != widget.scaleCurve ||
        oldWidget.beginScale != widget.beginScale) {
      _scale = Tween<double>(
        begin: widget.beginScale,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.scaleCurve));
    }
    if (oldWidget.delay != widget.delay) {
      _start(restart: true);
    }
  }

  void _start({bool restart = false}) {
    if (restart) {
      _delayTimer?.cancel();
      _controller
        ..reset()
        ..stop();
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class MotionPressable extends StatefulWidget {
  const MotionPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.enabled = true,
    this.scaleFactor = 0.96,
    this.duration = AppMotionDurations.fast,
    this.curve = AppMotionCurves.easeOut,
    this.reverseCurve = AppMotionCurves.easeIn,
    this.behavior,
  }) : assert(scaleFactor > 0 && scaleFactor <= 1);

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool enabled;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;
  final Curve reverseCurve;
  final HitTestBehavior? behavior;

  @override
  State<MotionPressable> createState() => _MotionPressableState();
}

class _MotionPressableState extends State<MotionPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _configureAnimation();
  }

  @override
  void didUpdateWidget(MotionPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..reverseDuration = widget.duration;
    }
    if (oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve ||
        oldWidget.scaleFactor != widget.scaleFactor) {
      _configureAnimation();
    }
  }

  void _configureAnimation() {
    _scale = Tween<double>(begin: 1, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      ),
    );
  }

  bool get _canHandlePress =>
      widget.enabled &&
      (widget.onPressed != null || widget.onLongPress != null);

  void _handleTapDown(TapDownDetails details) {
    if (!_canHandlePress) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_canHandlePress) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_canHandlePress) return;
    _controller.reverse();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_canHandlePress) return;
    _controller.forward();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_canHandlePress) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior ?? HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPressStart: widget.onLongPress != null
          ? _handleLongPressStart
          : null,
      onLongPressEnd: widget.onLongPress != null ? _handleLongPressEnd : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class FadeThrough extends StatefulWidget {
  const FadeThrough({
    super.key,
    required this.child,
    this.enterDuration = AppMotionDurations.medium,
    this.exitDuration = AppMotionDurations.short,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration enterDuration;
  final Duration exitDuration;
  final Duration delay;

  @override
  State<FadeThrough> createState() => _FadeThroughState();
}

class _FadeThroughState extends State<FadeThrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.enterDuration,
    reverseDuration: widget.exitDuration,
  );
  late Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppMotionCurves.fadeThroughEnter,
    reverseCurve: AppMotionCurves.fadeThroughExit,
  );
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(FadeThrough oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enterDuration != widget.enterDuration ||
        oldWidget.exitDuration != widget.exitDuration) {
      _controller
        ..duration = widget.enterDuration
        ..reverseDuration = widget.exitDuration;
    }
    if (oldWidget.delay != widget.delay) {
      _start(restart: true);
    }
  }

  void _start({bool restart = false}) {
    if (restart) {
      _delayTimer?.cancel();
      _controller
        ..reset()
        ..stop();
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class SharedAxis extends StatefulWidget {
  const SharedAxis({
    super.key,
    required this.child,
    this.duration = AppMotionDurations.medium,
    this.axis = Axis.horizontal,
    this.reverse = false,
  });

  final Widget child;
  final Duration duration;
  final Axis axis;
  final bool reverse;

  @override
  State<SharedAxis> createState() => _SharedAxisState();
}

class _SharedAxisState extends State<SharedAxis>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
  }

  @override
  void didUpdateWidget(SharedAxis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.axis != widget.axis || oldWidget.reverse != widget.reverse) {
      _configureAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }

  void _configureAnimations() {
    final curve = widget.reverse
        ? AppMotionCurves.sharedAxisReverse
        : AppMotionCurves.sharedAxisForward;
    final reverseCurve = widget.reverse
        ? AppMotionCurves.sharedAxisForward
        : AppMotionCurves.sharedAxisReverse;
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: curve,
      reverseCurve: reverseCurve,
    );
    _offset =
        Tween<Offset>(
          begin: _beginOffsetForAxis(widget.axis, widget.reverse),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        );
  }

  static Offset _beginOffsetForAxis(Axis axis, bool reverse) {
    switch (axis) {
      case Axis.horizontal:
        return Offset(reverse ? -0.2 : 0.2, 0);
      case Axis.vertical:
        return Offset(0, reverse ? -0.2 : 0.2);
    }
  }
}

/// Enhanced bounce animation for success feedback
class BounceIn extends StatefulWidget {
  const BounceIn({
    super.key,
    required this.child,
    this.duration = AppMotionDurations.medium,
    this.delay = Duration.zero,
    this.bounceFactor = 0.1,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double bounceFactor;

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.1),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 0.95),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.02),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0),
        weight: 10.0,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _start();
  }

  @override
  void didUpdateWidget(BounceIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay) {
      _start(restart: true);
    }
  }

  void _start({bool restart = false}) {
    if (restart) {
      _delayTimer?.cancel();
      _controller.reset();
    }

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Smooth slide transition for content changes
class SmoothSlideTransition extends StatefulWidget {
  const SmoothSlideTransition({
    super.key,
    required this.child,
    this.duration = AppMotionDurations.medium,
    this.slideDirection = AxisDirection.left,
    this.fade = true,
  });

  final Widget child;
  final Duration duration;
  final AxisDirection slideDirection;
  final bool fade;

  @override
  State<SmoothSlideTransition> createState() => _SmoothSlideTransitionState();
}

class _SmoothSlideTransitionState extends State<SmoothSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    _configureAnimations();
  }

  @override
  void didUpdateWidget(SmoothSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slideDirection != widget.slideDirection ||
        oldWidget.fade != widget.fade) {
      _configureAnimations();
    }
  }

  void _configureAnimations() {
    final offset = _getOffsetForDirection(widget.slideDirection);
    _slideAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: widget.fade ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  Offset _getOffsetForDirection(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.left:
        return const Offset(0.2, 0);
      case AxisDirection.right:
        return const Offset(-0.2, 0);
      case AxisDirection.up:
        return const Offset(0, 0.2);
      case AxisDirection.down:
        return const Offset(0, -0.2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.fade
          ? FadeTransition(opacity: _fadeAnimation, child: widget.child)
          : widget.child,
    );
  }
}

/// Pulse animation for attention-grabbing elements
class PulseAnimation extends StatefulWidget {
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.repeat = true,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.maxScale),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.maxScale, end: widget.minScale),
        weight: 50.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer loading effect for cards and lists
class ShimmerCard extends StatefulWidget {
  const ShimmerCard({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = 12,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: widget.height,
      width: widget.width,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_animation.value - 1, 0),
                  end: Alignment(_animation.value + 1, 0),
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Enhanced loading overlay with blur effect
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.blurStrength = 2.0,
    this.backgroundColor,
    this.progress,
  });

  final Widget child;
  final bool isLoading;
  final String? message;
  final double blurStrength;
  final Color? backgroundColor;
  final double? progress;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotionDurations.medium,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  color: widget.backgroundColor ??
                      theme.colorScheme.surface.withValues(alpha: 0.8),
                  child: Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.progress != null)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  value: widget.progress,
                                  strokeWidth: 4,
                                ),
                              )
                            else
                              const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(strokeWidth: 4),
                              ),
                            if (widget.message != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                widget.message!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
