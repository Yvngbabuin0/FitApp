class WorkoutSet {
  const WorkoutSet({
    this.id,
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    required this.weight,
    this.rpe,
    required this.completed,
  });

  final String? id;
  final String exerciseId;
  final int setIndex;
  final int reps;
  final double weight;
  final double? rpe;
  final bool completed;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exercise_id': exerciseId,
        'set_index': setIndex,
        'reps': reps,
        'weight': weight,
        'rpe': rpe,
        'completed': completed,
      };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
        id: map['id'] as String?,
        exerciseId: map['exercise_id'] as String,
        setIndex: (map['set_index'] as num).toInt(),
        reps: (map['reps'] as num).toInt(),
        weight: (map['weight'] as num).toDouble(),
        rpe: (map['rpe'] as num?)?.toDouble(),
        completed: map['completed'] as bool,
      );

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? setIndex,
    int? reps,
    double? weight,
    double? rpe,
    bool? completed,
  }) =>
      WorkoutSet(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        setIndex: setIndex ?? this.setIndex,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rpe: rpe ?? this.rpe,
        completed: completed ?? this.completed,
      );
}
