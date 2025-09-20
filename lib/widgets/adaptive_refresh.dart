import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';

class AdaptiveRefresh extends StatelessWidget {
  const AdaptiveRefresh({
    super.key,
    required this.onRefresh,
    this.controller,
    this.child,
    this.slivers,
  });

  final Future<void> Function() onRefresh;
  final ScrollController? controller;
  final Widget? child;
  final List<Widget>? slivers;

  @override
  Widget build(BuildContext context) {
    final useCupertino = isCupertinoPlatform(context);

    if (useCupertino) {
      return CustomScrollView(
        controller: controller,
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          if (slivers != null && slivers!.isNotEmpty)
            ...slivers!
          else
            SliverToBoxAdapter(child: child ?? const SizedBox.shrink()),
        ],
      );
    }

    if (slivers != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(controller: controller, slivers: slivers!),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
