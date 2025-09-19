import 'package:flutter/material.dart';

class ExploreGrid extends StatelessWidget {
  const ExploreGrid({super.key, required this.onNavigate});
  final void Function(String routeName) onNavigate;

  @override
  Widget build(BuildContext context) {
    final tiles = <ExploreTileData>[
      ExploreTileData('Search Profiles', Icons.search, 'search', Colors.blue, 'Find your perfect match'),
      ExploreTileData('Favorites', Icons.favorite_outline, 'favorites', Colors.red, 'View your liked profiles'),
      ExploreTileData('Shortlists', Icons.bookmark_outline, 'mainShortlists', Colors.green, 'Manage your saved lists'),
      ExploreTileData(
        'Icebreakers',
        Icons.lightbulb_outline,
        'mainIcebreakers',
        Colors.orange,
        'Get conversation starters',
      ),
      ExploreTileData('Edit Profile', Icons.edit, 'mainEditProfile', Colors.purple, 'Update your information'),
      ExploreTileData(
        'Subscription',
        Icons.workspace_premium,
        'mainSubscription',
        Colors.indigo,
        'Manage your plan',
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue exploring',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final t = tiles[index];
              return ExploreTile(
                label: t.label,
                icon: t.icon,
                color: t.color,
                description: t.description,
                onTap: () => onNavigate(t.routeName),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ExploreTileData {
  const ExploreTileData(this.label, this.icon, this.routeName, this.color, this.description);
  final String label;
  final IconData icon;
  final String routeName;
  final Color color;
  final String description;
}

class ExploreTile extends StatelessWidget {
  const ExploreTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });
  
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: color,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
