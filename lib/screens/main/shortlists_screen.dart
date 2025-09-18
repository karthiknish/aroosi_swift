import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aroosi_flutter/widgets/profile_list_item.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';

import 'package:aroosi_flutter/platform/adaptive_dialogs.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';

class ShortlistsScreen extends ConsumerStatefulWidget {
  const ShortlistsScreen({super.key});

  @override
  ConsumerState<ShortlistsScreen> createState() => _ShortlistsScreenState();
}

class _ShortlistsScreenState extends ConsumerState<ShortlistsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shortlistControllerProvider.notifier).refresh();
    });
    addLoadMoreListener(
      _scrollController,
      threshold: 120,
      canLoadMore: () {
        final s = ref.read(shortlistControllerProvider);
        return s.hasMore && !s.loading;
      },
      onLoadMore: () => ref.read(shortlistControllerProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shortlistControllerProvider);

    // Error state when nothing loaded
    if (!state.loading && state.error != null && state.items.isEmpty) {
      return AppScaffold(
        title: 'Shortlists',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(shortlistControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (!state.loading && state.error == null && state.items.isEmpty) {
      return AppScaffold(
        title: 'Shortlists',
        child: const Center(
          child: Text('No profiles in your shortlist yet.'),
        ),
      );
    }

    Widget buildItem(BuildContext context, int index) {
      if (state.items.isEmpty && state.loading) {
        return const ProfileListSkeleton();
      }
      if (index >= state.items.length) {
        return PagedListFooter(hasMore: state.hasMore, isLoading: state.loading);
      }
      final p = state.items[index];
      return ProfileListItem(
        profile: p,
        onTap: () {
          ref.read(lastSelectedProfileIdProvider.notifier).set(p.id);
          context.push('/details/${p.id}');
        },
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () async {
            final confirmed = await showAdaptiveConfirm(
              context,
              title: 'Remove from shortlist?',
              message: 'This will remove the match from your shortlist.',
            );
            if (confirmed == true) {
              await ref.read(shortlistControllerProvider.notifier).toggleShortlist(p.id);
              if (!mounted) return;
              ToastService.instance.success('Removed');
            }
          },
        ),
      );
    }

    final listChild = ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: (state.items.isEmpty && state.loading)
          ? 6
          : state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: buildItem,
    );

    final slivers = [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          buildItem,
          childCount: (state.items.isEmpty && state.loading)
              ? 6
              : state.items.length + (state.hasMore ? 1 : 0),
        ),
      ),
    ];

    final content = AdaptiveRefresh(
      onRefresh: () async {
        await ref.read(shortlistControllerProvider.notifier).refresh();
        if (!mounted) return;
        ToastService.instance.success('Refreshed');
      },
      controller: _scrollController,
      slivers: slivers,
      child: listChild,
    );

    return AppScaffold(
      title: 'Shortlists',
      actions: [
        // Bulk clear can be added later when backend supports it
      ],
      child: content,
    );
  }
}
