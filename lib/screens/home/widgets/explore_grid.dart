import 'package:flutter/material.dart';

class ExploreGrid extends StatelessWidget {
  const ExploreGrid({super.key, required this.onNavigate});
  final void Function(String routeName) onNavigate;

  @override
  Widget build(BuildContext context) {
    final tiles = <ExploreTileData>[
      ExploreTileData('Search Profiles', Icons.search, 'search'),
      ExploreTileData('Favorites', Icons.favorite_outline, 'favorites'),
      ExploreTileData('Shortlists', Icons.bookmark_outline, 'mainShortlists'),
      ExploreTileData(
        'Icebreakers',
        Icons.lightbulb_outline,
        'mainIcebreakers',
      ),
      ExploreTileData('Edit Profile', Icons.edit, 'mainEditProfile'),
      ExploreTileData(
        'Subscription',
        Icons.workspace_premium,
        'mainSubscription',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final t = tiles[index];
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onNavigate(t.routeName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(t.icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ExploreTileData {
  const ExploreTileData(this.label, this.icon, this.routeName);
  final String label;
  final IconData icon;
  final String routeName;
}
