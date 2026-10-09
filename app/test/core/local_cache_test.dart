import 'dart:io';

import 'package:fitness_app/core/cache/local_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late LocalCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('local_cache_test');
    cache = await LocalCache.open(path: dir.path);
  });

  tearDown(() async {
    await cache.close();
    await dir.delete(recursive: true);
  });

  test('put y get devuelven el valor guardado', () async {
    await cache.put('ultima_captura', '2026-10-08');
    await cache.put('volumen_total', 1234.5);
    await cache.put('sesiones', 7);

    expect(await cache.get('ultima_captura'), '2026-10-08');
    expect(await cache.get('volumen_total'), 1234.5);
    expect(await cache.get('sesiones'), 7);
  });

  test('get de clave inexistente devuelve null', () async {
    expect(await cache.get('no-existe'), isNull);
  });

  test('put sobreescribe el valor de una clave existente', () async {
    await cache.put('nivel', 1);
    await cache.put('nivel', 3);

    expect(await cache.get('nivel'), 3);
  });
}