import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/food/application/food_controller.dart';
import 'features/food/data/food_repository.dart';
import 'features/food/data/meal_analysis_service.dart';
import 'features/profile/application/profile_controller.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/progress/application/progress_controller.dart';
import 'features/progress/data/progress_repository.dart';
import 'features/workouts/application/workout_controller.dart';
import 'features/workouts/data/workout_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  final client = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepository(client)),
        profileRepositoryProvider.overrideWithValue(ProfileRepository(client)),
        workoutRepositoryProvider
            .overrideWithValue(WorkoutRepository(client)),
        foodRepositoryProvider.overrideWithValue(FoodRepository(client)),
        mealAnalysisServiceProvider
            .overrideWithValue(MealAnalysisService(client)),
        progressRepositoryProvider
            .overrideWithValue(ProgressRepository(client)),
      ],
      child: const FitnessApp(),
    ),
  );
}