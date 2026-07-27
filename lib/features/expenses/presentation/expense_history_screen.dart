import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/expense_model.dart';
import '../domain/expense_notifier.dart';

final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'All');

class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  static const List<String> _categories = [
    'All',
    'Groceries',
    'Food & Dining',
    'Transport',
    'Medical',
    'Fees & Education',
    'Clothing',
    'Entertainment',
    'Utilities',
    'Others',
  ];

  List<Expense> _sortedExpenses(List<Expense> expenses) {
    final list = expenses.where((e) => !e.isIncome).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedCategoryFilterProvider);
    final expenses = _sortedExpenses(ref.watch(expensesProvider));

    final filteredExpenses = selectedFilter == 'All'
        ? expenses
        : expenses.where((e) => e.category == selectedFilter).toList();

    final now = DateTime.now();
    final monthlyTotal = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                final isSelected = selectedFilter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(selectedCategoryFilterProvider.notifier)
                        .state = category,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.expenses
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (selectedFilter == 'All')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This month',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${filteredExpenses.length} transactions',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '₹${monthlyTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.expenses,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.textHint,
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedFilter == 'All'
                              ? 'Start tracking your expenses'
                              : 'No $selectedFilter expenses found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontMd,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      return _ExpenseHistoryItem(
                        expense: filteredExpenses[index],
                        key: ValueKey(filteredExpenses[index].id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseHistoryItem extends ConsumerStatefulWidget {
  const _ExpenseHistoryItem({required this.expense, super.key});

  final Expense expense;

  @override
  ConsumerState<_ExpenseHistoryItem> createState() =>
      _ExpenseHistoryItemState();
}

class _ExpenseHistoryItemState extends ConsumerState<_ExpenseHistoryItem> {
  static const Map<String, String> _categoryEmojis = {
    'Groceries': '🛒',
    'Food & Dining': '🍔',
    'Transport': '🚌',
    'Medical': '💊',
    'Fees & Education': '🎓',
    'Clothing': '👕',
    'Entertainment': '🎬',
    'Utilities': '💡',
    'Others': '📦',
  };

  Future<void> _deleteExpense() async {
    await ref
        .read(expensesProvider.notifier)
        .deleteExpense(widget.expense.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.expenses,
          onPressed: () {
            ref
                .read(expensesProvider.notifier)
                .addExpense(widget.expense);
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete transaction?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          '${widget.expense.category} · ₹${widget.expense.amount.toStringAsFixed(0)} will be removed.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categoryEmojis[widget.expense.category] ?? '💸',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.expense.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '-₹${widget.expense.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              title: Text(
                'Delete transaction',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Hold and swipe left to delete too',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final confirmed = await _confirmDelete();
                if (confirmed && mounted) {
                  await _deleteExpense();
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              title: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _categoryEmojis[widget.expense.category] ?? '💸';

    return Dismissible(
      key: ValueKey(widget.expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _deleteExpense(),
      child: GestureDetector(
        onLongPress: _showOptionsSheet,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.expense.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.expense.note?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.expense.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(widget.expense.date),
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '-₹${widget.expense.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}