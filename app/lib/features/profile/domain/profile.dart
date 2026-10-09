enum Units { kg, lb }

/// Perfil del usuario (fila de la tabla `profiles`).
class Profile {
  const Profile({
    required this.id,
    this.displayName,
    this.dailyCalorieTarget = 2000,
    this.proteinTargetG = 150,
    this.carbsTargetG = 200,
    this.fatTargetG = 70,
    this.units = Units.kg,
  });

  final String id;
  final String? displayName;
  final int dailyCalorieTarget;
  final double proteinTargetG;
  final double carbsTargetG;
  final double fatTargetG;
  final Units units;

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'daily_calorie_target': dailyCalorieTarget,
        'protein_target_g': proteinTargetG,
        'carbs_target_g': carbsTargetG,
        'fat_target_g': fatTargetG,
        'units': units.name,
      };

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        dailyCalorieTarget:
            (map['daily_calorie_target'] as num?)?.toInt() ?? 2000,
        proteinTargetG: (map['protein_target_g'] as num?)?.toDouble() ?? 150,
        carbsTargetG: (map['carbs_target_g'] as num?)?.toDouble() ?? 200,
        fatTargetG: (map['fat_target_g'] as num?)?.toDouble() ?? 70,
        units: Units.values.asNameMap()[map['units']] ?? Units.kg,
      );

  Profile copyWith({
    String? displayName,
    int? dailyCalorieTarget,
    double? proteinTargetG,
    double? carbsTargetG,
    double? fatTargetG,
    Units? units,
  }) =>
      Profile(
        id: id,
        displayName: displayName ?? this.displayName,
        dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
        proteinTargetG: proteinTargetG ?? this.proteinTargetG,
        carbsTargetG: carbsTargetG ?? this.carbsTargetG,
        fatTargetG: fatTargetG ?? this.fatTargetG,
        units: units ?? this.units,
      );
}