import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/responsive.dart';
import 'package:aroosi_flutter/platform/platform_utils.dart';
import 'package:aroosi_flutter/widgets/brand/aroosi_navigation_bar.dart';

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
              if (!Responsive.isLargeScreen(context)) ...[
                _buildTabItem(
                  context,
                  0,
                  CupertinoIcons.square_grid_2x2,
                  'Dashboard',
                ),
                _buildTabItem(
                  context,
                  1,
                  null,
                  'Aroosi',
                ), // null icon for custom search icon
                _buildTabItem(context, 2, CupertinoIcons.person, 'Profile'),
              ] else ...[
                // iPad/Tablet layout with more space
                Expanded(child: _buildTabItem(context, 0, CupertinoIcons.square_grid_2x2, 'Dashboard')),
                Expanded(child: _buildTabItem(context, 1, null, 'Aroosi')),
                Expanded(child: _buildTabItem(context, 2, CupertinoIcons.person, 'Profile')),
                // Additional space for iPad - could add more tabs here if needed
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    IconData? icon,
    String label,
  ) {
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
    shell.goBranch(
      validIndex,
      initialLocation: validIndex == shell.currentIndex,
    );
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
      key: const ValueKey('material_scaffold'),
      body: shell,
      bottomNavigationBar: AroosiNavigationBar(
        currentIndex: shell.currentIndex,
        onTabSelected: (index) {
          _handleTap(context, index);
        },
      ),
    );
  }
}

class _SearchCircleIcon extends StatelessWidget {
  const _SearchCircleIcon({this.selected = false, this.onTap});

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24.0;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.primary;
    final bg = selected ? scheme.primary : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            12,
          ), // Rounded corners instead of circle
        ),
        alignment: Alignment.center,
        child: Text(
          'Aroosi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Boldonse',
            fontWeight: FontWeight.w700,
            fontSize: size * 0.9,
            color: fg,
            height: 1,
          ),
        ),
      ),
    );
  }
}
