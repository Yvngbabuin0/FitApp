/// Un alimento detectado (por la IA) o introducido a mano, con sus macros.
class FoodItem {
  const FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.confidence,
    this.estimated = false,
  });

  final String name;
  final double quantity;
  final String unit;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Confianza 0–1 devuelta por la IA (null si es manual).
  final double? confidence;

  /// `true` si el valor no se pudo verificar en una base nutricional.
  final bool estimated;

  /// Construye un [FoodItem] a partir del JSON de la Edge Function
  /// `analyze-meal`. Tolera campos ausentes con valores seguros.
  factory FoodItem.fromAnalysisJson(Map<String, dynamic> json) => FoodItem(
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'g',
        calories: (json['calories'] as num?)?.round() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
        confidence: (json['confidence'] as num?)?.toDouble(),
        estimated: json['estimated'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'confidence': confidence,
        'estimated': estimated,
      };

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        calories: (map['calories'] as num).toInt(),
        proteinG: (map['protein_g'] as num).toDouble(),
        carbsG: (map['carbs_g'] as num).toDouble(),
        fatG: (map['fat_g'] as num).toDouble(),
        confidence: (map['confidence'] as num?)?.toDouble(),
        estimated: map['estimated'] as bool? ?? false,
      );

  FoodItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? confidence,
    bool? estimated,
  }) =>
      FoodItem(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        calories: calories ?? this.calories,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        confidence: confidence ?? this.confidence,
        estimated: estimated ?? this.estimated,
      );
}
