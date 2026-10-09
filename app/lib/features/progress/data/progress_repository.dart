import 'package:supabase_flutter/supabase_flutter.dart';

import '../../food/data/food_repository.dart';
import '../../workouts/data/workout_repository.dart';
import '../domain/weekly_summary.dart';

/// Repositorio de progreso: agrega sesiones y comidas de la semana actual y de
/// la anterior y construye la comparación semana a semana.
class ProgressRepository {
  ProgressRepository(this._client);

  final SupabaseClient _client;

  /// Devuelve la comparación de la semana que contiene [weekStart] frente a la
  /// anterior. Por defecto usa la semana actual.
  Future<WeeklyComparison> fetchWeeklyComparison({DateTime? weekStart}) async {
    final reference = weekStart ?? DateTime.now();
    final currentStart = isoWeekStart(reference);
    final previousStart = currentStart.subtract(const Duration(days: 7));
    final end = currentStart.add(const Duration(days: 7));

    final sessions = await WorkoutRepository(_client)
        .fetchSessions(from: previousStart, to: end);
    final food = await FoodRepository(_client)
        .fetchEntries(from: previousStart, to: end);

    return compareWeeks(
      currentWeekStart: currentStart,
      sessions: sessions,
      foodEntries: food,
    );
  }
}