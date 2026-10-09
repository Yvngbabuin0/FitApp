import 'package:fitness_app/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Env expone url y anon key no vacías', () {
    expect(Env.supabaseUrl, isNotEmpty);
    expect(Env.supabaseAnonKey, isNotEmpty);
  });
}