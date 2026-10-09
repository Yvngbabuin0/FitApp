import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

/// Repositorio de perfil. En producción se sobrescribe con el cliente real de
/// Supabase; en tests, con un mock.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError(
      'profileRepositoryProvider debe sobrescribirse en main.dart o en tests');
});

final profileProvider =
    AsyncNotifierProvider<ProfileController, Profile>(ProfileController.new);

class ProfileController extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() async {
    final auth = ref.watch(authRepositoryProvider);
    final userId = auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay usuario autenticado');
    }
    return ref.read(profileRepositoryProvider).fetch(userId);
  }

  Future<void> save(Profile profile) async {
    await ref.read(profileRepositoryProvider).update(profile);
    state = AsyncData(profile);
  }
}