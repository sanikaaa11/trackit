import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../domain/habit_notifier.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final habit = habits.where((h) => h.id == id).firstOrNull;

    if (habit == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Text(
            'Habit not found',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
      );
    }

    final repository = ref.watch(habitRepositoryProvider);
    final logs = ref.watch(habitLogsProvider(id));

    final currentStreak = repository.getCurrentStreak(id);
    final longestStreak = repository.getLongestStreak(id);
    final totalCompletions = repository.getTotalCompletions(id);

    final completedDates = logs.map((e) => e.date).toSet();
    final heatmapDates = _buildHeatmapDates();
    final weeklyPercentages = _buildWeeklyCompletionPercentages(completedDates);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          habit.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (context.mounted) context.push('/habits/edit/${habit.id}');
            },
            icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(habitsProvider.notifier).archiveHabit(id);
              if (context.mounted) context.pop();
            },
            icon: Icon(Icons.archive_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: 'Current Streak', value: currentStreak),
                ),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _StatCard(label: 'Longest Streak', value: longestStreak),
                ),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _StatCard(label: 'Total Completions', value: totalCompletions),
                ),
              ],
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'MONTHLY PROGRESS',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            _HeatmapGrid(
              dates: heatmapDates,
              completedDates: completedDates,
            ),
            SizedBox(height: AppSizes.md),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 100,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 25,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: TextStyle(color: AppColors.textHint, fontSize: 10),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final week = value.toInt() + 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'W$week',
                                style: TextStyle(color: AppColors.textHint, fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(weeklyPercentages.length, (index) {
                          return FlSpot(index.toDouble(), weeklyPercentages[index]);
                        }),
                        isCurved: true,
                        color: AppColors.habits,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.habits,
                            strokeColor: Colors.white,
                            strokeWidth: 1,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.habits.withOpacity(0.18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _buildHeatmapDates() {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    final start = end.subtract(const Duration(days: 41));

    return List.generate(42, (index) {
      return DateTime(start.year, start.month, start.day + index);
    });
  }

  List<double> _buildWeeklyCompletionPercentages(Set<String> completedDates) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    return List.generate(4, (index) {
      final weekStart = startOfWeek.subtract(Duration(days: (3 - index) * 7));
      final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

      final eligibleDays = weekDays.where((d) => !d.isAfter(now)).toList();
      if (eligibleDays.isEmpty) return 0;

      int completed = 0;
      for (final day in eligibleDays) {
        if (completedDates.contains(DateFormat('yyyy-MM-dd').format(day))) {
          completed++;
        }
      }

      return (completed / eligibleDays.length) * 100;
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: AppColors.habits,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontXs,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.dates, required this.completedDates});

  final List<DateTime> dates;
  final Set<String> completedDates;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: List.generate(6, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final date = dates[index];
              final dateKey = DateFormat('yyyy-MM-dd').format(date);

              final dayOnly = DateTime(date.year, date.month, date.day);
              final todayOnly = DateTime(today.year, today.month, today.day);

              final isFuture = dayOnly.isAfter(todayOnly);
              final isCompleted = completedDates.contains(dateKey);

              Color color;
              if (isFuture) {
                color = AppColors.border;
              } else if (isCompleted) {
                final diff = todayOnly.difference(dayOnly).inDays;
                final opacity = (1.0 - (diff / 60)).clamp(0.3, 1.0);
                color = AppColors.habits.withOpacity(opacity);
              } else {
                color = AppColors.surfaceVariant;
              }

              return Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
