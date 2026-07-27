import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackit/features/badges/data/badge_service.dart';

import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

final expensesProvider =
    StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repository, ref);
});

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier(this.repository, this.ref) : super([]) {
    loadExpenses();
  }

  final ExpenseRepository repository;
  final Ref ref;

  void loadExpenses() {
    state = repository.getAllExpenses();
  }

  Future<String?> addExpense(Expense expense) async {
    await repository.addExpense(expense);
    loadExpenses();

    if (expense.isIncome) return null;

    // Badge check — budget villain
    final monthlyBudget = repository.getMonthlyBudget();
    final now = expense.date;
    final monthSpent = repository
        .getAllExpenses()
        .where((e) =>
            !e.isIncome &&
            e.date.month == now.month &&
            e.date.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final isOverBudget = monthlyBudget > 0 && monthSpent > monthlyBudget;

    final badgeService = ref.read(badgeServiceProvider);
    return await badgeService.checkAndAward('expense_logged', {
      'isOverBudget': isOverBudget,
    });
  }

  Future<void> deleteExpense(String id) async {
    await repository.deleteExpense(id);
    loadExpenses();
  }
}

final selectedMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final totalSpentProvider = Provider<double>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final expenses = ref.watch(expensesProvider);

  return expenses
      .where(
        (expense) =>
            !expense.isIncome &&
            expense.date.month == selectedMonth.month &&
            expense.date.year == selectedMonth.year,
      )
      .fold(0.0, (sum, expense) => sum + expense.amount);
});

final balanceProvider = Provider<double>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final totalSpent = ref.watch(totalSpentProvider);
  final monthlyBudget = repository.getMonthlyBudget();
  return monthlyBudget - totalSpent;
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final expenses = ref.watch(expensesProvider).where((expense) {
    return !expense.isIncome &&
        expense.date.month == selectedMonth.month &&
        expense.date.year == selectedMonth.year;
  });

  final totals = <String, double>{};
  for (final expense in expenses) {
    totals.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }
  return totals;
});