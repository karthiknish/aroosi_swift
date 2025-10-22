import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aroosi_flutter/core/responsive.dart';

class ExploreGrid extends StatelessWidget {
  const ExploreGrid({super.key, required this.onNavigate});
  final void Function(String routeName) onNavigate;

  @override
  Widget build(BuildContext context) {
    final tiles = <ExploreTileData>[
      ExploreTileData(
        'Sacred Circle',
        Icons.family_restroom_rounded,
        'mainSacredCircle',
        Colors.pink,
        'Find sacred matches',
      ),
      ExploreTileData(
        'Search Profiles',
        Icons.search,
        'search',
        Colors.blue,
        'Find your perfect match',
      ),
      ExploreTileData(
        'Favorites',
        Icons.favorite_outline,
        'favorites',
        Colors.red,
        'View liked profiles',
      ),
      ExploreTileData(
        'Shortlists',
        Icons.bookmark_outline,
        'mainShortlists',
        Colors.green,
        'Manage saved lists',
      ),
      ExploreTileData(
        'Icebreakers',
        Icons.lightbulb_outline,
        'mainIcebreakers',
        Colors.orange,
        'Conversation starters',
      ),
      ExploreTileData(
        'Edit Profile',
        Icons.edit,
        'mainEditProfile',
        Colors.purple,
        'Update your information',
      ),
      ExploreTileData(
        'Privacy Settings',
        Icons.privacy_tip_outlined,
        'settingsPrivacy',
        Colors.green,
        'Manage privacy settings',
      ),
    ];

    return AdaptiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Continue exploring',
                  style: TextStyle(fontSize: 18, color: Colors.indigo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            spacing: 12,
            runSpacing: 12,
            children: tiles
                .map(
                  (t) => ExploreTile(
                    label: t.label,
                    icon: t.icon,
                    color: t.color,
                    description: t.description,
                    onTap: () => onNavigate(t.routeName),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class ExploreTileData {
  const ExploreTileData(
    this.label,
    this.icon,
    this.routeName,
    this.color,
    this.description,
  );
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
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: color, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Explore', style: TextStyle(fontSize: 10, color: color)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: color, size: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
