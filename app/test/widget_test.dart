import 'package:fitness_app/app.dart';
import 'package:fitness_app/features/auth/application/auth_controller.dart';
import 'package:fitness_app/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('la app sin sesión redirige a LoginScreen', (tester) async {
    final repo = MockAuthRepository();
    when(() => repo.currentUser).thenReturn(null);
    when(() => repo.authStateChanges)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const FitnessApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect(find.text('Email o contraseña incorrectos'), findsNothing);
  });
}