import 'package:fitness_app/features/auth/application/auth_controller.dart';
import 'package:fitness_app/features/auth/data/auth_repository.dart';
import 'package:fitness_app/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('Entrar con éxito no muestra error y llama a signIn', (tester) async {
    final repo = MockAuthRepository();
    when(() => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byKey(const Key('email-field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password-field')), '123456');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Email o contraseña incorrectos'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    verify(() => repo.signIn(email: 'a@b.com', password: '123456')).called(1);
  });

  testWidgets('Fallo de credenciales muestra el mensaje de error', (tester) async {
    final repo = MockAuthRepository();
    when(() => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(AuthException('Invalid login credentials'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byKey(const Key('email-field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'mala');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Email o contraseña incorrectos'), findsOneWidget);
  });
}