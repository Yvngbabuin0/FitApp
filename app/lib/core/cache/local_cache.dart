import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast_io.dart';

/// Caché local basado en sembast (archivo en disco). Se usa para lecturas
/// rápidas sin red (p. ej. preferencias o últimos datos vistos).
class LocalCache {
  LocalCache._(this._db);

  final Database _db;

  static const _storeName = 'app-cache';

  StoreRef<int, Map<String, Object?>> get _store =>
      intMapStoreFactory.store(_storeName);

  /// Abre (o crea) la base de datos de caché dentro de [path].
  static Future<LocalCache> open({String? path}) async {
    final dir = Directory(path ?? '${Directory.systemTemp.path}/fitness_cache');
    await dir.create(recursive: true);
    final db =
        await databaseFactoryIo.openDatabase('${dir.path}/local_cache.db');
    return LocalCache._(db);
  }

  /// Guarda [value] bajo [key] (sobreescribe si ya existe).
  Future<void> put(String key, Object value) async {
    final existing = await _store.findFirst(
      _db,
      finder: Finder(filter: Filter.equals('key', key)),
    );
    if (existing == null) {
      await _store.add(_db, {'key': key, 'value': value});
    } else {
      await _store.update(
        _db,
        {'value': value},
        finder: Finder(filter: Filter.equals('key', key)),
      );
    }
  }

  /// Devuelve el valor guardado bajo [key], o null si no existe.
  Future<Object?> get(String key) async {
    final record = await _store.findFirst(
      _db,
      finder: Finder(filter: Filter.equals('key', key)),
    );
    return record?['value'];
  }

  /// Elimina todos los valores de la caché.
  Future<void> clear() async {
    await _store.delete(_db);
  }

  Future<void> close() => _db.close();
}

/// Caché abierta de forma perezosa (solo se crea el archivo al leerse).
final localCacheProvider = FutureProvider<LocalCache>((ref) {
  return LocalCache.open();
});