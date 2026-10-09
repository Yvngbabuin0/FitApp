import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workout_repository.dart';
import '../domain/exercise.dart';

/// Repositorio de entrenamientos. En producción se sobrescribe con el cliente
/// real de Supabase; en tests, con uno simulado.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError(
      'workoutRepositoryProvider debe sobrescribirse en main.dart o en tests');
});

final workoutControllerProvider =
    AsyncNotifierProvider<WorkoutController, List<Exercise>>(
  WorkoutController.new,
);

/// Estado del catálogo de ejercicios del usuario.
class WorkoutController extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async {
    return ref.read(workoutRepositoryProvider).fetchExercises();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(workoutRepositoryProvider).fetchExercises(),
    );
  }

  Future<Exercise> createExercise(String name, String muscleGroup) async {
    final exercise = await ref
        .read(workoutRepositoryProvider)
        .createExercise(name, muscleGroup);
    await refresh();
    return exercise;
  }
}