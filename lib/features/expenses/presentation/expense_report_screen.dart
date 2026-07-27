import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/ai_service.dart';
import '../domain/expense_notifier.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  ConsumerState<ExpenseReportScreen> createState() =>
      _ExpenseReportScreenState();
}

class _ExpenseReportScreenState
    extends ConsumerState<ExpenseReportScreen> {
  DateTime selectedMonth = DateTime.now();
  String? aiInsight;
  bool isLoadingAi = false;

  Future<void> _getAiInsight() async {
    setState(() => isLoadingAi = true);

    final repository = ref.read(expenseRepositoryProvider);
    final categoryTotals = repository.getCategoryTotals(
      selectedMonth.month,
      selectedMonth.year,
    );
    final budget = repository.getMonthlyBudget();

    try {
      final insight = await ref.read(aiServiceProvider).getExpenseSuggestions(
        categoryTotals,
        budget,
      );
      setState(() {
        aiInsight = insight;
        isLoadingAi = false;
      });
    } catch (e) {
      setState(() {
        aiInsight = 'Could not load AI insights right now. Check your internet and try again.';
        isLoadingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final repository = ref.watch(expenseRepositoryProvider);

    final monthExpenses = expenses
        .where(
          (e) =>
              !e.isIncome &&
              e.date.month == selectedMonth.month &&
              e.date.year == selectedMonth.year,
        )
        .toList();

    final totalSpent =
        monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final budget = repository.getMonthlyBudget();
    final remaining = budget - totalSpent;
    final categoryTotals = repository.getCategoryTotals(
      selectedMonth.month,
      selectedMonth.year,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                selectedMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                );
              }),
              child: Icon(Icons.chevron_left, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMMM yyyy').format(selectedMonth),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                selectedMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                );
              }),
              child: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MONTHLY REPORT',
              style: TextStyle(
                color: AppColors.expenses,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Stat cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'TOTAL SPENT',
                    value: '₹${NumberFormat('#,##0').format(totalSpent)}',
                    valueColor: AppColors.expenses,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'BUDGET LEFT',
                    value: '₹${NumberFormat('#,##0').format(remaining.abs())}',
                    valueColor: remaining >= 0
                        ? Colors.white
                        : AppColors.error,
                    prefix: remaining < 0 ? '-' : '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pie chart
            if (categoryTotals.isNotEmpty)
              Container(
                padding: EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 60,
                          sections: _buildPieSections(
                            categoryTotals,
                            totalSpent,
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    ...categoryTotals.entries.map((e) {
                      final pct = totalSpent == 0
                          ? 0
                          : (e.value / totalSpent * 100).round();
                      final color = _categoryColor(e.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Bar chart
            Container(
              padding: EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
                      if (monthExpenses.isNotEmpty)
                        Text(
                          'AVG ₹${(totalSpent / DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day).toStringAsFixed(0)}/day',
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
                    child: monthExpenses.isEmpty
                        ? Center(
                            child: Text(
                              'No expenses this month',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : _buildBarChart(monthExpenses),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Insights button + result
            if (aiInsight != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: AppColors.expenses.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '✨',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insights',
                          style: TextStyle(
                            color: AppColors.expenses,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => aiInsight = null),
                          child: Icon(
                            Icons.close,
                            color: AppColors.textHint,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      aiInsight!,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingAi ? null : _getAiInsight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expenses,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: isLoadingAi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('✨', style: TextStyle(fontSize: 16)),
                label: Text(
                  isLoadingAi ? 'Getting insights...' : 'Get AI Insights',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> totals,
    double total,
  ) {
    final colors = [
      AppColors.tasks,
      AppColors.notes,
      AppColors.habits,
      AppColors.expenses,
      AppColors.journal,
      Colors.purple,
      Colors.pink,
      Colors.amber,
    ];
    int i = 0;
    return totals.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: e.value,
        color: color,
        radius: 40,
        showTitle: false,
      );
    }).toList();
  }

  Color _categoryColor(String category) {
    const map = {
      'Groceries': AppColors.expenses,
      'Food & Dining': AppColors.tasks,
      'Transport': AppColors.habits,
      'Medical': Colors.pink,
      'Fees & Education': AppColors.notes,
      'Clothing': Colors.purple,
      'Entertainment': Colors.amber,
      'Utilities': Colors.orange,
      'Others': Colors.grey,
    };
    return map[category] ?? Colors.grey;
  }

  Widget _buildBarChart(expenses) {
    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final dailyTotals = <int, double>{};
    for (final e in expenses) {
      dailyTotals[e.date.day] =
          (dailyTotals[e.date.day] ?? 0) + e.amount;
    }

    final maxVal = dailyTotals.values.isEmpty
        ? 1.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
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
              getTitlesWidget: (value, _) {
                final day = value.toInt();
                if (day == 1 || day == 10 || day == 20 || day == daysInMonth) {
                  return Text(
                    '$day',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barGroups: List.generate(daysInMonth, (index) {
          final day = index + 1;
          return BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: dailyTotals[day] ?? 0,
                color: AppColors.expenses,
                width: 4,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal * 1.2,
                  color: AppColors.surfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.prefix = '',
  });

  final String label;
  final String value;
  final Color valueColor;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: AppSizes.fontXs,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$prefix$value',
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.expenses,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}