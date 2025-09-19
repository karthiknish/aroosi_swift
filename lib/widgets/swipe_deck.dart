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

// Global key to access swipe deck state
class SwipeDeckGlobalKey<T> {
  final GlobalKey<_SwipeDeckState<T>> _key;
  
  SwipeDeckGlobalKey({String? debugLabel}) : _key = GlobalKey(debugLabel: debugLabel);
  
  _SwipeDeckState<T>? get currentState => _key.currentState;
  
  GlobalKey<_SwipeDeckState<T>> get key => _key;
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

  int _currentIndex = 0;

  void _animateOff(SwipeDirection direction) async {
    if (_currentIndex >= widget.items.length) return;
    print('Animating off: direction=$direction, currentIndex=$_currentIndex');
    final item = widget.items[_currentIndex];
    final width = MediaQuery.of(context).size.width;
    final targetX = direction == SwipeDirection.right ? width : -width;
    final tween = Tween<Offset>(
      begin: _offset,
      end: Offset(targetX, _offset.dy),
    );
    tween.animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    await _controller.forward(from: 0);
    print('Animation complete, calling onSwipe callback');
    widget.onSwipe?.call(item, direction);
    setState(() {
      _currentIndex++;
      _resetCard();
      print('Card advanced, new index=$_currentIndex');
      if (_currentIndex >= widget.items.length) widget.onEnd?.call();
    });
  }

  // Public methods for programmatic swipes
  void swipeLeft() {
    if (_currentIndex < widget.items.length) {
      _animateOff(SwipeDirection.left);
    }
  }

  void swipeRight() {
    if (_currentIndex < widget.items.length) {
      _animateOff(SwipeDirection.right);
    }
  }

  bool get hasCards => _currentIndex < widget.items.length;
  
  int get currentIndex => _currentIndex;
  
  T? get currentCard => _currentIndex < widget.items.length ? widget.items[_currentIndex] : null;

  

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty || _currentIndex >= widget.items.length) {
      return const SizedBox.shrink();
    }
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
        final maxStack = math.min(3, widget.items.length - _currentIndex);
        for (int i = maxStack - 1; i >= 0; i--) {
          final itemIndex = _currentIndex + i;
          if (itemIndex >= widget.items.length) continue;
          final item = widget.items[itemIndex];
          final isTop = i == 0;
          final scale = isTop ? 1.0 : 1.0 - (i * 0.04);
          final translateY = isTop ? 0.0 : i * 12.0;

          // Precache next two images if itemBuilder returns an Image inside Hero etc.
          if (i <= 2) {
            try {
              final url = (item as dynamic).avatarUrl;
              if (url is String && url.trim().isNotEmpty) {
                precacheImage(NetworkImage(url), context);
              }
            } catch (_) {}
          }

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
                    if (isTop && widget.overlayBuilder == null)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: true,
                          child: _ProgressSwipeOverlay(
                            direction: direction,
                            progress: progress,
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
                onTap: () {
                  print('Card tapped');
                },
                onHorizontalDragStart: (_) {
                  print('Swipe started');
                },
                onHorizontalDragUpdate: (d) {
                  setState(() {
                    _offset += Offset(d.delta.dx, 0);
                    _rotation =
                        (_offset.dx / constraints.maxWidth) *
                        widget.maxRotation;
                    print('Swipe update: offset=$_offset, rotation=$_rotation');
                  });
                },
                onHorizontalDragEnd: (d) {
                  print('Swipe ended: offset=$_offset, velocity=${d.primaryVelocity}');
                  final threshold = constraints.maxWidth * 0.32;
                  if (_offset.dx > threshold) {
                    print('Swiping right');
                    _animateOff(SwipeDirection.right);
                  } else if (_offset.dx < -threshold) {
                    print('Swiping left');
                    _animateOff(SwipeDirection.left);
                  } else {
                    print('Resetting card');
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
    return Container(
      constraints: const BoxConstraints(
        minHeight: 400,
        minWidth: 300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(elevation: 3, child: widget.itemBuilder(context, item)),
      ),
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

class _ProgressSwipeOverlay extends StatelessWidget {
  const _ProgressSwipeOverlay({
    required this.direction,
    required this.progress,
  });
  final SwipeDirection? direction;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final likeOpacity = direction == SwipeDirection.right ? progress : 0.0;
    final passOpacity = direction == SwipeDirection.left ? progress : 0.0;
    
    return Stack(
      children: [
        // Background color overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: direction == SwipeDirection.right 
                  ? Colors.green.withOpacity(0.3 * likeOpacity)
                  : direction == SwipeDirection.left
                      ? Colors.red.withOpacity(0.3 * passOpacity)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Opacity(
            opacity: passOpacity.clamp(0, 1),
            child: _AnimatedLabel(
              text: 'PASS',
              color: Colors.redAccent,
              rotation: -12 * passOpacity,
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Opacity(
            opacity: likeOpacity.clamp(0, 1),
            child: _AnimatedLabel(
              text: 'LIKE',
              color: Colors.lightGreen,
              rotation: 12 * likeOpacity,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedLabel extends StatelessWidget {
  const _AnimatedLabel({
    required this.text,
    required this.color,
    required this.rotation,
  });
  final String text;
  final Color color;
  final double rotation; // degrees

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.08),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
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
