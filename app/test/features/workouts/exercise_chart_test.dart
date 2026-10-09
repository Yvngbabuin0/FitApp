import 'package:fitness_app/features/workouts/application/workout_controller.dart';
import 'package:fitness_app/features/workouts/data/workout_repository.dart';
import 'package:fitness_app/features/workouts/domain/workout_session.dart';
import 'package:fitness_app/features/workouts/domain/workout_set.dart';
import 'package:fitness_app/features/workouts/presentation/exercise_chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  group('evolutionPoints', () {
    test('0 sesiones → sin puntos', () {
      expect(evolutionPoints(const [], 'ex-1'), isEmpty);
    });

    test('2 sesiones → 2 puntos con peso máximo y volumen por sesión', () {
      final sessions = [
        _session(DateTime(2026, 10, 1), [
          _set('ex-1', 0, 5, 100),
          _set('ex-1', 1, 5, 110),
        ]),
        _session(DateTime(2026, 10, 5), [
          _set('ex-1', 0, 3, 120),
        ]),
      ];

      final points = evolutionPoints(sessions, 'ex-1');

      expect(points, hasLength(2));
      expect(points[0].maxWeight, 110);
      expect(points[0].volume, 5 * 100 + 5 * 110);
      expect(points[1].maxWeight, 120);
      expect(points[1].volume, 3 * 120);
    });
  });

  testWidgets('0 sesiones → estado vacío en la pantalla', (tester) async {
    final repo = MockWorkoutRepository();
    when(() => repo.fetchSessionsForExercise(any()))
        .thenAnswer((_) async => const <WorkoutSession>[]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ExerciseChartScreen(exerciseId: 'ex-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Sin datos'), findsOneWidget);
  });
}

WorkoutSession _session(DateTime start, List<WorkoutSet> sets) => WorkoutSession(
      id: 's',
      userId: 'u',
      startedAt: start,
      sets: sets,
    );

WorkoutSet _set(String exerciseId, int index, int reps, double weight) =>
    WorkoutSet(
      exerciseId: exerciseId,
      setIndex: index,
      reps: reps,
      weight: weight,
      completed: true,
    );