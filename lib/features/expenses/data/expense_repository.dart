import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/account_scope.dart';
import 'expense_model.dart';
import 'user_settings_model.dart';

class ExpenseRepository {
  static const String expensesBoxName = 'expenses_box';
  static const String boxName = 'expenses_box';
  static const String settingsBoxName = 'settings_box';
  static const String _settingsKey = 'user_settings';

  String get _scopedSettingsKey => AccountScope.scopedHiveKey(_settingsKey);

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Expense>(boxName);
    }
    if (!Hive.isBoxOpen(settingsBoxName)) {
      await Hive.openBox<UserSettings>(settingsBoxName);
    }

    final settingsBox = Hive.box<UserSettings>(settingsBoxName);
    if (!settingsBox.containsKey(_scopedSettingsKey)) {
      await settingsBox.put(_scopedSettingsKey, UserSettings());
    }
  }

  Box<Expense> get _expenseBox => Hive.box<Expense>(boxName);
  Box<UserSettings> get _settingsBox => Hive.box<UserSettings>(settingsBoxName);

  List<Expense> getAllExpenses() {
    final expenses = _expenseBox.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _expenseBox.get(key))
        .whereType<Expense>()
        .toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(AccountScope.scopedHiveKey(expense.id), expense);
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(AccountScope.scopedHiveKey(id));
  }

  List<Expense> getExpensesForMonth(int month, int year) {
    return getAllExpenses().where((expense) {
      return expense.date.month == month && expense.date.year == year;
    }).toList();
  }

  double getTotalSpentThisMonth() {
    final now = DateTime.now();
    final expenses = getExpensesForMonth(now.month, now.year);
    return expenses
        .where((expense) => !expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getBalance() {
    return getMonthlyBudget() - getTotalSpentThisMonth();
  }

  Map<String, double> getCategoryTotals(int month, int year) {
    final totals = <String, double>{};
    final expenses = getExpensesForMonth(month, year)
        .where((expense) => !expense.isIncome)
        .toList();

    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  double getMonthlyBudget() {
    final settings = _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
    return settings.monthlyBudget;
  }

  Future<void> setMonthlyBudget(double budget) async {
    final settings = _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
    settings.monthlyBudget = budget;
    await _settingsBox.put(_scopedSettingsKey, settings);
  }

  Future<void> setUserName(String name) async {
    final settings = _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
    settings.userName = name;
    await _settingsBox.put(_scopedSettingsKey, settings);
  }

  Future<void> setUserEmoji(String emoji) async {
    final settings = _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
    settings.userEmoji = emoji;
    await _settingsBox.put(_scopedSettingsKey, settings);
  }

  Future<void> setUserVibe(int vibe) async {
    final settings = _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
    settings.userVibe = vibe;
    await _settingsBox.put(_scopedSettingsKey, settings);
  }

  Future<void> setHasCompletedOnboarding(bool completed) async {
    final settings = _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
    settings.hasCompletedOnboarding = completed;
    await _settingsBox.put(_scopedSettingsKey, settings);
  }

  UserSettings getSettings() {
    return _settingsBox.get(_scopedSettingsKey) ?? UserSettings();
  }
}
