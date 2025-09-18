import 'package:flutter/material.dart';

import 'package:aroosi_flutter/platform/adaptive_pickers.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';

class QuickPicksScreen extends ConsumerWidget {
  const QuickPicksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = AdaptiveRefresh(
      onRefresh: () async => ToastService.instance.success('Refreshed'),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('Recommended Match ${index + 1}'),
                subtitle: const Text('Based on your recent activity'),
              ),
            );
          }, childCount: 10),
        ),
      ],
    );

    return AppScaffold(
      title: 'Quick Picks',
      actions: [
        IconButton(
          onPressed: () async {
            final ctx = context;
            // ignore: use_build_context_synchronously
            final date = await showAdaptiveDatePicker(ctx);
            if (date != null) {
              final allowed = ref.read(featureUsageControllerProvider.notifier).requestUsage(UsageMetric.searchPerformed);
              if (!allowed) {
                ToastService.instance.warning('Search filters are limited on Free. Upgrade for unlimited filters.');
                return;
              }
              ToastService.instance.success('Filter date: ${date.toLocal().toString().split(' ').first}');
            }
          },
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
      child: content,
    );
  }
}
