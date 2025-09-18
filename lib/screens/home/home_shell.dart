import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/platform/platform_utils.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(BuildContext context, int index) {
    // Light haptic on iOS
    if (isCupertinoPlatform(context)) {
      // ignore: deprecated_member_use
      Feedback.forTap(context);
    }
    shell.goBranch(index,
        initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (isCupertinoPlatform(context)) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: shell.currentIndex,
          onTap: (i) => _onTap(context, i),
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart), label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
          ],
        ),
        tabBuilder: (context, index) {
          // GoRouter provides the body via shell
          return shell;
        },
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
