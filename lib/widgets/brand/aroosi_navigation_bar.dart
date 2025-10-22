import 'package:flutter/material.dart';

import 'package:aroosi_flutter/theme/colors.dart';

class AroosiNavigationBar extends StatelessWidget {
  const AroosiNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  static const _items = <_NavItem>[
    _NavItem(
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      selectedIcon: Icons.grid_view,
    ),
    _NavItem(label: 'Aroosi', isBrand: true),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.auroraOutline),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.92),
              Colors.white.withValues(alpha: 0.72),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.auroraSky.withValues(alpha: 0.12),
              blurRadius: 30,
              spreadRadius: -12,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = currentIndex == index;
              return Expanded(
                child: _NavButton(
                  item: item,
                  selected: selected,
                  onTap: () => onTabSelected(index),
                  theme: theme,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    this.icon,
    this.selectedIcon,
    this.isBrand = false,
  });

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final bool isBrand;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.16)
        : Colors.transparent;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(foreground),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    if (item.isBrand) {
      return _AroosiGlyph(selected: selected);
    }
    final iconData = selected ? (item.selectedIcon ?? item.icon) : item.icon;
    return Icon(iconData, color: color, size: 26);
  }
}

class _AroosiGlyph extends StatelessWidget {
  const _AroosiGlyph({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: selected
          ? const [AppColors.primary, AppColors.auroraIris]
          : const [AppColors.auroraRose, AppColors.auroraSky],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Text(
        'Aroosi',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'Boldonse',
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
