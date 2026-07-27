import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/expense_model.dart';
import '../domain/expense_notifier.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.extra});

  final Map<String, dynamic>? extra;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late final TextEditingController amountController;
  late final TextEditingController noteController;
  final FocusNode _amountFocus = FocusNode();

  String selectedCategory = 'Food & Dining';
  DateTime selectedDate = DateTime.now();
  String? prefillSource;

  final List<String> categories = const [
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
  void initState() {
    super.initState();
    amountController = TextEditingController();
    noteController = TextEditingController();
    _applyPrefillFromExtra();

    // Auto focus amount field — opens keyboard immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  void _applyPrefillFromExtra() {
    final extra = widget.extra;
    final amount = extra?['amount'];
    if (amount == null) return;

    amountController.text = (amount as double).toStringAsFixed(0);
    final source = extra?['source'];
    if (source != null) {
      prefillSource = source.toString();
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final expense = Expense.create(
      amount: amount,
      category: selectedCategory,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
      date: selectedDate,
    );

    await ref.read(expensesProvider.notifier).addExpense(expense);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Add Expense',
          style: TextStyle(
            color: AppColors.expenses,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UPI auto-detect banner
            if (prefillSource != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.expenses.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.expenses.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-detected from $prefillSource',
                      style: TextStyle(
                        color: AppColors.expenses,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Amount input
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹',
                    style: TextStyle(
                      color: AppColors.expenses,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: amountController,
                      focusNode: _amountFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        border: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.expenses),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.expenses),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.expenses,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.xl),

            // Category
            Text(
              'CATEGORY',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.expenses
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _categoryEmojis[category] ?? '💸',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
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
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: AppSizes.lg),

            // Note
            TextField(
              controller: noteController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a note... (optional)',
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(AppSizes.md),
              ),
            ),
            SizedBox(height: AppSizes.md),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: AppColors.expenses, size: 18),
                    SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(selectedDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSizes.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expenses,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}