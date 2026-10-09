import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/food_entry.dart';

/// Repositorio de comidas sobre las tablas `food_entries` y
/// `food_entry_items`.
class FoodRepository {
  FoodRepository(this._client);

  final SupabaseClient _client;

  /// Inserta la entrada **sin la clave anidada `items`** y, después, cada
  /// alimento con el `food_entry_id` devuelto por la base de datos.
  Future<void> saveEntry(FoodEntry entry) async {
    final row = entry.toMap()..remove('items');
    final res =
        await _client.from('food_entries').insert(row).select().single();
    final entryId = (res as Map)['id'] as String;
    for (final item in entry.items) {
      await _client.from('food_entry_items').insert({
        ...item.toMap(),
        'food_entry_id': entryId,
      });
    }
  }

  /// Entradas (con sus alimentos embebidos bajo `items`) en el rango de
  /// fechas, de más reciente a más antigua.
  Future<List<FoodEntry>> fetchEntries({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('food_entries')
        .select('*, items:food_entry_items(*)');
    if (from != null) {
      query = query.gte('logged_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lte('logged_at', to.toUtc().toIso8601String());
    }
    final res = await query.order('logged_at', ascending: false);
    return (res as List)
        .map((e) => FoodEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('food_entries').delete().eq('id', id);
  }
}