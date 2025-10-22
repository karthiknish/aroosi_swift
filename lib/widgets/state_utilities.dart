import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/widgets/empty_states.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/widgets/offline_states.dart';

/// A comprehensive state management widget that handles loading, error, empty, and success states
class StateBuilder<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final Widget? offlineWidget;
  final VoidCallback? onRetry;
  final bool showEmptyWhenNoData;
  final bool handleOffline;

  const StateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.offlineWidget,
    this.onRetry,
    this.showEmptyWhenNoData = false,
    this.handleOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return loadingWidget ?? const _LoadingState();
    }

    if (state.hasError) {
      final error = state.error.toString();

      // Check if it's an offline error
      if (handleOffline && _isOfflineError(error)) {
        return offlineWidget ?? OfflineState(onRetry: onRetry);
      }

      return errorWidget ??
          ErrorState(
            title: 'Something went wrong',
            subtitle: 'Failed to load data',
            errorMessage: error,
            onRetryPressed: onRetry,
          );
    }

    final data = state.value;

    if (data == null) {
      return emptyWidget ??
          (showEmptyWhenNoData
              ? const NoDataEmptyState()
              : const SizedBox.shrink());
    }

    // Check if data is empty (for lists)
    if (showEmptyWhenNoData && _isEmpty(data)) {
      return emptyWidget ?? const NoDataEmptyState();
    }

    return builder(data);
  }

  bool _isOfflineError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('offline') ||
        lowerError.contains('no internet');
  }

  bool _isEmpty(dynamic data) {
    if (data is List) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    return false;
  }
}

/// A loading state widget with shimmer effect
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

/// A loading overlay that can be shown over content
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.background.withValues(alpha: 0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  if (loadingMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      loadingMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A widget that handles pull-to-refresh with error states
class RefreshableStateBuilder<T> extends StatefulWidget {
  final Future<T> Function() onRefresh;
  final Widget Function(T data) builder;
  final Widget? initialWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final VoidCallback? onRetry;
  final bool showEmptyWhenNoData;

  const RefreshableStateBuilder({
    super.key,
    required this.onRefresh,
    required this.builder,
    this.initialWidget,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.onRetry,
    this.showEmptyWhenNoData = false,
  });

  @override
  State<RefreshableStateBuilder<T>> createState() =>
      _RefreshableStateBuilderState<T>();
}

class _RefreshableStateBuilderState<T>
    extends State<RefreshableStateBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ?? const _LoadingState();
        }

        if (snapshot.hasError) {
          return widget.errorWidget ??
              ErrorState(
                title: 'Failed to load',
                subtitle: 'Unable to refresh data',
                errorMessage: snapshot.error.toString(),
                onRetryPressed: _retry,
              );
        }

        final data = snapshot.data;

        if (data == null) {
          return widget.emptyWidget ??
              (widget.showEmptyWhenNoData
                  ? const NoDataEmptyState()
                  : const SizedBox.shrink());
        }

        // Check if data is empty (for lists)
        if (widget.showEmptyWhenNoData && _isEmpty(data)) {
          return widget.emptyWidget ?? const NoDataEmptyState();
        }

        return GestureDetector(
          onVerticalDragDown: (_) => _handleRefresh(),
          child: widget.builder(data),
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _future = widget.onRefresh();
    });
  }

  void _retry() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      _handleRefresh();
    }
  }

  bool _isEmpty(dynamic data) {
    if (data is List) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    return false;
  }
}

/// A widget that provides retry functionality with exponential backoff
class RetryableOperation extends StatefulWidget {
  final Future<void> Function() operation;
  final Widget Function(BuildContext context) builder;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final int maxRetries;
  final Duration initialDelay;

  const RetryableOperation({
    super.key,
    required this.operation,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  State<RetryableOperation> createState() => _RetryableOperationState();
}

class _RetryableOperationState extends State<RetryableOperation> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _retryCount = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder(context),
        if (_isLoading)
          Container(
            color: AppColors.background.withValues(alpha: 0.8),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        if (_hasError)
          ErrorState(
            title: 'Operation Failed',
            subtitle: 'Unable to complete the requested action',
            errorMessage: _errorMessage,
            onRetryPressed: _retry,
            actionLabel: 'Cancel',
            onActionPressed: _cancel,
          ),
      ],
    );
  }

  Future<void> _execute() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await widget.operation();
      _retryCount = 0;
      widget.onSuccess?.call();
    } catch (e) {
      _handleError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleError(String error) {
    setState(() {
      _hasError = true;
      _errorMessage = error;
    });

    widget.onError?.call();
  }

  Future<void> _retry() async {
    if (_retryCount >= widget.maxRetries) {
      return;
    }

    _retryCount++;
    final delay = widget.initialDelay * (1 << (_retryCount - 1));

    await Future.delayed(delay);
    await _execute();
  }

  void _cancel() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _execute();
  }
}

/// A widget that handles state with shimmer loading for lists
class ShimmerListBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) shimmerBuilder;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const ShimmerListBuilder({
    super.key,
    required this.itemCount,
    required this.shimmerBuilder,
    this.separator,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? EdgeInsets.zero,
      physics: physics,
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          separator ?? const SizedBox(height: 16),
      itemBuilder: (context, index) => shimmerBuilder(index),
    );
  }
}

/// A widget that shows different states based on data availability
class DataStateBuilder<T> extends StatelessWidget {
  final T? data;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final Widget? offlineWidget;
  final VoidCallback? onRetry;

  const DataStateBuilder({
    super.key,
    this.data,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.offlineWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return emptyWidget ?? const NoDataEmptyState();
    }

    return builder(data as T);
  }
}

/// A connection status widget that shows online/offline status
class ConnectionStatus extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;
  final bool showBanner;

  const ConnectionStatus({
    super.key,
    required this.isOnline,
    this.onRetry,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return const SizedBox.shrink();
    }

    if (!showBanner) {
      return const SizedBox.shrink();
    }

    return OfflineBanner(message: 'No internet connection', onRetry: onRetry);
  }
}

/// A skeleton loading widget for content
class ContentSkeleton extends StatelessWidget {
  final int lines;
  final double width;
  final double height;

  const ContentSkeleton({
    super.key,
    this.lines = 3,
    this.width = double.infinity,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
