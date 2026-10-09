import 'package:fitness_app/features/progress/application/progress_controller.dart';
import 'package:fitness_app/features/progress/data/progress_repository.dart';
import 'package:fitness_app/features/progress/domain/weekly_summary.dart';
import 'package:fitness_app/features/progress/presentation/weekly_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late MockProgressRepository repo;

  setUp(() {
    repo = MockProgressRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: WeeklySummaryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  WeeklySummary summary({
    required double volume,
    required int sessions,
    required int newPrs,
    required double calories,
    required double protein,
    required double adherence,
  }) =>
      WeeklySummary(
        weekStart: DateTime(2026, 10, 5),
        volume: volume,
        sessions: sessions,
        newPrs: newPrs,
        avgCalories: calories,
        avgProteinG: protein,
        avgCarbsG: 0,
        avgFatG: 0,
        adherence: adherence,
      );

  testWidgets('con datos de dos semanas muestra deltas con flechas ▲ y ▼',
      (tester) async {
    when(
      () => repo.fetchWeeklyComparison(weekStart: any(named: 'weekStart')),
    ).thenAnswer(
      (_) async => WeeklyComparison(
        current:
            summary(volume: 2000, sessions: 3, newPrs: 1, calories: 1800, protein: 120, adherence: 0.57),
        previous:
            summary(volume: 2500, sessions: 1, newPrs: 0, calories: 1500, protein: 90, adherence: 0.29),
      ),
    );

    await pumpScreen(tester);

    expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    expect(find.byIcon(Icons.arrow_downward), findsWidgets);
    expect(find.text('Volumen'), findsOneWidget);
    expect(find.text('Sesiones'), findsOneWidget);
    expect(find.text('PRs'), findsOneWidget);
    expect(find.text('Adherencia'), findsOneWidget);
  });

  testWidgets('usuario nuevo sin datos → estado vacío', (tester) async {
    when(
      () => repo.fetchWeeklyComparison(weekStart: any(named: 'weekStart')),
    ).thenAnswer(
      (_) async => WeeklyComparison(
        current:
            summary(volume: 0, sessions: 0, newPrs: 0, calories: 0, protein: 0, adherence: 0),
        previous:
            summary(volume: 0, sessions: 0, newPrs: 0, calories: 0, protein: 0, adherence: 0),
      ),
    );

    await pumpScreen(tester);

    expect(find.textContaining('Aún no hay datos'), findsOneWidget);
  });
}