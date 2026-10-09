import 'package:fitness_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;
  late AuthRepository repo;

  setUp(() {
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    repo = AuthRepository(supabase);
    when(() => supabase.auth).thenReturn(auth);
  });

  group('signIn', () {
    test('exitoso no lanza', () async {
      when(() => auth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse());

      await repo.signIn(email: 'a@b.com', password: '123456');

      verify(() => auth.signInWithPassword(
            email: 'a@b.com',
            password: '123456',
          )).called(1);
    });

    test('error de credenciales propaga AuthException', () async {
      when(() => auth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      expect(
        () => repo.signIn(email: 'a@b.com', password: 'mala'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signUp', () {
    test('envía display_name en data', () async {
      when(() => auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => AuthResponse());

      await repo.signUp(
        email: 'a@b.com',
        password: 'pw',
        displayName: 'Jordi',
      );

      verify(() => auth.signUp(
            email: 'a@b.com',
            password: 'pw',
            data: {'display_name': 'Jordi'},
          )).called(1);
    });
  });

  group('signOut', () {
    test('llama a signOut del cliente', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});

      await repo.signOut();

      verify(() => auth.signOut()).called(1);
    });
  });

  group('currentUser / authStateChanges', () {
    test('expone el usuario actual', () {
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);

      expect(repo.currentUser, same(user));
    });

    test('expone el stream de cambios de estado', () async {
      when(() => auth.onAuthStateChange)
          .thenAnswer((_) => const Stream.empty());

      expect(await repo.authStateChanges.isEmpty, isTrue);
    });
  });
}