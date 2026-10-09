import 'package:flutter/material.dart';

import '../domain/food_item.dart';

/// Diálogo para introducir un alimento a mano. Devuelve el [FoodItem] creado
/// (o null si se cancela). Es un StatefulWidget para que los controllers de
/// texto se liberen de forma segura al cerrarse el diálogo.
class ManualFoodDialog extends StatefulWidget {
  const ManualFoodDialog({super.key});

  static Future<FoodItem?> show(BuildContext context) {
    return showDialog<FoodItem>(
      context: context,
      builder: (_) => const ManualFoodDialog(),
    );
  }

  @override
  State<ManualFoodDialog> createState() => _ManualFoodDialogState();
}

class _ManualFoodDialogState extends State<ManualFoodDialog> {
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _unit = TextEditingController(text: 'ración');
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir alimento a mano'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('manual-name'),
              controller: _name,
              decoration: _dec('Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('manual-quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: _dec('Cantidad'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('manual-unit'),
              controller: _unit,
              decoration: _dec('Unidad'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('manual-calories'),
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: _dec('Calorías'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('manual-protein'),
              controller: _protein,
              keyboardType: TextInputType.number,
              decoration: _dec('Proteína (g)'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('manual-carbs'),
              controller: _carbs,
              keyboardType: TextInputType.number,
              decoration: _dec('Carbos (g)'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('manual-fat'),
              controller: _fat,
              keyboardType: TextInputType.number,
              decoration: _dec('Grasa (g)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm-manual-item'),
          onPressed: () {
            Navigator.of(context).pop(FoodItem(
              name: _name.text.trim().isEmpty ? 'Alimento' : _name.text.trim(),
              quantity: double.tryParse(_quantity.text.trim()) ?? 1,
              unit: _unit.text.trim().isEmpty ? 'ración' : _unit.text.trim(),
              calories: int.tryParse(_calories.text.trim()) ?? 0,
              proteinG: double.tryParse(_protein.text.trim()) ?? 0,
              carbsG: double.tryParse(_carbs.text.trim()) ?? 0,
              fatG: double.tryParse(_fat.text.trim()) ?? 0,
              estimated: true,
            ));
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}