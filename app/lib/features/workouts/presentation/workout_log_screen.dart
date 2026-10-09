import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../application/workout_controller.dart';
import '../domain/exercise.dart';
import '../domain/workout_session.dart';
import '../domain/workout_set.dart';

/// Borrador de una serie mientras se edita (controladores de texto).
class _SetDraft {
  final reps = TextEditingController();
  final weight = TextEditingController();
  final rpe = TextEditingController();

  void dispose() {
    reps.dispose();
    weight.dispose();
    rpe.dispose();
  }
}

/// Pantalla de registro de una sesión de entrenamiento: selecciona ejercicio,
/// añade series (reps/peso/RPE) y guarda la sesión.
class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  String? _exerciseId;
  final List<_SetDraft> _sets = [];
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    for (final draft in _sets) {
      draft.dispose();
    }
    super.dispose();
  }

  double get _volume {
    var total = 0.0;
    for (final draft in _sets) {
      final reps = int.tryParse(draft.reps.text.trim()) ?? 0;
      final weight = double.tryParse(draft.weight.text.trim()) ?? 0;
      total += reps * weight;
    }
    return total;
  }

  void _addSet() => setState(() => _sets.add(_SetDraft()));

  void _removeSet(int index) {
    final draft = _sets.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null) return;

    final sets = <WorkoutSet>[
      for (var i = 0; i < _sets.length; i++)
        WorkoutSet(
          exerciseId: exerciseId,
          setIndex: i,
          reps: int.tryParse(_sets[i].reps.text.trim()) ?? 0,
          weight: double.tryParse(_sets[i].weight.text.trim()) ?? 0,
          rpe: double.tryParse(_sets[i].rpe.text.trim()),
          completed: true,
        ),
    ];

    final session = WorkoutSession(
      userId: ref.read(authRepositoryProvider).currentUser?.id ?? '',
      startedAt: DateTime.now(),
      endedAt: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      sets: sets,
    );

    await ref.read(workoutControllerProvider.notifier).saveSession(session);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrenamiento guardado')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(workoutControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar entrenamiento')),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudieron cargar los ejercicios.\n$error',
              textAlign: TextAlign.center),
        ),
        data: (exercises) {
          if (exercises.isEmpty) {
            return const Center(
              child: Text('Añade ejercicios desde la lista de ejercicios'),
            );
          }
          return _buildForm(context, exercises);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Exercise> exercises) {
    final exerciseId = _exerciseId ?? exercises.first.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          key: const Key('exercise-dropdown'),
          initialValue: exerciseId,
          decoration: const InputDecoration(
            labelText: 'Ejercicio',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final exercise in exercises)
              DropdownMenuItem(
                value: exercise.id,
                child: Text(exercise.name),
              ),
          ],
          onChanged: (value) => setState(() => _exerciseId = value),
        ),
        const SizedBox(height: 16),
        Text('Volumen: ${_volume.toStringAsFixed(0)} kg',
            key: const Key('volume-label'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_sets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin series aún — añade tu primera serie'),
          )
        else
          for (var i = 0; i < _sets.length; i++) _buildSetRow(context, i),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('add-set-button'),
          onPressed: _addSet,
          icon: const Icon(Icons.add),
          label: const Text('Añadir serie'),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('notes-field'),
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('save-workout-button'),
          onPressed: _sets.isEmpty ? null : _save,
          child: const Text('Guardar sesión'),
        ),
      ],
    );
  }

  Widget _buildSetRow(BuildContext context, int index) {
    final draft = _sets[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: Key('reps-field-$index'),
              controller: draft.reps,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Reps',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: Key('weight-field-$index'),
              controller: draft.weight,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Peso',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: Key('rpe-field-$index'),
              controller: draft.rpe,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'RPE',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            key: Key('remove-set-$index'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeSet(index),
          ),
        ],
      ),
    );
  }
}