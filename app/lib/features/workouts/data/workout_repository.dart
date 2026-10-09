import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/exercise.dart';
import '../domain/workout_session.dart';

/// Repositorio de entrenamientos sobre las tablas `exercises`,
/// `workout_sessions` y `workout_sets`.
class WorkoutRepository {
  WorkoutRepository(this._client);

  final SupabaseClient _client;

  /// Ejercicios del catálogo común + los propios del usuario.
  Future<List<Exercise>> fetchExercises() async {
    final res = await _client.from('exercises').select().order('name');
    return (res as List)
        .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Crea un ejercicio propio del usuario.
  Future<Exercise> createExercise(String name, String muscleGroup) async {
    final row = <String, dynamic>{
      'name': name,
      'muscle_group': muscleGroup,
      'is_custom': true,
      'user_id': _client.auth.currentUser?.id,
    };
    final res = await _client.from('exercises').insert(row).select().single();
    return Exercise.fromMap(Map<String, dynamic>.from(res as Map));
  }

  /// Inserta la sesión **sin la clave anidada `sets`** y, después, cada serie
  /// con el `session_id` devuelto por la base de datos.
  Future<void> saveSession(WorkoutSession session) async {
    final row = session.toMap()..remove('sets');
    final res =
        await _client.from('workout_sessions').insert(row).select().single();
    final sessionId = (res as Map)['id'] as String;
    for (final set in session.sets) {
      await _client.from('workout_sets').insert({
        ...set.toMap(),
        'session_id': sessionId,
      });
    }
  }

  /// Sesiones (con sus series embebidas) en el rango de fechas, de más reciente
  /// a más antigua. Los filtros se aplican antes de `.order()` (que devuelve un
  /// `PostgrestTransformBuilder` sin métodos de filtro).
  Future<List<WorkoutSession>> fetchSessions({
    DateTime? from,
    DateTime? to,
  }) async {
    var query =
        _client.from('workout_sessions').select('*, workout_sets(*)');
    if (from != null) {
      query = query.gte('started_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lte('started_at', to.toUtc().toIso8601String());
    }
    final res = await query.order('started_at', ascending: false);
    return (res as List)
        .map((e) => WorkoutSession.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Sesiones donde aparece el ejercicio indicado, con sus series embebidas.
  Future<List<WorkoutSession>> fetchSessionsForExercise(
    String exerciseId,
  ) async {
    final res = await _client
        .from('workout_sessions')
        .select('*, workout_sets(*)')
        .eq('workout_sets.exercise_id', exerciseId)
        .order('started_at', ascending: false);
    return (res as List)
        .map((e) => WorkoutSession.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}