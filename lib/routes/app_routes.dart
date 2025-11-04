import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocus_app/modules/menus/goals_view.dart';
import 'package:pocus_app/modules/menus/home_view.dart';
import 'package:pocus_app/modules/menus/login_view.dart';
import 'package:pocus_app/modules/menus/profile_view.dart';
import 'package:pocus_app/modules/menus/progress_view.dart';
import 'package:pocus_app/modules/menus/signup_view.dart';

class AppRoutes {
  static final mainMenuRoutes = <RouteBase>[
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
    GoRoute(
      name: HomeView.routeName,
      path: HomeView.routeName,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          child: const HomeView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: ProgressView.routeName,
      path: ProgressView.routeName,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          child: const ProgressView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: GoalsView.routeName,
      path: GoalsView.routeName,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          child: const GoalsView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      name: ProfileView.routeName,
      path: ProfileView.routeName,
      pageBuilder: (_, state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          child: const ProfileView(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
  ];
}
