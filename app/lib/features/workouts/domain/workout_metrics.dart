import 'workout_session.dart';
import 'workout_set.dart';

/// Volumen total de una lista de series: Σ(reps × peso).
///
/// Una lista vacía devuelve 0 (nunca NaN).
double sessionVolume(List<WorkoutSet> sets) =>
    sets.fold(0.0, (sum, set) => sum + set.reps * set.weight);

/// Estimación de 1RM con la fórmula de Epley: `peso × (1 + reps / 30)`.
///
/// Con `reps <= 0` devuelve el propio peso.
double estimateOneRepMax(double weight, int reps) =>
    reps <= 0 ? weight : weight * (1 + reps / 30);

/// Peso máximo levantado en un ejercicio. Sin datos devuelve 0.
double bestWeightForExercise(String exerciseId, List<WorkoutSession> sessions) {
  var best = 0.0;
  for (final session in sessions) {
    for (final set in session.sets) {
      if (set.exerciseId == exerciseId && set.weight > best) {
        best = set.weight;
      }
    }
  }
  return best;
}

/// Devuelve los ids de ejercicio cuyo **último** máximo de peso supera a todos
/// los anteriores (es decir, se ha batido un récord personal).
///
/// Un ejercicio con una sola sesión registrada no cuenta como PR, y igualar el
/// máximo histórico tampoco.
Set<String> detectNewPrs(List<WorkoutSession> sessions) {
  final ordered = [...sessions]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  // Por ejercicio: máximo de cada sesión en la que aparece, en orden temporal.
  final maxPerSession = <String, List<double>>{};
  for (final session in ordered) {
    final maxInSession = <String, double>{};
    for (final set in session.sets) {
      final current = maxInSession[set.exerciseId];
      if (current == null || set.weight > current) {
        maxInSession[set.exerciseId] = set.weight;
      }
    }
    maxInSession.forEach((exerciseId, maxWeight) {
      maxPerSession.putIfAbsent(exerciseId, () => <double>[]).add(maxWeight);
    });
  }

  final prs = <String>{};
  maxPerSession.forEach((exerciseId, values) {
    if (values.length < 2) return;
    final last = values.last;
    final previousMax =
        values.sublist(0, values.length - 1).reduce((a, b) => a > b ? a : b);
    if (last > previousMax) prs.add(exerciseId);
  });
  return prs;
}
