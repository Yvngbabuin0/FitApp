import 'package:fitness_app/features/workouts/domain/workout_metrics.dart';
import 'package:fitness_app/features/workouts/domain/workout_session.dart';
import 'package:fitness_app/features/workouts/domain/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sessionVolume', () {
    test('lista vacía → 0 (no NaN)', () {
      expect(sessionVolume(const []), 0);
    });

    test('una serie 3x100 → 300', () {
      const sets = [
        WorkoutSet(
          exerciseId: 'ex-1',
          setIndex: 0,
          reps: 3,
          weight: 100,
          completed: true,
        ),
      ];

      expect(sessionVolume(sets), 300);
    });

    test('varias series suman reps x peso', () {
      const sets = [
        WorkoutSet(exerciseId: 'ex-1', setIndex: 0, reps: 5, weight: 100, completed: true),
        WorkoutSet(exerciseId: 'ex-1', setIndex: 1, reps: 5, weight: 100, completed: true),
        WorkoutSet(exerciseId: 'ex-1', setIndex: 2, reps: 8, weight: 50, completed: true),
      ];

      expect(sessionVolume(sets), 1400);
    });
  });

  group('estimateOneRepMax', () {
    test('100 kg x 5 reps ≈ 116.67', () {
      expect(estimateOneRepMax(100, 5), closeTo(116.67, 0.01));
    });

    test('reps <= 0 devuelve el propio peso', () {
      expect(estimateOneRepMax(100, 0), 100);
      expect(estimateOneRepMax(100, -3), 100);
    });
  });

  group('bestWeightForExercise', () {
    test('devuelve el peso máximo entre sesiones', () {
      final sessions = [
        _session(DateTime(2026, 10, 1), [
          _set('ex-1', 0, 5, 100),
          _set('ex-1', 1, 5, 105),
        ]),
        _session(DateTime(2026, 10, 2), [
          _set('ex-1', 0, 5, 110),
        ]),
      ];

      expect(bestWeightForExercise('ex-1', sessions), 110);
    });

    test('sin datos → 0', () {
      expect(bestWeightForExercise('ex-1', const []), 0);
      expect(
        bestWeightForExercise('ex-1', [
          _session(DateTime(2026, 10, 1), [_set('ex-2', 0, 5, 50)]),
        ]),
        0,
      );
    });
  });

  group('detectNewPrs', () {
    test('historial 100, 100, 110 → PR del ejercicio', () {
      final sessions = [
        _session(DateTime(2026, 10, 1), [_set('ex-1', 0, 5, 100)]),
        _session(DateTime(2026, 10, 2), [_set('ex-1', 0, 5, 100)]),
        _session(DateTime(2026, 10, 3), [_set('ex-1', 0, 5, 110)]),
      ];

      expect(detectNewPrs(sessions), {'ex-1'});
    });

    test('igualar el máximo histórico no es PR', () {
      final sessions = [
        _session(DateTime(2026, 10, 1), [_set('ex-1', 0, 5, 100)]),
        _session(DateTime(2026, 10, 2), [_set('ex-1', 0, 5, 110)]),
        _session(DateTime(2026, 10, 3), [_set('ex-1', 0, 5, 110)]),
      ];

      expect(detectNewPrs(sessions), isEmpty);
    });

    test('una sola sesión no cuenta como PR', () {
      final sessions = [
        _session(DateTime(2026, 10, 1), [_set('ex-1', 0, 5, 100)]),
      ];

      expect(detectNewPrs(sessions), isEmpty);
    });
  });
}

WorkoutSession _session(DateTime start, List<WorkoutSet> sets) => WorkoutSession(
      id: 's',
      userId: 'u',
      startedAt: start,
      sets: sets,
    );

WorkoutSet _set(String exerciseId, int index, int reps, double weight) => WorkoutSet(
      exerciseId: exerciseId,
      setIndex: index,
      reps: reps,
      weight: weight,
      completed: true,
    );
