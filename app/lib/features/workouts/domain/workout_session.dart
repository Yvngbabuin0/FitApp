import 'workout_set.dart';

class WorkoutSession {
  const WorkoutSession({
    this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.notes,
    this.sets = const [],
  });

  final String? id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  final List<WorkoutSet> sets;

  /// Mapa completo de la sesión, **incluidas las series** anidadas bajo `sets`.
  /// Al insertar en la tabla `workout_sessions` el repositorio debe **quitar**
  /// la clave `sets` (las series van a su propia tabla).
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'notes': notes,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        startedAt: DateTime.parse(map['started_at'] as String),
        endedAt: map['ended_at'] == null
            ? null
            : DateTime.parse(map['ended_at'] as String),
        notes: map['notes'] as String?,
        sets: (map['sets'] as List<dynamic>? ?? const [])
            .map((e) => WorkoutSet.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
