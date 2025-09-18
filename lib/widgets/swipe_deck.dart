import 'dart:math' as math;
import 'package:flutter/material.dart';

typedef SwipeDecisionBuilder =
    Widget Function(
      BuildContext context,
      SwipeDirection? direction,
      double swipeProgress,
    );

enum SwipeDirection { left, right }

class SwipeDeck<T> extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onSwipe,
    this.onEnd,
    this.overlayBuilder,
    this.maxRotation = 15,
  });

  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T item, SwipeDirection direction)? onSwipe;
  final VoidCallback? onEnd;
  final SwipeDecisionBuilder? overlayBuilder;
  final double maxRotation;

  @override
  State<SwipeDeck<T>> createState() => _SwipeDeckState<T>();
}

class _SwipeDeckState<T> extends State<SwipeDeck<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _offset = Offset.zero;
  double _rotation = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetCard() {
    _controller.reset();
    _offset = Offset.zero;
    _rotation = 0;
  }

  void _animateOff(SwipeDirection direction) async {
    if (widget.items.isEmpty) return;
    final item = widget.items.first;
    final width = MediaQuery.of(context).size.width;
    final targetX = direction == SwipeDirection.right ? width : -width;
    final tween = Tween<Offset>(
      begin: _offset,
      end: Offset(targetX, _offset.dy),
    );
    tween.animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    await _controller.forward(from: 0);
    widget.onSwipe?.call(item, direction);
    setState(() {
      widget.items.removeAt(0);
      _resetCard();
      if (widget.items.isEmpty) widget.onEnd?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    // topItem available via widget.items.first if needed
    final direction = _offset.dx == 0
        ? null
        : (_offset.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    final progress =
        (_offset.dx.abs() / (MediaQuery.of(context).size.width * 0.35)).clamp(
          0.0,
          1.0,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = <Widget>[];
        // Render a small stack of next cards
        for (int i = math.min(3, widget.items.length) - 1; i >= 0; i--) {
          final item = widget.items[i];
          final isTop = i == 0;
          final scale = isTop ? 1.0 : 1.0 - (i * 0.04);
          final translateY = isTop ? 0.0 : i * 12.0;

          final card = Transform.translate(
            offset: isTop ? _offset : Offset(0, translateY),
            child: Transform.rotate(
              angle: isTop ? _rotation * (math.pi / 180) : 0,
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  children: [
                    _buildCard(item),
                    if (isTop && widget.overlayBuilder != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: true,
                          child: widget.overlayBuilder!(
                            context,
                            direction,
                            progress,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );

          if (isTop) {
            cards.add(
              GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _offset += d.delta;
                    _rotation =
                        (_offset.dx / constraints.maxWidth) *
                        widget.maxRotation;
                  });
                },
                onPanEnd: (_) {
                  final threshold = constraints.maxWidth * 0.32;
                  if (_offset.dx > threshold) {
                    _animateOff(SwipeDirection.right);
                  } else if (_offset.dx < -threshold) {
                    _animateOff(SwipeDirection.left);
                  } else {
                    _resetCard();
                  }
                },
                child: card,
              ),
            );
          } else {
            cards.add(card);
          }
        }

        return Stack(children: cards.reversed.toList());
      },
    );
  }

  Widget _buildCard(T item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(elevation: 3, child: widget.itemBuilder(context, item)),
    );
  }
}

class DefaultSwipeOverlay extends StatelessWidget {
  const DefaultSwipeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _Label(text: 'NOPE', color: Colors.redAccent),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _Label(text: 'LIKE', color: Colors.lightGreen),
            ),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
