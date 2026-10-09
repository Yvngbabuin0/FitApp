import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/food_repository.dart';
import '../data/meal_analysis_service.dart';
import '../domain/food_entry.dart';
import '../domain/food_item.dart';

/// Servicio de análisis de comida. En producción se sobrescribe con el cliente
/// real; en tests, con uno simulado.
final mealAnalysisServiceProvider = Provider<MealAnalysisService>((ref) {
  throw UnimplementedError(
      'mealAnalysisServiceProvider debe sobrescribirse en main.dart o tests');
});

/// Repositorio de comidas. En producción se sobrescribe con el cliente real;
/// en tests, con uno simulado.
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  throw UnimplementedError(
      'foodRepositoryProvider debe sobrescribirse en main.dart o tests');
});

/// Estado del diario de hoy (entradas de comida del día).
final foodControllerProvider =
    AsyncNotifierProvider<FoodController, List<FoodEntry>>(
  FoodController.new,
);

class FoodController extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return ref.read(foodRepositoryProvider).fetchEntries(from: start, to: end);
  }

  /// Analiza una foto y devuelve los alimentos detectados (puede ser vacío).
  Future<List<FoodItem>> analyze(Uint8List imageBytes, {String? hint}) {
    return ref
        .read(mealAnalysisServiceProvider)
        .analyze(imageBytes, hint: hint);
  }

  Future<void> saveEntry(FoodEntry entry) async {
    await ref.read(foodRepositoryProvider).saveEntry(entry);
    await refresh();
  }

  Future<void> deleteEntry(String id) async {
    await ref.read(foodRepositoryProvider).deleteEntry(id);
    await refresh();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => build());
  }
}