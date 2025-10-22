import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/icebreakers/icebreaker_controller.dart';
import 'package:aroosi_flutter/features/icebreakers/icebreaker_models.dart';
import 'package:aroosi_flutter/core/toast_service.dart';

class IcebreakersScreen extends ConsumerStatefulWidget {
  const IcebreakersScreen({super.key});

  @override
  ConsumerState<IcebreakersScreen> createState() => _IcebreakersScreenState();
}

class _IcebreakersScreenState extends ConsumerState<IcebreakersScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icebreakersAsync = ref.watch(icebreakerControllerProvider);
    final controller = ref.read(icebreakerControllerProvider.notifier);

    // Fetch icebreakers if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!icebreakersAsync.isLoading && icebreakersAsync.icebreakers.isEmpty && icebreakersAsync.error == null) {
        controller.fetchDailyIcebreakers();
      }
    });

    Widget? progressWidget;
    if (!icebreakersAsync.isLoading && icebreakersAsync.error == null) {
      final icebreakers = icebreakersAsync.icebreakers;
      final answeredCount = icebreakers.where((q) => q.answered).length;
      final progress = icebreakers.isEmpty
          ? 0.0
          : answeredCount / icebreakers.length;

      progressWidget = Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$answeredCount / ${icebreakers.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Icebreakers'),
        actions: [
          if (icebreakersAsync.isLoading)
            const SizedBox.shrink()
          else if (icebreakersAsync.error != null)
            IconButton(
              icon: const Icon(Icons.error),
              onPressed: () => controller.fetchDailyIcebreakers(),
            )
          else if (progressWidget != null)
            progressWidget,
        ],
      ),
      body: icebreakersAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : icebreakersAsync.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${icebreakersAsync.error}'),
                  ElevatedButton(
                    onPressed: () => controller.fetchDailyIcebreakers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : icebreakersAsync.icebreakers.isEmpty
          ? const Center(child: Text('No icebreakers available today.'))
          : RefreshIndicator(
              onRefresh: () async {
                await controller.refreshIcebreakers();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: icebreakersAsync.icebreakers.length,
                itemBuilder: (context, index) {
                  final icebreaker = icebreakersAsync.icebreakers[index];
                  final controller = _getController(icebreaker.id);
                  final focusNode = _getFocusNode(icebreaker.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: IcebreakerCard(
                      icebreaker: icebreaker,
                      controller: controller,
                      focusNode: focusNode,
                      onSave: (answer) => _handleSave(icebreaker.id, answer),
                      onSkip: () => _handleSkip(
                        index,
                        icebreakersAsync.icebreakers.length,
                      ),
                      onNext: () => _handleNext(
                        index,
                        icebreakersAsync.icebreakers.length,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  TextEditingController _getController(String id) {
    return _controllers[id] ??= TextEditingController();
  }

  FocusNode _getFocusNode(String id) {
    return _focusNodes[id] ??= FocusNode();
  }

  void _handleSave(String id, String answer) async {
    final controller = ref.read(icebreakerControllerProvider.notifier);
    final success = await controller.submitAnswer(id, answer);

    if (success && mounted) {
      // Haptic feedback for success
      HapticFeedback.lightImpact();

      ToastService.instance.success('Saved');

      // Auto-advance to next question
      final icebreakersAsync = ref.read(icebreakerControllerProvider);
      final icebreakers = icebreakersAsync.icebreakers;
      final currentIndex = icebreakers.indexWhere((q) => q.id == id);
      if (currentIndex >= 0 && currentIndex < icebreakers.length - 1) {
        _scrollToIndex(currentIndex + 1);
      }

      // Check if all are answered
      final answeredCount = icebreakers.where((q) => q.answered).length;
      if (answeredCount >= icebreakers.length) {
        // Haptic feedback for completion
        HapticFeedback.mediumImpact();
        ToastService.instance.success('All icebreakers answered — nice!');
      }
    } else if (mounted) {
      // Haptic feedback for error
      HapticFeedback.lightImpact();
      ToastService.instance.error('Failed to save');
    }
  }

  void _handleSkip(int currentIndex, int totalLength) {
    if (currentIndex < totalLength - 1) {
      _scrollToIndex(currentIndex + 1);
    }
  }

  void _handleNext(int currentIndex, int totalLength) {
    if (currentIndex < totalLength - 1) {
      _scrollToIndex(currentIndex + 1);
    }
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemHeight = 200.0; // Approximate height of each card
        final targetOffset = index * itemHeight;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}

class IcebreakerCard extends ConsumerWidget {
  const IcebreakerCard({
    super.key,
    required this.icebreaker,
    required this.controller,
    required this.focusNode,
    required this.onSave,
    required this.onSkip,
    required this.onNext,
  });

  final Icebreaker icebreaker;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSave;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icebreakerState = ref.watch(icebreakerControllerProvider);
    final minLength = 10;
    final text = controller.text;
    final remaining = (minLength - text.trim().length).clamp(0, minLength);
    final isSaving = icebreakerState.savingIds.contains(icebreaker.id);
    final canSave = text.trim().length >= minLength && !isSaving;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icebreaker.text,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Type your answer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 4,
                maxLength: 280,
                onChanged: (value) {
                  // Trigger rebuild to update character count
                },
                onEditingComplete: () {
                  // Auto-save when user finishes editing
                  final text = controller.text.trim();
                  if (text.length >= 10 && text != (icebreaker.answer ?? '')) {
                    onSave(text);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remaining > 0
                      ? '$remaining more characters to go'
                      : 'Looks good!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${text.length}/280',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: canSave ? () => onSave(controller.text) : null,
                      child: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(icebreaker.answered ? 'Update' : 'Save'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onNext,
                      child: Text(
                        'Next →',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
