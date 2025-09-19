import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';

/// Custom Cupertino-style tab scaffold that avoids GlobalKey conflicts
class _CupertinoTabScaffoldWrapper extends StatelessWidget {
  const _CupertinoTabScaffoldWrapper({
    required this.shell,
    required this.currentIndex,
    required this.onTap,
  });

  final StatefulNavigationShell shell;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        // Add bottom margin to make space for the floating search button
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          border: Border(
            top: BorderSide(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildTabItem(context, 0, CupertinoIcons.square_grid_2x2, 'Dashboard'),
              _buildTabItem(context, 1, null, 'Search'), // null icon for custom search icon
              _buildTabItem(context, 2, CupertinoIcons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, IconData? icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? CupertinoColors.activeBlue.resolveFrom(context)
        : CupertinoColors.systemGrey.resolveFrom(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, color: color, size: 24)
              else
                _SearchCircleIcon(
                  selected: isSelected,
                  onTap: () => onTap(index),
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _handleTap(BuildContext context, int index) {
    if (isCupertinoPlatform(context)) {
      // ignore: deprecated_member_use
      Feedback.forTap(context);
    }
    // Ensure index is within valid range (0, 1, 2)
    final validIndex = index < 0 ? 0 : (index > 2 ? 2 : index);
    shell.goBranch(validIndex, initialLocation: validIndex == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (isCupertinoPlatform(context)) {
      return _CupertinoTabScaffoldWrapper(
        shell: shell,
        currentIndex: shell.currentIndex,
        onTap: (index) {
          // Direct mapping: 0->Dashboard, 1->Search, 2->Profile
          _handleTap(context, index);
        },
      );
    }
    return Scaffold(
      key: ValueKey('material_scaffold'),
      body: shell,
      bottomNavigationBar: Container(
        // Add padding to the bottom to ensure the search button has space to bleed
        margin: const EdgeInsets.only(bottom: 32),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) {
            // Direct mapping: 0->Dashboard, 1->Search, 2->Profile
            _handleTap(context, index);
          },
          destinations: [
            NavigationDestination(
              key: const ValueKey('dashboard'),
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              key: const ValueKey('search'),
              icon: _SearchCircleIcon(
                key: const ValueKey('search_icon_normal'),
                onTap: () => _handleTap(context, 1),
              ),
              selectedIcon: _SearchCircleIcon(
                key: const ValueKey('search_icon_selected'),
                selected: true,
                onTap: () => _handleTap(context, 1),
              ),
              label: 'Search',
            ),
            NavigationDestination(
              key: const ValueKey('profile'),
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchCircleIcon extends StatelessWidget {
  const _SearchCircleIcon({
    super.key,
    this.selected = false,
    this.onTap,
  });

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24.0;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.primary;
    final bg = selected ? scheme.primary : Colors.transparent;

    // Make the circle much larger and bleed outside the nav bar using SizedBox and Transform
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, -size * 0.85),
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: size * 3.0,
                height: size * 3.0,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary,
                    width: selected ? 0 : 2.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 3,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Boldonse',
                    fontWeight: FontWeight.w700,
                    fontSize: size * 1.4,
                    color: fg,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
