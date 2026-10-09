import 'package:fitness_app/app.dart';
import 'package:fitness_app/features/auth/application/auth_controller.dart';
import 'package:fitness_app/features/auth/data/auth_repository.dart';
import 'package:fitness_app/features/food/application/food_controller.dart';
import 'package:fitness_app/features/food/data/food_repository.dart';
import 'package:fitness_app/features/profile/application/profile_controller.dart';
import 'package:fitness_app/features/profile/data/profile_repository.dart';
import 'package:fitness_app/features/profile/domain/profile.dart';
import 'package:fitness_app/features/progress/application/progress_controller.dart';
import 'package:fitness_app/features/progress/data/progress_repository.dart';
import 'package:fitness_app/features/progress/domain/weekly_summary.dart';
import 'package:fitness_app/features/workouts/application/workout_controller.dart';
import 'package:fitness_app/features/workouts/data/workout_repository.dart';
import 'package:fitness_app/features/workouts/domain/exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockWorkoutRepository extends Mock implements WorkoutRepository {}
class MockFoodRepository extends Mock implements FoodRepository {}
class MockProgressRepository extends Mock implements ProgressRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  testWidgets('con sesión iniciada muestra la shell con las 4 pestañas',
      (tester) async {
    final auth = MockAuthRepository();
    when(() => auth.currentUser).thenReturn(
      const User(
        id: 'u-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00.000000Z',
      ),
    );
    when(() => auth.authStateChanges)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    final workouts = MockWorkoutRepository();
    when(() => workouts.fetchExercises())
        .thenAnswer((_) async => const <Exercise>[]);

    final food = MockFoodRepository();
    when(() => food.fetchEntries(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => const []);

    final progress = MockProgressRepository();
    when(
      () => progress.fetchWeeklyComparison(weekStart: any(named: 'weekStart')),
    ).thenAnswer(
      (_) async => WeeklyComparison(
        current: WeeklySummary(
          weekStart: DateTime(2026, 10, 5),
          volume: 0,
          sessions: 0,
          newPrs: 0,
          avgCalories: 0,
          avgProteinG: 0,
          avgCarbsG: 0,
          avgFatG: 0,
          adherence: 0,
        ),
        previous: WeeklySummary(
          weekStart: DateTime(2026, 9, 28),
          volume: 0,
          sessions: 0,
          newPrs: 0,
          avgCalories: 0,
          avgProteinG: 0,
          avgCarbsG: 0,
          avgFatG: 0,
          adherence: 0,
        ),
      ),
    );

    final profile = MockProfileRepository();
    when(() => profile.fetch('u-1'))
        .thenAnswer((_) async => const Profile(id: 'u-1'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          workoutRepositoryProvider.overrideWithValue(workouts),
          foodRepositoryProvider.overrideWithValue(food),
          progressRepositoryProvider.overrideWithValue(progress),
          profileRepositoryProvider.overrideWithValue(profile),
        ],
        child: const FitnessApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Barra inferior con las 4 pestañas.
    expect(find.byType(NavigationBar), findsOneWidget);
    Finder navText(String label) => find.descendant(
        of: find.byType(NavigationBar), matching: find.text(label));
    expect(navText('Comidas'), findsOneWidget);
    expect(navText('Entrenos'), findsOneWidget);
    expect(navText('Progreso'), findsOneWidget);
    expect(navText('Perfil'), findsOneWidget);

    // Pestaña inicial: pantalla de captura de comidas.
    expect(find.text('Analiza una foto para registrar tu comida'),
        findsOneWidget);

    // Cambiar a la pestaña Entrenos mantiene la barra inferior.
    await tester.tap(find.text('Entrenos'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}