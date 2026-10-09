import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/food/domain/food_item.dart';
import '../../features/food/presentation/daily_log_screen.dart';
import '../../features/food/presentation/food_capture_screen.dart';
import '../../features/food/presentation/food_review_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/progress/presentation/weekly_summary_screen.dart';
import '../../features/workouts/presentation/exercise_chart_screen.dart';
import '../../features/workouts/presentation/exercise_list_screen.dart';
import '../../features/workouts/presentation/workout_log_screen.dart';
import '../../main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  // Rebota el router cuando cambia el estado de auth (login/logout) para
  // re-evaluar el redirect sin recrear la instancia de GoRouter.
  final refresh = ValueNotifier<int>(0);
  final sub = authRepository.authStateChanges.listen((_) => refresh.value++);
  ref.onDispose(() {
    unawaited(sub.cancel());
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: '/food',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = authRepository.currentUser != null;
      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !onAuthRoute) return '/login';
      if (loggedIn && onAuthRoute) return '/food';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/food', builder: (_, _) => const FoodCaptureScreen()),
            GoRoute(
              path: '/food/review',
              builder: (context, state) => FoodReviewScreen(
                initialItems:
                    (state.extra as List? ?? const []).cast<FoodItem>(),
              ),
            ),
            GoRoute(
                path: '/food/log', builder: (_, _) => const DailyLogScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/workouts',
                builder: (_, _) => const ExerciseListScreen()),
            GoRoute(
              path: '/workouts/log',
              builder: (_, _) => const WorkoutLogScreen(),
            ),
            GoRoute(
              path: '/workouts/chart/:exerciseId',
              builder: (context, state) => ExerciseChartScreen(
                exerciseId: state.pathParameters['exerciseId']!,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/progress',
                builder: (_, _) => const WeeklySummaryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    ],
  );
});