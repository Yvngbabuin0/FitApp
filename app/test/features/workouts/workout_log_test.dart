import 'package:fitness_app/features/workouts/application/workout_controller.dart';
import 'package:fitness_app/features/workouts/data/workout_repository.dart';
import 'package:fitness_app/features/workouts/domain/exercise.dart';
import 'package:fitness_app/features/workouts/presentation/workout_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late MockWorkoutRepository repo;

  setUp(() {
    repo = MockWorkoutRepository();
    when(() => repo.fetchExercises()).thenAnswer((_) async => [
          const Exercise(
            id: 'ex-1',
            userId: 'u-1',
            name: 'Press banca',
            muscleGroup: 'Pecho',
            isCustom: false,
          ),
        ]);
  });

  Future<void> pumpLog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: WorkoutLogScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('estado vacío sin series: volumen 0', (tester) async {
    await pumpLog(tester);

    expect(find.textContaining('Volumen: 0'), findsOneWidget);
    expect(find.textContaining('Sin series'), findsOneWidget);
  });

  testWidgets('añadir una serie 5×100 muestra volumen 500', (tester) async {
    await pumpLog(tester);

    await tester.tap(find.byKey(const Key('add-set-button')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('reps-field-0')), '5');
    await tester.enterText(find.byKey(const Key('weight-field-0')), '100');
    await tester.pump();

    expect(find.textContaining('500'), findsOneWidget);
    expect(find.textContaining('Volumen: 0'), findsNothing);
  });
}