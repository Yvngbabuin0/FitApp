import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/workout_controller.dart';
import '../domain/workout_session.dart';

/// Punto de evolución de un ejercicio: fecha, peso máximo y volumen de la sesión.
class ExerciseChartPoint {
  const ExerciseChartPoint({
    required this.date,
    required this.maxWeight,
    required this.volume,
  });

  final DateTime date;
  final double maxWeight;
  final double volume;
}

/// Evolución por sesión de un ejercicio: peso máximo y volumen (solo de las
/// series de ese ejercicio). Sesiones sin series del ejercicio se omiten.
List<ExerciseChartPoint> evolutionPoints(
  List<WorkoutSession> sessions,
  String exerciseId,
) {
  final sorted = [...sessions]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final points = <ExerciseChartPoint>[];
  for (final session in sorted) {
    final sets =
        session.sets.where((s) => s.exerciseId == exerciseId).toList();
    if (sets.isEmpty) continue;
    var maxWeight = 0.0;
    var volume = 0.0;
    for (final set in sets) {
      if (set.weight > maxWeight) maxWeight = set.weight;
      volume += set.reps * set.weight;
    }
    points.add(ExerciseChartPoint(
      date: session.startedAt,
      maxWeight: maxWeight,
      volume: volume,
    ));
  }
  return points;
}

/// Gráfica de evolución (peso máximo y volumen) de un ejercicio.
class ExerciseChartScreen extends ConsumerStatefulWidget {
  const ExerciseChartScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ExerciseChartScreen> createState() =>
      _ExerciseChartScreenState();
}

class _ExerciseChartScreenState extends ConsumerState<ExerciseChartScreen> {
  late final Future<List<WorkoutSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = ref
        .read(workoutRepositoryProvider)
        .fetchSessionsForExercise(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolución')),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('No se pudieron cargar los datos.\n${snapshot.error}',
                  textAlign: TextAlign.center),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final points =
              evolutionPoints(snapshot.data!, widget.exerciseId);
          if (points.isEmpty) {
            return const Center(
              child: Text('Sin datos aún para este ejercicio.'),
            );
          }
          return _EvolutionChart(points: points);
        },
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.points});

  final List<ExerciseChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].maxWeight),
    ];
    final volumeSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].volume),
    ];

    var maxValue = 0.0;
    for (final spot in [...weightSpots, ...volumeSpots]) {
      if (spot.y > maxValue) maxValue = spot.y;
    }
    final yMax = maxValue <= 0 ? 1.0 : maxValue * 1.1;
    final xMax = points.length <= 1 ? 1.0 : (points.length - 1).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            children: [
              _LegendDot(
                color: theme.colorScheme.primary,
                label: 'Peso máx (${points.first.maxWeight.toStringAsFixed(0)})',
              ),
              _LegendDot(
                color: theme.colorScheme.secondary,
                label: 'Volumen',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: xMax,
                minY: 0,
                maxY: yMax,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: theme.dividerColor),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final date = points[index].date;
                        final text = '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}';
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(text, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: weightSpots,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isCurved: true,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: volumeSpots,
                    color: theme.colorScheme.secondary,
                    barWidth: 3,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}