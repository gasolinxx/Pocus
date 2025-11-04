import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocus_app/components/components.dart';
import 'package:pocus_app/cores/cores.dart';
import 'package:pocus_app/modules/menus/goals_view.dart';
import 'package:pocus_app/modules/menus/home_view.dart';
import 'package:pocus_app/modules/menus/profile_view.dart';
import 'package:pocus_app/modules/menus/progress_view.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.child,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('AppNavBar'));

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomBar(
        opacity: .2,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int? index) => _onTap(context, index ?? 0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        elevation: 8,
        hasInk: true, // new, gives a cute ink effect
        items: _navigationItems,
      ),
    );
  }

  static const _navigationItems = <AppBottomBarItem>[
    AppBottomBarItem(
      icon: Icon(AppIcons.home),
      activeIcon: Icon(AppIcons.homeAlt),
      title: Text("Home"),
    ),
    AppBottomBarItem(
      icon: Icon(Icons.assignment),
      activeIcon: Icon(Icons.assignment),
      title: Text("Tap"),
    ),
    AppBottomBarItem(
      icon: Icon(Icons.add_circle), // Plus icon with a circle
      activeIcon: Icon(Icons.add_circle), // Active version of the same icon
      title: Text("Goals"),
    ),
    AppBottomBarItem(
      icon: Icon(AppIcons.profile),
      activeIcon: Icon(AppIcons.profileAlt),
      title: Text("Profile"),
    ),
  ];

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith(HomeView.routeName)) {
      return 0;
    }
    if (location.startsWith(ProgressView.routeName)) {
      return 1; // "Assignment" icon
    }
    if (location.startsWith(GoalsView.routeName)) {
      return 2; // "Plus Circle" icon
    }
    if (location.startsWith(ProfileView.routeName)) {
      return 3;
    }
    return 0;
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(HomeView.routeName);
        break;
      case 1:
        GoRouter.of(context).go(ProgressView.routeName);
        break;
      case 2:
        GoRouter.of(context).go(GoalsView.routeName);
        break;
      case 3:
        GoRouter.of(context).go(ProfileView.routeName);
        break;
    }
  }
}
