import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_repository.dart';
import '../domain/weekly_summary.dart';

/// Repositorio de progreso. En producción se sobrescribe con el cliente real;
/// en tests, con uno simulado.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  throw UnimplementedError(
      'progressRepositoryProvider debe sobrescribirse en main.dart o tests');
});

/// Comparación semanal, parametrizada por el lunes de la semana a mostrar.
final progressControllerProvider =
    AsyncNotifierProvider.family<ProgressController, WeeklyComparison, DateTime>(
  ProgressController.new,
);

class ProgressController extends FamilyAsyncNotifier<WeeklyComparison, DateTime> {
  @override
  Future<WeeklyComparison> build(DateTime arg) async {
    return ref
        .read(progressRepositoryProvider)
        .fetchWeeklyComparison(weekStart: arg);
  }
}