import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userInterestsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(userInterestsControllerProvider);

    return AppScaffold(
      title: 'Select Interests',
      actions: [
        IconButton(
          onPressed: s.selected.isEmpty || s.loading
              ? null
              : () async {
                  final ok = await ref
                      .read(userInterestsControllerProvider.notifier)
                      .save();
                  if (ok) {
                    ToastService.instance.success(
                      'Saved ${s.selected.length} interests',
                    );
                  } else {
                    ToastService.instance.error('Failed to save interests');
                  }
                },
          icon: const Icon(Icons.check),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.loading) const Center(child: CircularProgressIndicator()),
            if (s.error != null && !s.loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  s.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: s.options.map((interest) {
                final isActive = s.selected.contains(interest);
                return ChoiceChip(
                  label: Text(interest),
                  selected: isActive,
                  onSelected: (value) => ref
                      .read(userInterestsControllerProvider.notifier)
                      .toggle(interest, value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
