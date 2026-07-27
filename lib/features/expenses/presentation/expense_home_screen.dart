import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/upi_sms_service.dart';
import '../data/expense_model.dart';
import '../domain/expense_notifier.dart';

class ExpenseHomeScreen extends ConsumerStatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  ConsumerState<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends ConsumerState<ExpenseHomeScreen> {
  // Tracks which UPI transactions we've already shown this session
  final Set<String> _shownTransactions = {};

  @override
  void initState() {
    super.initState();
    _syncBudgetFromPrefsIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupUpiDetection();
    });
  }

  Future<void> _setupUpiDetection() async {
    // First scan recent SMS history (catches payments made before app opened)
    await UpiSmsService.scanRecentSms((amount, sender) {
      if (!mounted) return;
      _showUpiSnackbar(amount, sender);
    });

    // Then listen for new SMS while on this screen
    if (!mounted) return;
    UpiSmsService.initialize(context, (amount, sender) {
      if (!mounted) return;
      _showUpiSnackbar(amount, sender);
    });
  }

  void _showUpiSnackbar(double amount, String sender) {
    // Deduplicate — don't show same transaction twice
    final key = '${amount.toStringAsFixed(0)}_$sender';
    if (_shownTransactions.contains(key)) return;
    _shownTransactions.add(key);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(
              '💳',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)} detected from $sender',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap "Log it" to add this expense',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Log it',
          textColor: AppColors.expenses,
          onPressed: () {
            context.push(
              '/expenses/add',
              extra: {'amount': amount, 'source': sender},
            );
          },
        ),
        duration: const Duration(seconds: 10),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _syncBudgetFromPrefsIfNeeded() async {
    final repository = ref.read(expenseRepositoryProvider);
    if (repository.getMonthlyBudget() > 0) return;

    final prefs = await SharedPreferences.getInstance();
    final savedBudget = prefs.getDouble('monthlyBudget') ?? 0;
    if (savedBudget > 0) {
      await repository.setMonthlyBudget(savedBudget);
      if (mounted) setState(() {});
    }
  }

  Future<void> _showBudgetDialog(double currentBudget) async {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    final newBudget = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Set monthly budget',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(
              color: AppColors.expenses,
              fontWeight: FontWeight.bold,
            ),
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: AppColors.textHint),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.expenses),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: Text('Save',
                style: TextStyle(
                  color: AppColors.expenses,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );

    if (newBudget == null || newBudget < 0) return;

    final repository = ref.read(expenseRepositoryProvider);
    await repository.setMonthlyBudget(newBudget);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', newBudget);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final repository = ref.watch(expenseRepositoryProvider);
    final budget = repository.getMonthlyBudget();
    final spent = ref.watch(totalSpentProvider);

    final recentExpenses = expenses.where((e) => !e.isIncome).take(5).toList();

    // Calculate remaining balance
    final remaining = budget - spent;
    final isOverBudget = remaining < 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Expenses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/expenses/report'),
            icon: Icon(Icons.bar_chart_rounded, color: AppColors.expenses),
            tooltip: 'Monthly report',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'BUDGET',
                    value: budget,
                    valueColor: Colors.white,
                    onTap: () => _showBudgetDialog(budget),
                  ),
                ),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _StatCard(
                    label: 'SPENT',
                    value: spent,
                    valueColor: AppColors.expenses,
                  ),
                ),
              ],
            ),
            // Over budget warning
            if (isOverBudget && budget > 0) ...[
              SizedBox(height: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Over budget by ₹${remaining.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppSizes.lg),
            // Recent transactions header
            Row(
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.fontLg,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/expenses/history'),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.expenses,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.sm),
            Expanded(
              child: recentExpenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.textHint,
                            size: 56,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No expenses yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppSizes.fontMd,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add your first expense',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentExpenses.length,
                      itemBuilder: (context, index) {
                        return _ExpenseItem(
                          expense: recentExpenses[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.expenses,
        onPressed: () => context.push('/expenses/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.onTap,
  });

  final String label;
  final double value;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          padding: EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppSizes.fontXs,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.textHint,
                      size: 14,
                    ),
                  ],
                ],
              ),
              SizedBox(height: AppSizes.xs),
              Text(
                '₹${value.toStringAsFixed(0)}',
                style: TextStyle(
                  color: valueColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.sm),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({required this.expense});

  final Expense expense;

  static const Map<String, String> _categoryEmojis = {
    'Groceries': '🛒',
    'Food & Dining': '🍽️',
    'Transport': '🚌',
    'Medical': '💊',
    'Fees & Education': '🎓',
    'Clothing': '👕',
    'Entertainment': '🎬',
    'Utilities': '💡',
    'Others': '📦',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _categoryEmojis[expense.category] ?? '💸';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  expense.note?.trim().isEmpty ?? true
                      ? DateFormat('dd MMM').format(expense.date)
                      : expense.note!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontSm,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSizes.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₹${expense.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.expenses,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('dd MMM').format(expense.date),
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}