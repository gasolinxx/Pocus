import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocus_app/modules/menus/goals_view.dart';
import 'package:pocus_app/modules/menus/home_view.dart';
import 'package:pocus_app/modules/menus/login_view.dart';
import 'package:pocus_app/modules/menus/profile_view.dart';
import 'package:pocus_app/modules/menus/progress_view.dart';
import 'package:pocus_app/modules/menus/signup_view.dart';
import 'package:pocus_app/routes/app_nav_bar.dart';

class AppRouter {
  static GoRouter get router => _router;
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static GlobalKey<NavigatorState> get mainMenuNavigatorKey => _mainMenuNavigatorKey;

  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _mainMenuNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'main-menu');

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: LoginView.routeName,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      // Standalone routes (no AppNavBar)
      GoRoute(
        name: LoginView.routeName,
        path: LoginView.routeName,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        name: SignUpView.routeName,
        path: SignUpView.routeName,
        builder: (context, state) => const SignUpView(),
      ),

      // Routes wrapped with AppNavBar
      ShellRoute(
        navigatorKey: _mainMenuNavigatorKey,
        builder: (_, __, child) {
          return AppNavBar(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            name: HomeView.routeName,
            path: HomeView.routeName,
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            name: ProgressView.routeName,
            path: ProgressView.routeName,
            builder: (context, state) => const ProgressView(),
          ),
          GoRoute(
            name: GoalsView.routeName,
            path: GoalsView.routeName,
            builder: (context, state) => const GoalsView(),
          ),
          GoRoute(
            name: ProfileView.routeName,
            path: ProfileView.routeName,
            builder: (context, state) => const ProfileView(),
          ),
        ],
      ),
    ],
  );
}
