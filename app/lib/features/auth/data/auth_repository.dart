import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositorio de autenticación que delega en el cliente de Supabase.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}