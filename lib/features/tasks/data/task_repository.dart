import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/account_scope.dart';
import 'task_model.dart';

class TaskRepository {
  static const String boxName = 'tasks_box';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Task>(boxName);
    }
  }

  Box<Task> get _box => Hive.box<Task>(boxName);

  List<Task> getAllTasks() {
    final tasks = _box.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _box.get(key))
        .whereType<Task>()
        .toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<void> addTask(Task task) async {
    await _box.put(AccountScope.scopedHiveKey(task.id), task);
  }

  Future<void> updateTask(Task task) async {
    await task.save();
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(AccountScope.scopedHiveKey(id));
  }

  Future<void> completeTask(String id) async {
    final task = _box.get(AccountScope.scopedHiveKey(id));
    if (task != null) {
      task.isComplete = true;
      await task.save();
    }
  }

  List<Task> getPendingTasks() {
    return getAllTasks().where((task) => !task.isComplete).toList();
  }

  List<Task> getCompletedTasks() {
    return getAllTasks().where((task) => task.isComplete).toList();
  }

  List<Task> getTasksByPriority() {
    final priorityOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
    final tasks = getAllTasks();
    tasks.sort((a, b) {
      final priorityA = priorityOrder[a.priority] ?? 999;
      final priorityB = priorityOrder[b.priority] ?? 999;
      return priorityA.compareTo(priorityB);
    });
    return tasks;
  }
}
