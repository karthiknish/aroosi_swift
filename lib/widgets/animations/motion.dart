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
