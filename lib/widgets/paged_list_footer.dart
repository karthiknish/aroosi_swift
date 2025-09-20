import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PagedListFooter extends StatelessWidget {
  const PagedListFooter({
    super.key,
    required this.hasMore,
    required this.isLoading,
    this.indicatorPadding = const EdgeInsets.symmetric(vertical: 24),
  });

  final bool hasMore;
  final bool isLoading;
  final EdgeInsets indicatorPadding;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    final isCupertino =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return Padding(
      padding: indicatorPadding,
      child: Center(
        child: isCupertino
            ? const CupertinoActivityIndicator()
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
      ),
    );
  }
}
