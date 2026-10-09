import 'dart:convert';

import 'package:fitness_app/features/food/data/food_repository.dart';
import 'package:fitness_app/features/food/domain/food_entry.dart';
import 'package:fitness_app/features/food/domain/food_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

  late List<http.Request> requests;
  late SupabaseClient client;
  late FoodRepository repo;

  setUp(() {
    requests = [];
    final mock = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;

      if (request.method == 'POST' && path.endsWith('/food_entries')) {
        // insert().select().single() → objeto con el id asignado.
        return http.Response(
          jsonEncode({
            'id': 'entry-1',
            'user_id': 'u-1',
            'logged_at': '2026-10-08T12:00:00.000Z',
            'meal_type': 'lunch',
            'total_calories': 480,
            'total_protein_g': 35,
            'total_carbs_g': 57,
            'total_fat_g': 11,
            'photo_path': null,
            'source': 'ai',
          }),
          201,
          headers: jsonHeaders,
          request: request,
        );
      }

      if (request.method == 'POST' && path.endsWith('/food_entry_items')) {
        return http.Response(
          jsonEncode([]),
          201,
          headers: jsonHeaders,
          request: request,
        );
      }

      if (request.method == 'GET' && path.endsWith('/food_entries')) {
        return http.Response(
          jsonEncode([
            {
              'id': 'entry-1',
              'user_id': 'u-1',
              'logged_at': '2026-10-08T12:00:00.000Z',
              'meal_type': 'lunch',
              'total_calories': 480,
              'total_protein_g': 35,
              'total_carbs_g': 57,
              'total_fat_g': 11,
              'photo_path': null,
              'source': 'ai',
              'items': [
                {
                  'name': 'Pollo',
                  'quantity': 150,
                  'unit': 'g',
                  'calories': 220,
                  'protein_g': 30,
                  'carbs_g': 0,
                  'fat_g': 10,
                  'confidence': 0.9,
                  'estimated': false,
                },
              ],
            }
          ]),
          200,
          headers: jsonHeaders,
          request: request,
        );
      }

      if (request.method == 'DELETE' && path.endsWith('/food_entries')) {
        return http.Response('', 204, request: request);
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
    repo = FoodRepository(client);
  });

  group('saveEntry', () {
    test('inserta la entrada SIN items y luego cada alimento', () async {
      final entry = FoodEntry(
        userId: 'u-1',
        loggedAt: DateTime.utc(2026, 10, 8, 12),
        mealType: MealType.lunch,
        source: FoodSource.ai,
        items: const [
          FoodItem(
            name: 'Pollo',
            quantity: 150,
            unit: 'g',
            calories: 220,
            proteinG: 30,
            carbsG: 0,
            fatG: 10,
            confidence: 0.9,
            estimated: false,
          ),
          FoodItem(
            name: 'Arroz',
            quantity: 200,
            unit: 'g',
            calories: 260,
            proteinG: 5,
            carbsG: 57,
            fatG: 1,
          ),
        ],
      );

      await repo.saveEntry(entry);

      final posts = requests.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(3)); // 1 entrada + 2 alimentos

      final entryPost = posts.first;
      expect(entryPost.url.path, endsWith('/food_entries'));
      final entryBody = jsonDecode(entryPost.body) as Map<String, dynamic>;
      expect(entryBody, isNot(contains('items')));
      expect(entryBody['user_id'], 'u-1');
      expect(entryBody['meal_type'], 'lunch');
      expect(entryBody['source'], 'ai');
      expect(entryBody['total_calories'], 480);
      expect(entryBody['logged_at'], isNotEmpty);

      for (final itemPost in posts.skip(1)) {
        expect(itemPost.url.path, endsWith('/food_entry_items'));
        final itemBody = jsonDecode(itemPost.body) as Map<String, dynamic>;
        expect(itemBody['food_entry_id'], 'entry-1');
        expect(itemBody.containsKey('name'), isTrue);
        expect(itemBody.containsKey('calories'), isTrue);
      }
    });
  });

  group('fetchEntries', () {
    test('filtra por rango de fechas y parsea items anidados', () async {
      final entries = await repo.fetchEntries(
        from: DateTime.utc(2026, 10, 1),
        to: DateTime.utc(2026, 10, 8, 23, 59),
      );

      expect(entries, hasLength(1));
      expect(entries.first.items, hasLength(1));
      expect(entries.first.items.first.name, 'Pollo');
      expect(entries.first.totalCalories, 220);

      final get = requests.firstWhere((r) =>
          r.method == 'GET' && r.url.path.endsWith('/food_entries'));
      final loggedAt = get.url.queryParametersAll['logged_at'];
      expect(loggedAt, contains('gte.2026-10-01T00:00:00.000Z'));
      expect(loggedAt, contains('lte.2026-10-08T23:59:00.000Z'));
      expect(get.url.queryParameters['select'], contains('food_entry_items'));
    });
  });

  group('deleteEntry', () {
    test('borra la entrada por id', () async {
      await repo.deleteEntry('entry-1');

      final del = requests.firstWhere((r) => r.method == 'DELETE');
      expect(del.url.path, endsWith('/food_entries'));
      expect(del.url.queryParameters['id'], 'eq.entry-1');
    });
  });
}