import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/workout_controller.dart';
import '../domain/exercise.dart';

/// Lista de ejercicios (catálogo + propios) con alta de ejercicio propio y
/// acceso al registro de entrenamiento.
class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  Future<void> _showAddExerciseDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final groupController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo ejercicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('new-exercise-name'),
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('new-exercise-group'),
              controller: groupController,
              decoration: const InputDecoration(
                labelText: 'Grupo muscular',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('create-exercise-button'),
            onPressed: () async {
              final name = nameController.text.trim();
              final group = groupController.text.trim();
              if (name.isEmpty || group.isEmpty) return;
              Navigator.of(dialogContext).pop();
              await ref
                  .read(workoutControllerProvider.notifier)
                  .createExercise(name, group);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    nameController.dispose();
    groupController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(workoutControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
        actions: [
          IconButton(
            key: const Key('add-exercise-button'),
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo ejercicio',
            onPressed: () => _showAddExerciseDialog(context, ref),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudieron cargar los ejercicios.\n$error',
              textAlign: TextAlign.center),
        ),
        data: (exercises) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final exercise in exercises)
              _ExerciseTile(exercise: exercise),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('go-to-log-button'),
        onPressed: () => context.go('/workouts/log'),
        icon: const Icon(Icons.fitness_center),
        label: const Text('Registrar entrenamiento'),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.fitness_center),
      title: Text(exercise.name),
      subtitle: Text(exercise.muscleGroup),
      trailing: exercise.isCustom
          ? const Chip(label: Text('propio'))
          : null,
    );
  }
}