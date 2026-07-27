import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/pdf_service.dart';
import '../domain/expense_notifier.dart';

class ExpenseReportScreen extends ConsumerWidget {
  const ExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final balance = ref.watch(balanceProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final expenses = ref.watch(expensesProvider);

    final monthExpenses = expenses.where((expense) {
      return !expense.isIncome &&
          expense.date.year == selectedMonth.year &&
          expense.date.month == selectedMonth.month;
    }).toList();

    final dailyTotals = _buildDailyTotals(monthExpenses);
    final avgPerDay = dailyTotals.isEmpty
        ? 0.0
        : dailyTotals.values.fold(0.0, (sum, value) => sum + value) /
              dailyTotals.length;

    final monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            final prev = DateTime(
              selectedMonth.year,
              selectedMonth.month - 1,
              1,
            );
            ref.read(selectedMonthProvider.notifier).state = prev;
          },
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        title: Text(
          monthTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.expenses,
            ),
            tooltip: 'Export PDF',
            onPressed: () async {
              try {
                final expenses = ref.read(expensesProvider).where((expense) {
                  final selected = ref.read(selectedMonthProvider);
                  return expense.date.month == selected.month &&
                      expense.date.year == selected.year;
                }).toList();

                final budget = ref
                    .read(expenseRepositoryProvider)
                    .getMonthlyBudget();
                final categoryTotals = ref.read(categoryTotalsProvider);
                final monthYear = DateFormat(
                  'MMMM_yyyy',
                ).format(ref.read(selectedMonthProvider));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating PDF...'),
                    duration: Duration(seconds: 1),
                    backgroundColor: AppColors.surface,
                  ),
                );

                await ref
                    .read(pdfServiceProvider)
                    .exportExpenseReport(
                      expenses: expenses,
                      monthlyBudget: budget,
                      monthYear: monthYear,
                      categoryTotals: categoryTotals,
                    );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export failed: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
          IconButton(
            onPressed: () {
              final next = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
                1,
              );
              ref.read(selectedMonthProvider.notifier).state = next;
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'MONTHLY REPORT',
              style: TextStyle(
                color: AppColors.expenses,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Spent',
                    value: totalSpent,
                    valueColor: AppColors.expenses,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Budget Left',
                    value: balance,
                    valueColor: balance < 0 ? AppColors.error : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceRadius: 60,
                            sectionsSpace: 2,
                            sections: _buildPieSections(categoryTotals),
                          ),
                        ),
                        Text(
                          'Total\n₹${totalSpent.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildLegend(categoryTotals),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Daily Spending',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'AVG ₹${avgPerDay.toStringAsFixed(0)}/day',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          horizontalInterval: math.max(
                            1,
                            _maxY(dailyTotals) / 4,
                          ),
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            );
                          },
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5,
                              getTitlesWidget: (value, meta) {
                                final day = value.toInt();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: _buildBarGroups(dailyTotals),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expenses,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Get AI Insights'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> totals) {
    if (totals.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppColors.surfaceVariant,
          radius: 34,
          title: '',
        ),
      ];
    }

    final colors = [
      AppColors.expenses,
      AppColors.tasks,
      AppColors.notes,
      AppColors.journal,
      AppColors.habits,
      AppColors.onboarding,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    final entries = totals.entries.toList();
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return PieChartSectionData(
        value: entry.value,
        color: colors[index % colors.length],
        radius: 34,
        title: '',
      );
    });
  }

  List<Widget> _buildLegend(Map<String, double> totals) {
    final sum = totals.values.fold(0.0, (a, b) => a + b);
    final colors = [
      AppColors.expenses,
      AppColors.tasks,
      AppColors.notes,
      AppColors.journal,
      AppColors.habits,
      AppColors.onboarding,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    final entries = totals.entries.toList();
    if (entries.isEmpty) {
      return [
        Text(
          'No category data yet',
          style: TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ];
    }

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percentage = sum == 0 ? 0 : (entry.value / sum) * 100;
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ],
        ),
      );
    });
  }

  Map<int, double> _buildDailyTotals(List<dynamic> expenses) {
    final totals = <int, double>{};
    for (final expense in expenses) {
      final day = expense.date.day;
      totals[day] = (totals[day] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<BarChartGroupData> _buildBarGroups(Map<int, double> dailyTotals) {
    if (dailyTotals.isEmpty) {
      return List.generate(7, (index) {
        return BarChartGroupData(
          x: index + 1,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: AppColors.expenses,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      });
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    return sortedDays.map((day) {
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[day] ?? 0,
            color: AppColors.expenses,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  double _maxY(Map<int, double> dailyTotals) {
    if (dailyTotals.isEmpty) return 0;
    return dailyTotals.values.reduce(math.max);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final double value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
