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
import '../../features/home/presentation/home_screen.dart';
import '../../features/workouts/presentation/exercise_chart_screen.dart';
import '../../features/workouts/presentation/exercise_list_screen.dart';
import '../../features/workouts/presentation/workout_log_screen.dart';

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
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = authRepository.currentUser != null;
      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !onAuthRoute) return '/login';
      if (loggedIn && onAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/workouts', builder: (_, _) => const ExerciseListScreen()),
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
      GoRoute(path: '/food', builder: (_, _) => const FoodCaptureScreen()),
      GoRoute(
        path: '/food/review',
        builder: (context, state) => FoodReviewScreen(
          initialItems: (state.extra as List? ?? const []).cast<FoodItem>(),
        ),
      ),
      GoRoute(path: '/food/log', builder: (_, _) => const DailyLogScreen()),
    ],
  );
});