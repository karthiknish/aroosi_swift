import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.isLoading = false,
    this.showProgress = true,
  });

  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T item, SwipeDirection direction)? onSwipe;
  final VoidCallback? onEnd;
  final SwipeDecisionBuilder? overlayBuilder;
  final double maxRotation;
  final bool isLoading;
  final bool showProgress;

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

  void _animateReset() {
    if (!mounted) return;

    try {
      final tween = Tween<Offset>(
        begin: _offset,
        end: Offset.zero,
      );

      final animation = tween.animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
        ),
      );

      animation.addListener(() {
        if (mounted) {
          setState(() {
            _offset = animation.value;
            _rotation = (_offset.dx / MediaQuery.of(context).size.width) * widget.maxRotation;
          });
        }
      });

      _controller.forward(from: 0);
    } catch (e) {
      // Handle animation errors gracefully
      if (mounted) {
        _resetCard();
      }
    }
  }

  int _currentIndex = 0;

  void _animateOff(SwipeDirection direction) async {
    if (_currentIndex >= widget.items.length || !mounted) return;

    try {
      final item = widget.items[_currentIndex];
      final width = MediaQuery.of(context).size.width;
      final targetX = direction == SwipeDirection.right ? width * 1.2 : -width * 1.2;

      // Create animation with custom curve for more natural feel
      final tween = Tween<Offset>(
        begin: _offset,
        end: Offset(targetX, _offset.dy),
      );

      final animation = tween.animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );

      // Update offset and rotation during animation
      animation.addListener(() {
        if (mounted) {
          setState(() {
            _offset = animation.value;
            _rotation = (_offset.dx / MediaQuery.of(context).size.width) * widget.maxRotation;
          });
        }
      });

      await _controller.forward(from: 0);

      // Call callback and advance to next card
      if (mounted) {
        widget.onSwipe?.call(item, direction);
        setState(() {
          _currentIndex++;
          _resetCard();
          if (_currentIndex >= widget.items.length) widget.onEnd?.call();
        });
      }
    } catch (e) {
      // Handle animation errors gracefully
      if (mounted) {
        _resetCard();
      }
    }
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
    if (widget.isLoading) {
      return const _LoadingState();
    }

    if (widget.items.isEmpty || _currentIndex >= widget.items.length) {
      return const _EmptyState();
    }

    final direction = _offset.dx == 0
        ? null
        : (_offset.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    final progress = (_offset.dx.abs() / (MediaQuery.of(context).size.width * 0.35)).clamp(0.0, 1.0);

    return FocusScope(
      child: Column(
        children: [
          if (widget.showProgress)
            _ProgressIndicator(
              current: _currentIndex + 1,
              total: widget.items.length,
            ),
          Expanded(
            child: LayoutBuilder(
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

                  // Precache next two images for better performance
                  if (i <= 2) {
                    _precacheImage(item, context);
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
                      Semantics(
                        label: 'Profile card. Use arrow keys or swipe to navigate. Right arrow or swipe right to like, left arrow or swipe left to pass',
                        child: Focus(
                          autofocus: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              // TODO: Add accessibility announcement
                              // SemanticsService.announce('Profile details', TextDirection.ltr);
                            },
                            onHorizontalDragStart: (_) {},
                            onHorizontalDragUpdate: (d) {
                              setState(() {
                                final newOffset = _offset + Offset(d.delta.dx, 0);
                                final maxDrag = constraints.maxWidth * 0.8;
                                _offset = Offset(
                                  newOffset.dx.clamp(-maxDrag, maxDrag),
                                  0,
                                );
                                _rotation = (_offset.dx / constraints.maxWidth) * widget.maxRotation;
                              });
                            },
                            onHorizontalDragEnd: (d) {
                              final threshold = constraints.maxWidth * 0.25;
                              final velocity = d.primaryVelocity ?? 0;
                              final distance = _offset.dx.abs();

                              if (velocity.abs() > 1000) {
                                HapticFeedback.mediumImpact();
                                if (velocity > 0) {
                                  _animateOff(SwipeDirection.right);
                                } else {
                                  _animateOff(SwipeDirection.left);
                                }
                              } else if (distance > threshold) {
                                HapticFeedback.lightImpact();
                                if (_offset.dx > 0) {
                                  _animateOff(SwipeDirection.right);
                                } else {
                                  _animateOff(SwipeDirection.left);
                                }
                              } else {
                                _animateReset();
                              }
                            },
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                    HapticFeedback.lightImpact();
                                    _animateOff(SwipeDirection.right);
                                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                    HapticFeedback.lightImpact();
                                    _animateOff(SwipeDirection.left);
                                  }
                                }
                              },
                              child: card,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    cards.add(
                      Semantics(
                        label: 'Background profile card',
                        child: card,
                      ),
                    );
                  }
                }
                return Stack(children: cards.reversed.toList());
              },
            ),
          ),
        ],
      ),
    );
  }

  void _precacheImage(T item, BuildContext context) {
    try {
      // Try to extract image URL from the item
      final dynamic itemData = item;
      final url = itemData.avatarUrl ?? itemData.imageUrl ?? itemData.profileImageUrl;

      if (url is String && url.trim().isNotEmpty && _isValidUrl(url)) {
        precacheImage(NetworkImage(url), context);
      }
    } catch (_) {
      // Ignore precaching errors
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (_) {
      return false;
    }
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
        // Background color overlay with gradient effect
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: direction == SwipeDirection.right
                  ? LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green.withOpacity(0.1 * likeOpacity),
                        Colors.green.withOpacity(0.3 * likeOpacity),
                      ],
                      stops: [0.0, 0.5, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : direction == SwipeDirection.left
                      ? LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.red.withOpacity(0.1 * passOpacity),
                            Colors.red.withOpacity(0.3 * passOpacity),
                          ],
                          stops: [0.0, 0.5, 1.0],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        )
                      : null,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Opacity(
            opacity: passOpacity.clamp(0, 1),
            child: Transform.scale(
              scale: 0.8 + (0.2 * passOpacity),
              child: _AnimatedLabel(
                text: 'PASS',
                color: Colors.redAccent,
                rotation: -12 * passOpacity,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Opacity(
            opacity: likeOpacity.clamp(0, 1),
            child: Transform.scale(
              scale: 0.8 + (0.2 * likeOpacity),
              child: _AnimatedLabel(
                text: 'LIKE',
                color: Colors.lightGreen,
                rotation: 12 * likeOpacity,
              ),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading profiles...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No more profiles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new matches!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile $current of $total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
