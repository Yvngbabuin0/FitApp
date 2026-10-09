import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/food_item.dart';

/// Cliente de la Edge Function `analyze-meal` (cloudflare workers ai).
/// Comprime la foto, la envía en base64 y devuelve los alimentos detectados.
class MealAnalysisService {
  MealAnalysisService(this._client);

  final SupabaseClient _client;

  static const int _maxDimension = 1024;

  /// Comprime [imageBytes] a ≤1024 px (JPEG) y llama a la función de análisis.
  /// Devuelve lista vacía (sin lanzar) si la función no detecta alimentos o
  /// falla la llamada.
  Future<List<FoodItem>> analyze(Uint8List imageBytes, {String? hint}) async {
    try {
      final jpeg = _compress(imageBytes);
      final body = <String, dynamic>{
        'image': base64Encode(jpeg),
        if (hint != null && hint.trim().isNotEmpty) 'hint': hint.trim(),
      };
      final res = await _client.functions.invoke('analyze-meal', body: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) {
          return items
              .map((e) => FoodItem.fromAnalysisJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Redimensiona manteniendo la proporción (máximo [_maxDimension] px en el
  /// lado mayor) y codifica en JPEG. Si no se puede decodificar, devuelve los
  /// bytes originales.
  Uint8List _compress(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= _maxDimension) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
    }

    final scale = _maxDimension / longest;
    final resized = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}