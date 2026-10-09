import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/food_controller.dart';
import '../domain/food_entry.dart';
import '../domain/food_item.dart';
import 'manual_food_dialog.dart';

const _mealLabels = {
  MealType.breakfast: 'Desayuno',
  MealType.lunch: 'Comida',
  MealType.dinner: 'Cena',
  MealType.snack: 'Snack',
};

/// Revisión de los alimentos detectados por la IA: editable, con totales,
/// selector de tipo de comida y guardado.
class FoodReviewScreen extends ConsumerStatefulWidget {
  const FoodReviewScreen({super.key, this.initialItems = const []});

  final List<FoodItem> initialItems;

  @override
  ConsumerState<FoodReviewScreen> createState() => _FoodReviewScreenState();
}

class _FoodReviewScreenState extends ConsumerState<FoodReviewScreen> {
  late final List<FoodItem> _items;
  MealType _mealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialItems);
  }

  int get _calories => _items.fold(0, (sum, item) => sum + item.calories);

  double get _protein => _items.fold(0.0, (sum, item) => sum + item.proteinG);

  double get _carbs => _items.fold(0.0, (sum, item) => sum + item.carbsG);

  double get _fat => _items.fold(0.0, (sum, item) => sum + item.fatG);

  Future<void> _addManual() async {
    final item = await ManualFoodDialog.show(context);
    if (item != null) {
      setState(() => _items.add(item));
    }
  }

  Future<void> _save() async {
    final entry = FoodEntry(
      userId: ref.read(authRepositoryProvider).currentUser?.id ?? '',
      loggedAt: DateTime.now(),
      mealType: _mealType,
      items: List.unmodifiable(_items),
      source: FoodSource.ai,
    );
    await ref.read(foodControllerProvider.notifier).saveEntry(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comida registrada')),
    );
    context.go('/food');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar comida')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<MealType>(
            key: const Key('meal-type-dropdown'),
            initialValue: _mealType,
            decoration: const InputDecoration(
              labelText: 'Tipo de comida',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final type in MealType.values)
                DropdownMenuItem(value: type, child: Text(_mealLabels[type]!)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _mealType = value);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Calorías: $_calories kcal · Proteína: ${_protein.toStringAsFixed(0)} g'
            ' · Carbos: ${_carbs.toStringAsFixed(0)} g'
            ' · Grasa: ${_fat.toStringAsFixed(0)} g',
            key: const Key('totals-label'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No se detectaron alimentos. Añádelos a mano o '
                  'vuelve a intentarlo.'),
            )
          else
            for (var i = 0; i < _items.length; i++)
              _ItemRow(
                index: i,
                item: _items[i],
                onChanged: (item) => setState(() => _items[i] = item),
                onDelete: () => setState(() => _items.removeAt(i)),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('add-manual-item-button'),
            onPressed: _addManual,
            icon: const Icon(Icons.add),
            label: const Text('Añadir a mano'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('save-food-button'),
            onPressed: _items.isEmpty ? null : _save,
            child: const Text('Guardar comida'),
          ),
        ],
      ),
    );
  }
}

/// Serie editable de un alimento detectado.
class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final FoodItem item;
  final ValueChanged<FoodItem> onChanged;
  final VoidCallback onDelete;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _quantity = TextEditingController(text: widget.item.quantity.toString());
  late final _calories = TextEditingController(text: widget.item.calories.toString());
  late final _protein = TextEditingController(text: widget.item.proteinG.toString());
  late final _carbs = TextEditingController(text: widget.item.carbsG.toString());
  late final _fat = TextEditingController(text: widget.item.fatG.toString());

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(widget.item.copyWith(
      name: _name.text.trim(),
      quantity: double.tryParse(_quantity.text.trim()) ?? widget.item.quantity,
      calories: int.tryParse(_calories.text.trim()) ?? 0,
      proteinG: double.tryParse(_protein.text.trim()) ?? 0,
      carbsG: double.tryParse(_carbs.text.trim()) ?? 0,
      fatG: double.tryParse(_fat.text.trim()) ?? 0,
    ));
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('name-field-${widget.index}'),
                    controller: _name,
                    onChanged: (_) => _update(),
                    decoration: _dec('Nombre'),
                  ),
                ),
                IconButton(
                  key: Key('delete-item-${widget.index}'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: Key('quantity-field-${widget.index}'),
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                    decoration: _dec('Cantidad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('calories-field-${widget.index}'),
                    controller: _calories,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                    decoration: _dec('Calorías'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('protein-field-${widget.index}'),
                    controller: _protein,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _update(),
                    decoration: _dec('Prot (g)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}