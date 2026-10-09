import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/profile_controller.dart';
import '../domain/profile.dart';

/// Pantalla de perfil: edición de objetivos diarios y unidades.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: Text('No se pudo cargar el perfil.\n$error',
                textAlign: TextAlign.center)),
        data: (profile) => _ProfileForm(profile: profile),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late Units _units;

  @override
  void initState() {
    super.initState();
    _calories = TextEditingController(
        text: widget.profile.dailyCalorieTarget.toString());
    _protein =
        TextEditingController(text: widget.profile.proteinTargetG.toString());
    _carbs = TextEditingController(text: widget.profile.carbsTargetG.toString());
    _fat = TextEditingController(text: widget.profile.fatTargetG.toString());
    _units = widget.profile.units;
  }

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = int.tryParse(_calories.text.trim()) ??
        widget.profile.dailyCalorieTarget;
    final protein = double.tryParse(_protein.text.trim()) ??
        widget.profile.proteinTargetG;
    final carbs =
        double.tryParse(_carbs.text.trim()) ?? widget.profile.carbsTargetG;
    final fat = double.tryParse(_fat.text.trim()) ?? widget.profile.fatTargetG;

    final updated = widget.profile.copyWith(
      dailyCalorieTarget: target,
      proteinTargetG: protein,
      carbsTargetG: carbs,
      fatTargetG: fat,
      units: _units,
    );

    await ref.read(profileProvider.notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Objetivos diarios',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          key: const Key('calorie-target-field'),
          controller: _calories,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Calorías', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('protein-target-field'),
          controller: _protein,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Proteína (g)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('carbs-target-field'),
          controller: _carbs,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Carbohidratos (g)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('fat-target-field'),
          controller: _fat,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Grasas (g)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        SegmentedButton<Units>(
          key: const Key('units-selector'),
          segments: const [
            ButtonSegment(value: Units.kg, label: Text('kg')),
            ButtonSegment(value: Units.lb, label: Text('lb')),
          ],
          selected: {_units},
          onSelectionChanged: (selection) =>
              setState(() => _units = selection.first),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('save-profile-button'),
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}