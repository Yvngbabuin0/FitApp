import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../application/food_controller.dart';
import '../domain/food_entry.dart';
import 'manual_food_dialog.dart';

const _mealLabels = {
  MealType.breakfast: 'Desayuno',
  MealType.lunch: 'Comida',
  MealType.dinner: 'Cena',
  MealType.snack: 'Snack',
};

/// Diario de comidas del día: entradas, totales y alta manual.
class DailyLogScreen extends ConsumerWidget {
  const DailyLogScreen({super.key});

  Future<void> _addManual(BuildContext context, WidgetRef ref) async {
    final item = await ManualFoodDialog.show(context);
    if (item == null) return;

    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    await ref
        .read(foodControllerProvider.notifier)
        .saveEntry(FoodEntry(
          userId: userId,
          loggedAt: DateTime.now(),
          mealType: MealType.snack,
          items: [item],
          source: FoodSource.manual,
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(foodControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diario de hoy')),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudieron cargar las comidas.\n$error',
              textAlign: TextAlign.center),
        ),
        data: (entries) => _buildContent(context, ref, entries),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<FoodEntry> entries) {
    final theme = Theme.of(context);
    final calories = entries.fold<int>(0, (s, e) => s + e.totalCalories);
    final protein = entries.fold<double>(0, (s, e) => s + e.totalProteinG);
    final carbs = entries.fold<double>(0, (s, e) => s + e.totalCarbsG);
    final fat = entries.fold<double>(0, (s, e) => s + e.totalFatG);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calorías: $calories kcal',
                    key: const Key('totals-calories'),
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Proteína: ${protein.toStringAsFixed(0)} g'
                  ' · Carbos: ${carbs.toStringAsFixed(0)} g'
                  ' · Grasa: ${fat.toStringAsFixed(0)} g',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Sin comidas registradas hoy'),
          )
        else
          for (final entry in entries)
            ListTile(
              key: Key('entry-${entry.id}'),
              leading: const Icon(Icons.restaurant),
              title: Text(_mealLabels[entry.mealType] ?? entry.mealType.name),
              subtitle: Text(
                entry.items.map((item) => item.name).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: entry.id == null
                    ? null
                    : () => ref
                        .read(foodControllerProvider.notifier)
                        .deleteEntry(entry.id!),
              ),
            ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('add-manual-entry-button'),
          onPressed: () => _addManual(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Añadir comida a mano'),
        ),
      ],
    );
  }
}