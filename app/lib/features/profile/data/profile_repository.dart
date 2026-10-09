import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

/// Repositorio de perfil sobre la tabla `profiles` de Supabase.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> fetch(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromMap(Map<String, dynamic>.from(res as Map));
  }

  Future<void> update(Profile profile) async {
    final row = profile.toMap()..remove('id');
    await _client.from('profiles').update(row).eq('id', profile.id);
  }
}