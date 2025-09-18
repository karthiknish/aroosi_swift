import 'package:flutter/widgets.dart';

/// Adds a scroll listener to trigger [onLoadMore] when the user nears the end.
///
/// - [threshold]: pixels from the bottom at which to trigger loading (default 200).
/// - [canLoadMore]: optional guard to prevent duplicate triggers (e.g., based on state.hasMore/state.loading).
///
/// Returns the listener callback so callers can remove it if needed, though disposing
/// the controller typically suffices.
VoidCallback addLoadMoreListener(
  ScrollController controller, {
  required VoidCallback onLoadMore,
  double threshold = 200,
  bool Function()? canLoadMore,
}) {
  void listener() {
    if (canLoadMore != null && !canLoadMore()) return;
    final position = controller.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    final trigger = position.maxScrollExtent - threshold;
    if (position.pixels >= trigger) {
      onLoadMore();
    }
  }

  controller.addListener(listener);
  return () => controller.removeListener(listener);
}
