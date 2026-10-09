import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack }

enum FoodSource { ai, manual }

/// Una comida registrada, con sus alimentos y totales derivados.
class FoodEntry {
  const FoodEntry({
    this.id,
    required this.userId,
    required this.loggedAt,
    required this.mealType,
    required this.items,
    this.photoPath,
    required this.source,
  });

  final String? id;
  final String userId;
  final DateTime loggedAt;
  final MealType mealType;
  final List<FoodItem> items;
  final String? photoPath;
  final FoodSource source;

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);

  double get totalProteinG =>
      items.fold(0.0, (sum, item) => sum + item.proteinG);

  double get totalCarbsG => items.fold(0.0, (sum, item) => sum + item.carbsG);

  double get totalFatG => items.fold(0.0, (sum, item) => sum + item.fatG);

  /// Mapa completo, **incluidos los items** anidados bajo `items`. Al insertar
  /// en la tabla `food_entries` el repositorio debe **quitar** la clave `items`
  /// (los alimentos van a `food_entry_items`).
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'logged_at': loggedAt.toIso8601String(),
        'meal_type': mealType.name,
        'total_calories': totalCalories,
        'total_protein_g': totalProteinG,
        'total_carbs_g': totalCarbsG,
        'total_fat_g': totalFatG,
        'photo_path': photoPath,
        'source': source.name,
        'items': items.map((item) => item.toMap()).toList(),
      };

  factory FoodEntry.fromMap(Map<String, dynamic> map) => FoodEntry(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        loggedAt: DateTime.parse(map['logged_at'] as String),
        mealType: MealType.values.byName(map['meal_type'] as String),
        items: (map['items'] as List<dynamic>? ?? const [])
            .map((e) => FoodItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        photoPath: map['photo_path'] as String?,
        source: FoodSource.values.byName(map['source'] as String),
      );

  FoodEntry copyWith({
    String? id,
    String? userId,
    DateTime? loggedAt,
    MealType? mealType,
    List<FoodItem>? items,
    String? photoPath,
    FoodSource? source,
  }) =>
      FoodEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        loggedAt: loggedAt ?? this.loggedAt,
        mealType: mealType ?? this.mealType,
        items: items ?? this.items,
        photoPath: photoPath ?? this.photoPath,
        source: source ?? this.source,
      );
}
