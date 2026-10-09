import 'package:fitness_app/features/workouts/domain/exercise.dart';
import 'package:fitness_app/features/workouts/domain/workout_session.dart';
import 'package:fitness_app/features/workouts/domain/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exercise', () {
    test('toMap/fromMap hace round-trip', () {
      const e = Exercise(
        id: 'ex-1',
        userId: 'u-1',
        name: 'Press banca',
        muscleGroup: 'Pecho',
        isCustom: true,
      );

      final back = Exercise.fromMap(e.toMap());

      expect(back.id, 'ex-1');
      expect(back.userId, 'u-1');
      expect(back.name, 'Press banca');
      expect(back.muscleGroup, 'Pecho');
      expect(back.isCustom, isTrue);
    });
  });

  group('WorkoutSet', () {
    test('toMap/fromMap hace round-trip', () {
      const s = WorkoutSet(
        id: 'set-1',
        exerciseId: 'ex-1',
        setIndex: 2,
        reps: 5,
        weight: 100,
        rpe: 8,
        completed: true,
      );

      final back = WorkoutSet.fromMap(s.toMap());

      expect(back.id, 'set-1');
      expect(back.exerciseId, 'ex-1');
      expect(back.setIndex, 2);
      expect(back.reps, 5);
      expect(back.weight, 100);
      expect(back.rpe, 8);
      expect(back.completed, isTrue);
    });

    test('rpe nulo se conserva como null', () {
      const s = WorkoutSet(
        exerciseId: 'ex-1',
        setIndex: 0,
        reps: 5,
        weight: 100,
        completed: false,
      );

      expect(WorkoutSet.fromMap(s.toMap()).rpe, isNull);
    });

    test('weight entero de Postgres se convierte a double', () {
      final map = <String, dynamic>{
        'exercise_id': 'ex-1',
        'set_index': 0,
        'reps': 5,
        'weight': 100,
        'completed': true,
      };

      expect(WorkoutSet.fromMap(map).weight, 100.0);
    });
  });

  group('WorkoutSession', () {
    test('round-trip con lista de series vacía', () {
      final s = WorkoutSession(
        id: 'sess-1',
        userId: 'u-1',
        startedAt: DateTime(2026, 10, 8, 10, 0),
        sets: const [],
      );

      final back = WorkoutSession.fromMap(s.toMap());

      expect(back.id, 'sess-1');
      expect(back.userId, 'u-1');
      expect(back.startedAt, DateTime(2026, 10, 8, 10, 0));
      expect(back.endedAt, isNull);
      expect(back.sets, isEmpty);
    });

    test('round-trip con series', () {
      final session = WorkoutSession(
        id: 'sess-1',
        userId: 'u-1',
        startedAt: DateTime(2026, 10, 8, 10, 0),
        sets: const [
          WorkoutSet(
            exerciseId: 'ex-1',
            setIndex: 0,
            reps: 5,
            weight: 100,
            completed: true,
          ),
        ],
      );

      final back = WorkoutSession.fromMap(session.toMap());

      expect(back.sets.length, 1);
      expect(back.sets.first.weight, 100);
    });
  });
}
