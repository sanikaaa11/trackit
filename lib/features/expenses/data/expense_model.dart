import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 3)
class Expense extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late String category;

  @HiveField(3)
  String? note;

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late bool isIncome;

  Expense({
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
    this.isIncome = false,
    String? id,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  factory Expense.create({
    required double amount,
    required String category,
    String? note,
    DateTime? date,
    bool isIncome = false,
  }) {
    return Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      note: note,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      isIncome: isIncome,
    );
  }
}
