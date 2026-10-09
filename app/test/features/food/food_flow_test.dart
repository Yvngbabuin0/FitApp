import 'package:fitness_app/features/food/application/food_controller.dart';
import 'package:fitness_app/features/food/data/food_repository.dart';
import 'package:fitness_app/features/food/domain/food_entry.dart';
import 'package:fitness_app/features/food/domain/food_item.dart';
import 'package:fitness_app/features/food/presentation/daily_log_screen.dart';
import 'package:fitness_app/features/food/presentation/food_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

void main() {
  late MockFoodRepository repo;

  setUp(() {
    repo = MockFoodRepository();
  });

  testWidgets('revisión: análisis simulado muestra items editables y totales',
      (tester) async {
    const items = [
      FoodItem(
        name: 'Pollo',
        quantity: 150,
        unit: 'g',
        calories: 220,
        proteinG: 30,
        carbsG: 0,
        fatG: 10,
        confidence: 0.9,
        estimated: false,
      ),
      FoodItem(
        name: 'Arroz',
        quantity: 200,
        unit: 'g',
        calories: 260,
        proteinG: 5,
        carbsG: 57,
        fatG: 1,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: FoodReviewScreen(initialItems: items)),
      ),
    );

    expect(find.text('Pollo'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.textContaining('480'), findsOneWidget);

    // Editar las calorías del primer item → los totales se recalculan.
    await tester.enterText(find.byKey(const Key('calories-field-0')), '300');
    await tester.pump();

    expect(find.textContaining('560'), findsOneWidget);
  });

  testWidgets('revisión: análisis vacío avisa y permite añadir a mano',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: FoodReviewScreen(initialItems: [])),
      ),
    );

    expect(find.textContaining('No se detectaron alimentos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-manual-item-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('manual-name')), 'Yogur');
    await tester.enterText(find.byKey(const Key('manual-calories')), '120');
    await tester.tap(find.byKey(const Key('confirm-manual-item')));
    await tester.pumpAndSettle();

    expect(find.text('Yogur'), findsOneWidget);
    expect(find.textContaining('120'), findsWidgets);
  });

  testWidgets('diario vacío: totales 0', (tester) async {
    when(() => repo.fetchEntries(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => const <FoodEntry>[]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: DailyLogScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Calorías: 0'), findsOneWidget);
    expect(find.textContaining('Sin comidas'), findsOneWidget);
  });
}