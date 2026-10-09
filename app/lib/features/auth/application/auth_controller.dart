import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Repositorio de auth. En producción se sobrescribe en `main.dart` con el
/// cliente real de Supabase; en los tests, se sobrescribe con un mock.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
      'authRepositoryProvider debe sobrescribirse en main.dart o en tests');
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// Estado de las operaciones de autenticación (`AsyncValue<void>`).
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(authRepositoryProvider).signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider)
        .signUp(email: email, password: password, displayName: displayName));
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }
}