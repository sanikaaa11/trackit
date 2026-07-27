import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  late String priority;

  @HiveField(5)
  late bool isComplete;

  @HiveField(6)
  late DateTime createdAt;

  Task({
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    required this.isComplete,
    required this.createdAt,
    String? id,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  factory Task.create({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'Medium',
  }) {
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      isComplete: false,
      createdAt: DateTime.now(),
    );
  }
}
