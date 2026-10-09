import 'dart:convert';
import 'dart:typed_data';

import 'package:fitness_app/features/food/data/meal_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

  late List<http.Request> requests;
  late Map<String, dynamic> functionResponse;
  late MealAnalysisService service;

  setUp(() {
    requests = [];
    functionResponse = {'items': []};
    final mock = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST' &&
          request.url.path.endsWith('/analyze-meal')) {
        return http.Response(
          jsonEncode(functionResponse),
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

    final client = SupabaseClient(
      'https://test.supabase.co',
      'test-anon-key',
      httpClient: mock,
    );
    service = MealAnalysisService(client);
  });

  Uint8List makeImage(int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(120, 180, 90));
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  test('función sin items → lista vacía sin lanzar', () async {
    final result = await service.analyze(makeImage(800, 600));

    expect(result, isEmpty);
    expect(requests, hasLength(1));
  });

  test('función con items → FoodItems mapeados', () async {
    functionResponse = {
      'items': [
        {
          'name': 'Pollo a la plancha',
          'quantity': 150,
          'unit': 'g',
          'calories': 220,
          'protein_g': 30,
          'carbs_g': 0,
          'fat_g': 10,
          'confidence': 0.92,
          'estimated': false,
        },
        {
          'name': 'Arroz blanco',
          'quantity': 200,
          'unit': 'g',
          'calories': 260,
          'protein_g': 5,
          'carbs_g': 57,
          'fat_g': 1,
        },
      ]
    };

    final result = await service.analyze(makeImage(800, 600), hint: 'almuerzo');

    expect(result, hasLength(2));
    expect(result.first.name, 'Pollo a la plancha');
    expect(result.first.calories, 220);
    expect(result.first.confidence, 0.92);
    expect(result.first.estimated, isFalse);
    expect(result.last.name, 'Arroz blanco');

    final req = requests.single;
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['hint'], 'almuerzo');
    final jpeg = base64Decode(body['image'] as String);
    final decoded = img.decodeImage(jpeg);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(1024));
    expect(decoded.height, lessThanOrEqualTo(1024));
  });

  test('imagen grande se comprime a ≤1024 px', () async {
    final result = await service.analyze(makeImage(2000, 1200));

    expect(result, isEmpty);

    final req = requests.single;
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    final jpeg = base64Decode(body['image'] as String);
    final decoded = img.decodeImage(jpeg);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(1024));
    expect(decoded.height, lessThanOrEqualTo(1024));
  });
}