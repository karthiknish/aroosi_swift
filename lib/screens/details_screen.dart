import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/profiles/detail_controller.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';
import 'package:aroosi_flutter/features/safety/safety_controller.dart';
import 'package:aroosi_flutter/core/toast_service.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  bool _blocked = false;
  bool _limitReached = false;
  String? _blockedMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateAccessAndLoad();
    });
  }

  Future<void> _evaluateAccessAndLoad() async {
    await ref.read(profileDetailControllerProvider.notifier).load(widget.id);
    if (mounted) {
      setState(() {
        _blocked = false;
        _limitReached = false;
        _blockedMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileDetailControllerProvider);
    final data = state.data;

    if (_blocked) {
      return AppScaffold(
        title: 'Profile',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _blockedMessage ??
                      (_limitReached
                          ? 'You\'ve reached your monthly profile view limit.'
                          : 'This profile is not available.'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: data != null
          ? (data['fullName']?.toString() ??
                data['name']?.toString() ??
                'Profile')
          : 'Profile',
      actions: data == null
          ? null
          : [
              IconButton(
                icon: Icon(
                  (data['isFavorite'] == true || data['favorite'] == true)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: () async {
                  await ref
                      .read(profileDetailControllerProvider.notifier)
                      .toggleFavorite(widget.id);
                  if (!mounted) return;
                  final isNowFav =
                      (data['isFavorite'] == true || data['favorite'] == true);
                  ToastService.instance.success(
                    isNowFav ? 'Removed from favorites' : 'Added to favorites',
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  (data['isShortlisted'] == true || data['shortlisted'] == true)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                onPressed: () async {
                  await ref
                      .read(profileDetailControllerProvider.notifier)
                      .toggleShortlist(widget.id);
                  if (!mounted) return;
                  final isNowSl =
                      (data['isShortlisted'] == true ||
                      data['shortlisted'] == true);
                  ToastService.instance.success(
                    isNowSl ? 'Removed from shortlist' : 'Added to shortlist',
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final userId = widget.id;
                  if (value == 'report') {
                    final reason = await showDialog<_ReportInputResult>(
                      context: context,
                      builder: (ctx) => const _ReportDialog(),
                    );
                    if (reason != null) {
                      final ok = await ref
                          .read(safetyControllerProvider.notifier)
                          .report(
                            userId,
                            reason: reason.reason,
                            details: reason.details,
                          );
                      if (!mounted) return;
                      ok
                          ? ToastService.instance.success('Report submitted')
                          : ToastService.instance.error(
                              'Failed to submit report',
                            );
                    }
                  } else if (value == 'block') {
                    final ok = await ref
                        .read(safetyControllerProvider.notifier)
                        .block(userId);
                    if (!mounted) return;
                    ok
                        ? ToastService.instance.success('User blocked')
                        : ToastService.instance.error('Failed to block user');
                  } else if (value == 'unblock') {
                    final ok = await ref
                        .read(safetyControllerProvider.notifier)
                        .unblock(userId);
                    if (!mounted) return;
                    ok
                        ? ToastService.instance.success('User unblocked')
                        : ToastService.instance.error('Failed to unblock user');
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'report', child: Text('Report')),
                  PopupMenuItem(
                    value: 'block',
                    enabled: true,
                    child: const Text('Block'),
                  ),
                  PopupMenuItem(
                    value: 'unblock',
                    enabled: true,
                    child: const Text('Unblock'),
                  ),
                ],
              ),
            ],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeThrough(
          delay: AppMotionDurations.fast,
          child: state.loading
              ? _buildSkeleton(context)
              : state.error != null
              ? FadeIn(
                  duration: AppMotionDurations.short,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref
                              .read(profileDetailControllerProvider.notifier)
                              .load(widget.id),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(context, data),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return FadeSlideIn(
      duration: AppMotionDurations.medium,
      beginOffset: const Offset(0, 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 160,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 120,
                    color: Colors.grey.shade200,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 16, width: 100, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: double.infinity,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: double.infinity,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();
    final name =
        data['fullName']?.toString() ?? data['name']?.toString() ?? 'Profile';
    final city = data['city']?.toString() ?? '';
    final about = data['about']?.toString() ?? data['bio']?.toString() ?? '';
    final interests =
        (data['interests'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    return FadeSlideIn(
      duration: AppMotionDurations.medium,
      beginOffset: const Offset(0, 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 32, child: Icon(Icons.person_outline)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (city.isNotEmpty) Text(city),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (about.isNotEmpty) ...[
            const Text('About'),
            const SizedBox(height: 8),
            Text(about),
            const SizedBox(height: 24),
          ],
          if (interests.isNotEmpty) ...[
            const Text('Interests'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: interests.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportInputResult {
  final String reason;
  final String? details;
  const _ReportInputResult(this.reason, this.details);
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report user'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. Spam, harassment, fake profile',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(
              context,
              _ReportInputResult(
                reason,
                _detailsController.text.trim().isEmpty
                    ? null
                    : _detailsController.text.trim(),
              ),
            );
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
