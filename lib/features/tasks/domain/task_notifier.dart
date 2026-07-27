import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackit/core/utils/notification_service.dart';
import 'package:trackit/features/badges/data/badge_service.dart';

import '../data/task_model.dart';
import '../data/task_repository.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

final tasksProvider =
    StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskNotifier(repository, ref);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final TaskRepository repository;
  final Ref ref;

  TaskNotifier(this.repository, this.ref) : super([]) {
    loadTasks();
  }

  void loadTasks() {
    state = repository.getAllTasks();
  }

  Future<void> addTask(Task task) async {
    await repository.addTask(task);
    loadTasks();
    if (task.dueDate != null) {
      await NotificationService.scheduleTaskNotification(
        id: NotificationService.taskNotificationId(task.id),
        taskTitle: task.title,
        dueDate: task.dueDate!,
      );
    }
  }

  Future<void> deleteTask(String id) async {
    await repository.deleteTask(id);
    loadTasks();
    await NotificationService.cancelTaskNotification(
      NotificationService.taskNotificationId(id),
    );
  }

  Future<void> completeTask(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    await repository.completeTask(id);
    loadTasks();
    await NotificationService.cancelTaskNotification(
      NotificationService.taskNotificationId(id),
    );

    // Badge checks
    final badgeService = ref.read(badgeServiceProvider);
    final allTasks = repository.getAllTasks();
    final totalCompleted = allTasks.where((t) => t.isComplete).length;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = allTasks
        .where((t) =>
            t.isComplete &&
            t.createdAt.isAfter(weekStart))
        .length;

    // Check if completed on due date
    final isOnDueDate = task.dueDate != null &&
        DateFormat('yyyy-MM-dd').format(task.dueDate!) ==
            DateFormat('yyyy-MM-dd').format(now);

    await badgeService.checkAndAward('task_completed', {
      'totalCompleted': totalCompleted,
      'completedThisWeek': completedThisWeek,
      'isOnDueDate': isOnDueDate,
    });
  }

  List<Task> get pendingTasks =>
      state.where((task) => !task.isComplete).toList();

  List<Task> get completedTasks =>
      state.where((task) => task.isComplete).toList();

  List<Task> get urgentTasks => pendingTasks
      .where((task) =>
          task.priority == 'Urgent' || task.priority == 'High')
      .toList();
}

final selectedFilterProvider = StateProvider<String>((ref) => 'All');