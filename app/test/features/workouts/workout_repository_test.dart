import 'dart:convert';

import 'package:fitness_app/features/workouts/data/workout_repository.dart';
import 'package:fitness_app/features/workouts/domain/workout_session.dart';
import 'package:fitness_app/features/workouts/domain/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

  late List<http.Request> requests;
  late SupabaseClient client;
  late WorkoutRepository repo;

  setUp(() {
    requests = [];
    final mock = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;

      if (request.method == 'POST' && path.endsWith('/workout_sessions')) {
        // insert().select().single() → objeto único con el id asignado.
        return http.Response(
          jsonEncode({
            'id': 'sess-1',
            'user_id': 'u-1',
            'started_at': '2026-10-08T10:00:00.000Z',
            'ended_at': null,
            'notes': null,
          }),
          201,
          headers: jsonHeaders,
          request: request,
        );
      }

      if (request.method == 'POST' && path.endsWith('/workout_sets')) {
        return http.Response(
          jsonEncode([]),
          201,
          headers: jsonHeaders,
          request: request,
        );
      }

      if (request.method == 'GET' && path.endsWith('/workout_sessions')) {
        return http.Response(
          jsonEncode([
            {
              'id': 'sess-1',
              'user_id': 'u-1',
              'started_at': '2026-10-08T10:00:00.000Z',
              'ended_at': null,
              'notes': null,
              'workout_sets': [
                {
                  'id': 'set-1',
                  'session_id': 'sess-1',
                  'exercise_id': 'ex-1',
                  'set_index': 0,
                  'reps': 5,
                  'weight': 100,
                  'rpe': null,
                  'completed': true,
                },
              ],
            }
          ]),
          200,
          headers: jsonHeaders,
          request: request,
        );
      }

      if (request.method == 'GET' && path.endsWith('/exercises')) {
        return http.Response(
          jsonEncode([
            {
              'id': 'ex-1',
              'user_id': 'u-1',
              'name': 'Press banca',
              'muscle_group': 'Pecho',
              'is_custom': false,
            }
          ]),
          200,
          headers: jsonHeaders,
          request: request,
        );
      }

      return http.Response(
        jsonEncode({'error': 'not found'}),
        404,
        headers: jsonHeaders,
        request: request,
      );
    });

    client = SupabaseClient(
      'https://test.supabase.co',
      'test-anon-key',
      httpClient: mock,
    );
    repo = WorkoutRepository(client);
  });

  group('saveSession', () {
    test('inserta la sesión SIN la clave sets y luego cada serie', () async {
      final session = WorkoutSession(
        userId: 'u-1',
        startedAt: DateTime.utc(2026, 10, 8, 10),
        sets: [
          WorkoutSet(
            exerciseId: 'ex-1',
            setIndex: 0,
            reps: 5,
            weight: 100,
            completed: true,
          ),
          WorkoutSet(
            exerciseId: 'ex-1',
            setIndex: 1,
            reps: 5,
            weight: 105,
            completed: true,
          ),
        ],
      );

      await repo.saveSession(session);

      final posts = requests.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(3)); // 1 sesión + 2 series

      final sessionPost = posts.first;
      expect(sessionPost.url.path, endsWith('/workout_sessions'));
      final sessionBody =
          jsonDecode(sessionPost.body) as Map<String, dynamic>;
      expect(sessionBody, isNot(contains('sets')));
      expect(sessionBody['user_id'], 'u-1');
      expect(sessionBody['started_at'], isNotEmpty);

      for (final setPost in posts.skip(1)) {
        expect(setPost.url.path, endsWith('/workout_sets'));
        final setBody = jsonDecode(setPost.body) as Map<String, dynamic>;
        expect(setBody['session_id'], 'sess-1');
        expect(setBody['exercise_id'], 'ex-1');
        expect(setBody.containsKey('reps'), isTrue);
        expect(setBody.containsKey('weight'), isTrue);
      }
    });
  });

  group('fetchSessions', () {
    test('filtra por rango de fechas y parsea las series anidadas', () async {
      final sessions = await repo.fetchSessions(
        from: DateTime.utc(2026, 10, 1),
        to: DateTime.utc(2026, 10, 8, 23, 59),
      );

      expect(sessions, hasLength(1));
      expect(sessions.first.sets, hasLength(1));
      expect(sessions.first.sets.first.reps, 5);
      expect(sessions.first.sets.first.weight, 100);

      final get = requests.firstWhere((r) =>
          r.method == 'GET' && r.url.path.endsWith('/workout_sessions'));
      final startedAt = get.url.queryParametersAll['started_at'];
      expect(startedAt, isNotNull);
      expect(startedAt, contains('gte.2026-10-01T00:00:00.000Z'));
      expect(startedAt, contains('lte.2026-10-08T23:59:00.000Z'));
      expect(get.url.queryParameters['select'], contains('workout_sets'));
    });
  });

  group('fetchExercises', () {
    test('devuelve los ejercicios del catálogo y propios', () async {
      final exercises = await repo.fetchExercises();

      expect(exercises, hasLength(1));
      expect(exercises.first.name, 'Press banca');
      expect(exercises.first.isCustom, isFalse);
    });
  });
}