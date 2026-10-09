import 'package:fitness_app/features/food/domain/food_entry.dart';
import 'package:fitness_app/features/food/domain/food_item.dart';
import 'package:fitness_app/features/progress/domain/weekly_summary.dart';
import 'package:fitness_app/features/workouts/domain/workout_session.dart';
import 'package:fitness_app/features/workouts/domain/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Semana ISO actual: lunes 2026-10-05 (el 2026-10-08 es jueves).
  final currentWeekStart = DateTime(2026, 10, 5);

  final sessions = [
    // Semana anterior (start 2026-09-28): volumen 500.
    _session(DateTime(2026, 9, 29), [_set('ex-1', 0, 5, 100)]),
    // Semana actual: 550 + 500 = 1050, 2 sesiones.
    _session(DateTime(2026, 10, 5), [_set('ex-1', 0, 5, 110)]),
    _session(DateTime(2026, 10, 7), [_set('ex-2', 0, 10, 50)]),
  ];

  final food = [
    _entry(DateTime(2026, 9, 29), 1500, 100, 120, 40),
    _entry(DateTime(2026, 10, 5), 2000, 150, 200, 60),
    _entry(DateTime(2026, 10, 6), 1800, 130, 180, 55),
  ];

  group('isoWeekStart', () {
    test('devuelve el lunes 00:00 local', () {
      final monday = isoWeekStart(DateTime(2026, 10, 8, 15, 30));

      expect(monday, DateTime(2026, 10, 5));
      expect(monday.weekday, DateTime.monday);
      expect(monday.hour, 0);
      expect(monday.minute, 0);
    });

    test('un domingo y el lunes siguiente dan lunes distintos', () {
      final sunday = isoWeekStart(DateTime(2026, 10, 11, 23, 59));
      final nextMonday = isoWeekStart(DateTime(2026, 10, 12, 0, 1));

      expect(sunday, DateTime(2026, 10, 5));
      expect(nextMonday, DateTime(2026, 10, 12));
      expect(sunday, isNot(equals(nextMonday)));
    });
  });

  group('buildWeeklySummary', () {
    test('semana sin datos → todo 0 y sin NaN', () {
      final summary = buildWeeklySummary(
        weekStart: currentWeekStart,
        sessions: const [],
        foodEntries: const [],
      );

      expect(summary.volume, 0);
      expect(summary.sessions, 0);
      expect(summary.newPrs, 0);
      expect(summary.avgCalories, 0);
      expect(summary.avgProteinG, 0);
      expect(summary.avgCarbsG, 0);
      expect(summary.avgFatG, 0);
      expect(summary.adherence, 0);
      expect(summary.avgCalories.isNaN, isFalse);
      expect(summary.adherence.isNaN, isFalse);
    });

    test('agrega volumen, sesiones, medias y adherencia', () {
      final summary = buildWeeklySummary(
        weekStart: currentWeekStart,
        sessions: sessions,
        foodEntries: food,
      );

      expect(summary.weekStart, currentWeekStart);
      expect(summary.volume, 1050);
      expect(summary.sessions, 2);
      expect(summary.avgCalories, 1900);
      expect(summary.avgProteinG, 140);
      expect(summary.avgCarbsG, 190);
      expect(summary.avgFatG, 57.5);
      // Adherencia = días con CUALQUIER registro (comida O entrenamiento) / 7.
      // Días: lunes(comida+entreno), martes(comida), miércoles(entreno) = 3.
      expect(summary.adherence, closeTo(3 / 7, 1e-9));
    });

    test('un día con solo entrenamiento cuenta para la adherencia', () {
      final summary = buildWeeklySummary(
        weekStart: currentWeekStart,
        sessions: [
          _session(DateTime(2026, 10, 6), [_set('ex-1', 0, 5, 100)]),
        ],
        foodEntries: const [],
      );

      expect(summary.adherence, closeTo(1 / 7, 1e-9));
      // Pero las medias de comida valen 0 porque no hay registro de comida.
      expect(summary.avgCalories, 0);
    });

    test('cuenta PRs nuevos de la semana (supera el máximo previo)', () {
      final summary = buildWeeklySummary(
        weekStart: currentWeekStart,
        sessions: sessions,
        foodEntries: food,
      );

      // ex-1: 110 en la semana > 100 previo → PR. ex-2 sin historial → no.
      expect(summary.newPrs, 1);
    });

    test('la semana anterior no tiene PRs sin historial previo', () {
      final summary = buildWeeklySummary(
        weekStart: DateTime(2026, 9, 28),
        sessions: sessions,
        foodEntries: food,
      );

      expect(summary.newPrs, 0);
      expect(summary.volume, 500);
      expect(summary.sessions, 1);
    });
  });

  group('compareWeeks', () {
    test('calcula deltas de la semana actual frente a la anterior', () {
      final comparison = compareWeeks(
        currentWeekStart: currentWeekStart,
        sessions: sessions,
        foodEntries: food,
      );

      expect(comparison.current.volume, 1050);
      expect(comparison.previous.volume, 500);
      expect(comparison.volumeDelta, 550);
      expect(comparison.sessionsDelta, 1);
      expect(comparison.newPrsDelta, 1);
      expect(comparison.caloriesDelta, 400);
      expect(comparison.proteinDelta, 40);
      expect(comparison.carbsDelta, 70);
      expect(comparison.fatDelta, 17.5);
      // Semana anterior: 1 día con registro (lun 29/9: comida+entreno) = 1/7.
      // Actual: 3 días = 3/7 → delta 2/7.
      expect(comparison.adherenceDelta, closeTo(2 / 7, 1e-9));
    });
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

FoodEntry _entry(
  DateTime loggedAt,
  int calories,
  double protein,
  double carbs,
  double fat,
) =>
    FoodEntry(
      userId: 'u',
      loggedAt: loggedAt,
      mealType: MealType.lunch,
      source: FoodSource.manual,
      items: [
        FoodItem(
          name: 'comida',
          quantity: 1,
          unit: 'unit',
          calories: calories,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
        ),
      ],
    );
