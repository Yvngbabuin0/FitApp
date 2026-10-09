import 'package:fitness_app/features/food/domain/food_entry.dart';
import 'package:fitness_app/features/food/domain/food_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodItem.fromAnalysisJson', () {
    test('parsea el JSON de la Edge Function', () {
      final json = <String, dynamic>{
        'name': 'Pollo a la plancha',
        'quantity': 150.0,
        'unit': 'g',
        'calories': 248,
        'protein_g': 46.5,
        'carbs_g': 0,
        'fat_g': 5.4,
        'confidence': 0.82,
        'estimated': false,
      };

      final item = FoodItem.fromAnalysisJson(json);

      expect(item.name, 'Pollo a la plancha');
      expect(item.quantity, 150.0);
      expect(item.unit, 'g');
      expect(item.calories, 248);
      expect(item.proteinG, 46.5);
      expect(item.carbsG, 0.0);
      expect(item.fatG, 5.4);
      expect(item.confidence, 0.82);
      expect(item.estimated, isFalse);
    });

    test('valores ausentes usan valores por defecto seguros', () {
      final item = FoodItem.fromAnalysisJson(<String, dynamic>{'name': 'Algo'});

      expect(item.name, 'Algo');
      expect(item.quantity, 0);
      expect(item.unit, 'g');
      expect(item.calories, 0);
      expect(item.proteinG, 0);
      expect(item.carbsG, 0);
      expect(item.fatG, 0);
      expect(item.confidence, isNull);
      expect(item.estimated, isTrue);
    });
  });

  group('FoodItem toMap/fromMap', () {
    test('round-trip', () {
      const item = FoodItem(
        name: 'Arroz',
        quantity: 200,
        unit: 'g',
        calories: 260,
        proteinG: 5,
        carbsG: 56,
        fatG: 0.6,
        confidence: 0.5,
        estimated: true,
      );

      final back = FoodItem.fromMap(item.toMap());

      expect(back.name, 'Arroz');
      expect(back.quantity, 200);
      expect(back.calories, 260);
      expect(back.proteinG, 5);
      expect(back.carbsG, 56);
      expect(back.fatG, 0.6);
      expect(back.confidence, 0.5);
      expect(back.estimated, isTrue);
    });
  });

  group('FoodEntry totales', () {
    test('lista vacía → totales 0', () {
      final entry = FoodEntry(
        userId: 'u-1',
        loggedAt: DateTime(2026, 10, 8, 13),
        mealType: MealType.lunch,
        items: const [],
        source: FoodSource.manual,
      );

      expect(entry.totalCalories, 0);
      expect(entry.totalProteinG, 0);
      expect(entry.totalCarbsG, 0);
      expect(entry.totalFatG, 0);
    });

    test('suma los totales de los items', () {
      final entry = FoodEntry(
        userId: 'u-1',
        loggedAt: DateTime(2026, 10, 8, 13),
        mealType: MealType.lunch,
        items: const [
          FoodItem(
            name: 'a',
            quantity: 100,
            unit: 'g',
            calories: 100,
            proteinG: 10,
            carbsG: 5,
            fatG: 2,
          ),
          FoodItem(
            name: 'b',
            quantity: 100,
            unit: 'g',
            calories: 50,
            proteinG: 5,
            carbsG: 2,
            fatG: 1,
          ),
        ],
        source: FoodSource.ai,
      );

      expect(entry.totalCalories, 150);
      expect(entry.totalProteinG, 15);
      expect(entry.totalCarbsG, 7);
      expect(entry.totalFatG, 3);
    });
  });

  group('FoodEntry toMap/fromMap', () {
    test('round-trip incluye items y enums', () {
      final entry = FoodEntry(
        id: 'entry-1',
        userId: 'u-1',
        loggedAt: DateTime(2026, 10, 8, 13, 30),
        mealType: MealType.dinner,
        items: const [
          FoodItem(
            name: 'Salmón',
            quantity: 120,
            unit: 'g',
            calories: 208,
            proteinG: 20,
            carbsG: 0,
            fatG: 13,
          ),
        ],
        photoPath: 'u-1/photo.jpg',
        source: FoodSource.ai,
      );

      final back = FoodEntry.fromMap(entry.toMap());

      expect(back.id, 'entry-1');
      expect(back.mealType, MealType.dinner);
      expect(back.source, FoodSource.ai);
      expect(back.photoPath, 'u-1/photo.jpg');
      expect(back.items.length, 1);
      expect(back.totalCalories, 208);
    });
  });
}
