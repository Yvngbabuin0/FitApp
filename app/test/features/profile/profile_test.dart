import 'package:fitness_app/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile round-trip', () {
    test('fromMap(toMap()) conserva todos los campos', () {
      const profile = Profile(
        id: 'u-1',
        displayName: 'Jordi',
        dailyCalorieTarget: 2000,
        proteinTargetG: 150,
        carbsTargetG: 200,
        fatTargetG: 70,
        units: Units.kg,
      );

      final back = Profile.fromMap(profile.toMap());

      expect(back.id, 'u-1');
      expect(back.displayName, 'Jordi');
      expect(back.dailyCalorieTarget, 2000);
      expect(back.proteinTargetG, 150);
      expect(back.carbsTargetG, 200);
      expect(back.fatTargetG, 70);
      expect(back.units, Units.kg);
    });

    test('units se parsea a Units desde el texto de la DB', () {
      final map = <String, dynamic>{
        'id': 'u-1',
        'display_name': null,
        'daily_calorie_target': 1800,
        'protein_target_g': 140,
        'carbs_target_g': 190,
        'fat_target_g': 65,
        'units': 'lb',
      };

      expect(Profile.fromMap(map).units, Units.lb);
    });

    test('display_name nulo se conserva como null', () {
      final profile = Profile.fromMap(const {'id': 'u-1', 'units': 'kg'});

      expect(profile.displayName, isNull);
      expect(profile.dailyCalorieTarget, 2000);
    });
  });

  group('Profile.copyWith', () {
    test('cambia units y dailyCalorieTarget sin tocar el resto', () {
      const profile = Profile(
        id: 'u-1',
        dailyCalorieTarget: 2000,
        proteinTargetG: 150,
        carbsTargetG: 200,
        fatTargetG: 70,
        units: Units.kg,
      );

      final updated =
          profile.copyWith(dailyCalorieTarget: 2200, units: Units.lb);

      expect(updated.dailyCalorieTarget, 2200);
      expect(updated.units, Units.lb);
      expect(updated.id, 'u-1');
      expect(updated.proteinTargetG, 150);
      expect(updated.carbsTargetG, 200);
      expect(updated.fatTargetG, 70);
      expect(updated.displayName, isNull);
    });
  });
}