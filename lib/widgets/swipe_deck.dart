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
  State<SwipeDeck<T>> createState() => SwipeDeckState<T>();
}

// Global key to access swipe deck state
class SwipeDeckGlobalKey<T> {
  final GlobalKey<SwipeDeckState<T>> _key;

  SwipeDeckGlobalKey({String? debugLabel})
    : _key = GlobalKey(debugLabel: debugLabel);

  SwipeDeckState<T>? get currentState => _key.currentState;

  GlobalKey<SwipeDeckState<T>> get key => _key;
}

class SwipeDeckState<T> extends State<SwipeDeck<T>> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Public methods for programmatic swipes
  void swipeLeft() {
    if (_currentIndex < widget.items.length) {
      widget.onSwipe?.call(widget.items[_currentIndex], SwipeDirection.left);
      setState(() {
        _currentIndex++;
        if (_currentIndex >= widget.items.length) widget.onEnd?.call();
      });
    }
  }

  void swipeRight() {
    if (_currentIndex < widget.items.length) {
      widget.onSwipe?.call(widget.items[_currentIndex], SwipeDirection.right);
      setState(() {
        _currentIndex++;
        if (_currentIndex >= widget.items.length) widget.onEnd?.call();
      });
    }
  }

  bool get hasCards => _currentIndex < widget.items.length;

  int get currentIndex => _currentIndex;

  T? get currentCard =>
      _currentIndex < widget.items.length ? widget.items[_currentIndex] : null;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const _LoadingState();
    }

    if (widget.items.isEmpty || _currentIndex >= widget.items.length) {
      return const _EmptyState();
    }

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
                final maxStack = math.min(
                  3,
                  widget.items.length - _currentIndex,
                );

                for (int i = maxStack - 1; i >= 0; i--) {
                  final itemIndex = _currentIndex + i;
                  if (itemIndex >= widget.items.length) continue;

                  final item = widget.items[itemIndex];
                  final isTop = i == 0;
                  final scale = isTop ? 1.0 : 1.0 - (i * 0.04);
                  final translateY = isTop ? 0.0 : i * 12.0;

                  final card = Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: _buildCard(item),
                    ),
                  );

                  if (isTop) {
                    cards.add(
                      Semantics(
                        label:
                            'Profile card. Use heart button to like, cross button to pass',
                        child: card,
                      ),
                    );
                  } else {
                    cards.add(card);
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
        style: TextStyle(color: color),
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
  const _ProgressIndicator({required this.current, required this.total});

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
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
