import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/progress_controller.dart';
import '../domain/weekly_summary.dart';

/// Resumen semanal con comparación frente a la semana anterior (flechas ▲/▼)
/// y navegación a semanas anteriores.
class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = isoWeekStart(DateTime.now());
  }

  bool get _isCurrentWeek =>
      _weekStart == isoWeekStart(DateTime.now());

  void _previousWeek() => setState(
      () => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() => setState(
      () => _weekStart = _weekStart.add(const Duration(days: 7)));

  String get _weekLabel {
    final end = _weekStart.add(const Duration(days: 6));
    return '${_two(_weekStart.day)}/${_two(_weekStart.month)} – '
        '${_two(end.day)}/${_two(end.month)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final comparisonAsync = ref.watch(progressControllerProvider(_weekStart));

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const Key('prev-week-button'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Semana anterior',
                  onPressed: _previousWeek,
                ),
                Text('Semana del $_weekLabel',
                    style: Theme.of(context).textTheme.titleSmall),
                IconButton(
                  key: const Key('next-week-button'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Semana siguiente',
                  onPressed: _isCurrentWeek ? null : _nextWeek,
                ),
              ],
            ),
          ),
          Expanded(
            child: comparisonAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('No se pudieron cargar los datos.\n$error',
                    textAlign: TextAlign.center),
              ),
              data: (comparison) => _buildSummary(context, comparison),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WeeklyComparison comparison) {
    final current = comparison.current;
    final hasData = current.sessions > 0 ||
        current.volume > 0 ||
        current.avgCalories > 0;

    if (!hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no hay datos esta semana.\nRegistra entrenamientos y comidas '
            'para ver tu progreso.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricRow(
          label: 'Volumen',
          value: '${current.volume.toStringAsFixed(0)} kg',
          delta: comparison.volumeDelta,
        ),
        _MetricRow(
          label: 'Sesiones',
          value: '${current.sessions}',
          delta: comparison.sessionsDelta.toDouble(),
        ),
        _MetricRow(
          label: 'PRs',
          value: '${current.newPrs}',
          delta: comparison.newPrsDelta.toDouble(),
        ),
        _MetricRow(
          label: 'Calorías',
          value: '${current.avgCalories.toStringAsFixed(0)} kcal',
          delta: comparison.caloriesDelta,
        ),
        _MetricRow(
          label: 'Proteína',
          value: '${current.avgProteinG.toStringAsFixed(0)} g',
          delta: comparison.proteinDelta,
        ),
        _MetricRow(
          label: 'Adherencia',
          value:
              '${(current.adherence * 100).toStringAsFixed(0)}%',
          delta: comparison.adherenceDelta * 100,
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = delta > 0.001
        ? (Icons.arrow_upward, Colors.green.shade700)
        : delta < -0.001
            ? (Icons.arrow_downward, Colors.red.shade700)
            : (Icons.remove, theme.disabledColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(value, style: theme.textTheme.titleMedium),
          const SizedBox(width: 16),
          SizedBox(
            width: 72,
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  delta.abs() >= 1
                      ? delta.toStringAsFixed(0)
                      : delta.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}