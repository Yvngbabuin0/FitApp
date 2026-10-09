class Exercise {
  const Exercise({
    required this.id,
    required this.userId,
    required this.name,
    required this.muscleGroup,
    required this.isCustom,
  });

  final String id;
  final String userId;
  final String name;
  final String muscleGroup;
  final bool isCustom;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'muscle_group': muscleGroup,
        'is_custom': isCustom,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        muscleGroup: map['muscle_group'] as String,
        isCustom: map['is_custom'] as bool,
      );
}
