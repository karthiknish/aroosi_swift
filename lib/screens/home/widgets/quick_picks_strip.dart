import 'package:flutter/material.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';

class QuickPicksStrip extends StatelessWidget {
  const QuickPicksStrip({
    super.key,
    required this.loading,
    required this.items,
    required this.onTapProfile,
    required this.onSeeAll,
  });

  final bool loading;
  final List<ProfileSummary> items;
  final void Function(String id) onTapProfile;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => const QuickPickSkeleton(),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: 4,
        ),
      );
    }
    if (items.isEmpty) {
      return Text(
        'No quick picks today. Check back later.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final p = items[index];
                return QuickPickCard(item: p, onTap: () => onTapProfile(p.id));
              },
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onSeeAll,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('See all'),
          ),
        ],
      ),
    );
  }
}

class QuickPickCard extends StatelessWidget {
  const QuickPickCard({super.key, required this.item, this.onTap});
  final ProfileSummary item;
  final VoidCallback? onTap;

  static const _placeholderAsset = 'assets/images/placeholder.png';

  @override
  Widget build(BuildContext context) {
    final img = (item.avatarUrl != null && item.avatarUrl!.trim().isNotEmpty)
        ? FadeInImage.assetNetwork(
            placeholder: _placeholderAsset,
            image: item.avatarUrl!,
            fit: BoxFit.cover,
            imageErrorBuilder: (_, __, ___) =>
                Image.asset(_placeholderAsset, fit: BoxFit.cover),
          )
        : Image.asset(_placeholderAsset, fit: BoxFit.cover);
    return SizedBox(
      width: 110,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: img,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickPickSkeleton extends StatelessWidget {
  const QuickPickSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 12, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}
