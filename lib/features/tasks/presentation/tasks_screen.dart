import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/task_model.dart';
import '../domain/task_notifier.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  List<Task> _getFilteredTasks(List<Task> tasks, String filter) {
    switch (filter) {
      case 'Pending':
        return tasks.where((task) => !task.isComplete).toList();
      case 'Completed':
        return tasks.where((task) => task.isComplete).toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    final filteredTasks = _getFilteredTasks(tasks, selectedFilter);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Tasks',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.search),
            color: AppColors.textSecondary,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            child: Row(
              children: ['All', 'Pending', 'Completed'].map((filter) {
                final isSelected = selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedFilterProvider.notifier).state = filter;
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    margin: EdgeInsets.only(right: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.tasks
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: AppSizes.md),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.textHint,
                          size: 64,
                        ),
                        SizedBox(height: AppSizes.md),
                        Text(
                          'No tasks here!',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: AppSizes.fontMd,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPadding,
                    ),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _TaskCard(
                        task: task,
                        onComplete: () {
                          ref
                              .read(tasksProvider.notifier)
                              .completeTask(task.id);
                        },
                        onDelete: () {
                          ref.read(tasksProvider.notifier).deleteTask(task.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/add'),
        backgroundColor: AppColors.tasks,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  Color _getPriorityBgColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return const Color(0x26E24A4A);
      case 'High':
        return const Color(0x26F97316);
      case 'Medium':
        return const Color(0x26EAB308);
      case 'Low':
        return const Color(0x2622C55E);
      default:
        return const Color(0x26888780);
    }
  }

  Color _getPriorityTextColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return const Color(0xFFE24A4A);
      case 'High':
        return const Color(0xFFF97316);
      case 'Medium':
        return const Color(0xFFEAB308);
      case 'Low':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF888780);
    }
  }

  Color _getPriorityBorderColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return const Color(0x40E24A4A);
      case 'High':
        return const Color(0x40F97316);
      case 'Medium':
        return const Color(0x40EAB308);
      case 'Low':
        return const Color(0x4022C55E);
      default:
        return const Color(0x40888780);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSizes.md),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        margin: EdgeInsets.only(bottom: AppSizes.sm),
        padding: EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isComplete ? AppColors.tasks : Colors.transparent,
                  border: Border.all(
                    color: task.isComplete ? AppColors.tasks : AppColors.border,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: task.isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.w600,
                      decoration: task.isComplete
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    SizedBox(height: AppSizes.xs),
                    Text(
                      DateFormat('MMM dd, yyyy').format(task.dueDate!),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontSm,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSizes.md),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityBgColor(task.priority),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getPriorityBorderColor(task.priority),
                  width: 1,
                ),
              ),
              child: Text(
                task.priority,
                style: TextStyle(
                  color: _getPriorityTextColor(task.priority),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
