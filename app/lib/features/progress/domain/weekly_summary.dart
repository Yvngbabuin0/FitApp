import '../../food/domain/food_entry.dart';
import '../../workouts/domain/workout_metrics.dart';
import '../../workouts/domain/workout_session.dart';

/// Resumen agregado de una semana ISO (lunes a domingo).
class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.volume,
    required this.sessions,
    required this.newPrs,
    required this.avgCalories,
    required this.avgProteinG,
    required this.avgCarbsG,
    required this.avgFatG,
    required this.adherence,
  });

  /// Lunes 00:00 local de la semana.
  final DateTime weekStart;
  final double volume;
  final int sessions;
  final int newPrs;
  final double avgCalories;
  final double avgProteinG;
  final double avgCarbsG;
  final double avgFatG;

  /// Días con registro / 7.
  final double adherence;
}

/// Comparación de la semana actual frente a la anterior.
class WeeklyComparison {
  const WeeklyComparison({required this.current, required this.previous});

  final WeeklySummary current;
  final WeeklySummary previous;

  double get volumeDelta => current.volume - previous.volume;
  int get sessionsDelta => current.sessions - previous.sessions;
  int get newPrsDelta => current.newPrs - previous.newPrs;
  double get caloriesDelta => current.avgCalories - previous.avgCalories;
  double get proteinDelta => current.avgProteinG - previous.avgProteinG;
  double get carbsDelta => current.avgCarbsG - previous.avgCarbsG;
  double get fatDelta => current.avgFatG - previous.avgFatG;
  double get adherenceDelta => current.adherence - previous.adherence;
}

/// Lunes 00:00 local de la semana ISO que contiene [localDate].
DateTime isoWeekStart(DateTime localDate) {
  final date = DateTime(localDate.year, localDate.month, localDate.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

bool _inWeek(DateTime value, DateTime weekStart, DateTime weekEnd) =>
    !value.isBefore(weekStart) && value.isBefore(weekEnd);

String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

/// Construye el [WeeklySummary] de la semana que empieza en [weekStart].
///
/// [sessions] y [foodEntries] pueden contener datos de cualquier fecha; aquí se
/// filtran a la semana. Las medias de kcal/macros se calculan **solo sobre los
/// días con registro** y valen 0 si no hay ninguno (nunca NaN).
WeeklySummary buildWeeklySummary({
  required DateTime weekStart,
  required List<WorkoutSession> sessions,
  required List<FoodEntry> foodEntries,
}) {
  final start = isoWeekStart(weekStart);
  final end = start.add(const Duration(days: 7));

  final weekSessions =
      sessions.where((s) => _inWeek(s.startedAt, start, end)).toList();
  final volume =
      weekSessions.fold(0.0, (sum, s) => sum + sessionVolume(s.sets));

  // PRs: ejercicios que en la semana superan su máximo histórico anterior.
  final priorMax = <String, double>{};
  for (final session in sessions) {
    if (session.startedAt.isBefore(start)) {
      for (final set in session.sets) {
        final current = priorMax[set.exerciseId];
        if (current == null || set.weight > current) {
          priorMax[set.exerciseId] = set.weight;
        }
      }
    }
  }
  final weekMax = <String, double>{};
  for (final session in weekSessions) {
    for (final set in session.sets) {
      final current = weekMax[set.exerciseId];
      if (current == null || set.weight > current) {
        weekMax[set.exerciseId] = set.weight;
      }
    }
  }
  var newPrs = 0;
  weekMax.forEach((exerciseId, weekWeight) {
    final previous = priorMax[exerciseId] ?? 0;
    if (previous > 0 && weekWeight > previous) newPrs++;
  });

  final weekFood =
      foodEntries.where((e) => _inWeek(e.loggedAt, start, end)).toList();
  final loggedDays = <String>{};
  var totalCalories = 0;
  var totalProtein = 0.0;
  var totalCarbs = 0.0;
  var totalFat = 0.0;
  for (final entry in weekFood) {
    loggedDays.add(_dayKey(entry.loggedAt));
    totalCalories += entry.totalCalories;
    totalProtein += entry.totalProteinG;
    totalCarbs += entry.totalCarbsG;
    totalFat += entry.totalFatG;
  }
  final days = loggedDays.length;

  // Adherencia: días con CUALQUIER registro (comida O entrenamiento) / 7.
  final recordDays = <String>{...loggedDays};
  for (final session in weekSessions) {
    recordDays.add(_dayKey(session.startedAt));
  }
  final adherence = recordDays.length / 7;

  return WeeklySummary(
    weekStart: start,
    volume: volume,
    sessions: weekSessions.length,
    newPrs: newPrs,
    avgCalories: days == 0 ? 0 : totalCalories / days,
    avgProteinG: days == 0 ? 0 : totalProtein / days,
    avgCarbsG: days == 0 ? 0 : totalCarbs / days,
    avgFatG: days == 0 ? 0 : totalFat / days,
    adherence: adherence,
  );
}

/// Compara la semana que empieza en [currentWeekStart] con la anterior.
WeeklyComparison compareWeeks({
  required DateTime currentWeekStart,
  required List<WorkoutSession> sessions,
  required List<FoodEntry> foodEntries,
}) {
  final currentStart = isoWeekStart(currentWeekStart);
  final previousStart = currentStart.subtract(const Duration(days: 7));

  return WeeklyComparison(
    current: buildWeeklySummary(
      weekStart: currentStart,
      sessions: sessions,
      foodEntries: foodEntries,
    ),
    previous: buildWeeklySummary(
      weekStart: previousStart,
      sessions: sessions,
      foodEntries: foodEntries,
    ),
  );
}
