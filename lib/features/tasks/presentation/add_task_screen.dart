import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/task_model.dart';
import '../domain/task_notifier.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  DateTime? selectedDate;
  String selectedPriority = 'Medium';

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  // Priority config
  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  Color _priorityColor(String p) {
    switch (p) {
      case 'Urgent': return const Color(0xFFE24A4A);
      case 'High': return const Color(0xFFF97316);
      case 'Medium': return const Color(0xFFEAB308);
      case 'Low': return const Color(0xFF22C55E);
      default: return AppColors.textHint;
    }
  }

  Color _priorityBgColor(String p) => _priorityColor(p).withOpacity(0.15);

  String _priorityEmoji(String p) {
    switch (p) {
      case 'Urgent': return '🔴';
      case 'High': return '🟠';
      case 'Medium': return '🟡';
      case 'Low': return '🟢';
      default: return '⚪';
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.tasks,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;

    setState(() {
      selectedDate = time == null
          ? date
          : DateTime(
              date.year, date.month, date.day,
              time.hour, time.minute,
            );
    });
  }

  Future<void> _createTask() async {
    if (titleController.text.trim().isEmpty) return;

    final task = Task.create(
      title: titleController.text.trim(),
      description: descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      dueDate: selectedDate,
      priority: selectedPriority,
    );

    await ref.read(tasksProvider.notifier).addTask(task);
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
          'New Task',
          style: TextStyle(
            color: AppColors.tasks,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.tasks),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.tasks, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: descController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add description...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // Due date
            Text(
              'DUE DATE',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.tasks,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate == null
                          ? 'No due date'
                          : DateFormat('dd MMM yyyy, hh:mm a')
                              .format(selectedDate!),
                      style: TextStyle(
                        color: selectedDate == null
                            ? AppColors.textHint
                            : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (selectedDate != null)
                      GestureDetector(
                        onTap: () => setState(() => selectedDate = null),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textHint,
                          size: 16,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Priority — THE FIX: clear visual selection state
            Text(
              'PRIORITY',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _priorities.map((priority) {
                final isSelected = selectedPriority == priority;
                final color = _priorityColor(priority);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: priority != _priorities.last ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedPriority = priority),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          // Selected = filled bg with color
                          color: isSelected
                              ? color.withOpacity(0.2)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            // Selected = colored border, thick
                            color: isSelected ? color : AppColors.border,
                            width: isSelected ? 2 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _priorityEmoji(priority),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priority,
                              style: TextStyle(
                                // Selected = colored text, bold
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            // Checkmark when selected
                            if (isSelected) ...[
                              const SizedBox(height: 2),
                              Icon(
                                Icons.check_circle,
                                color: color,
                                size: 12,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: titleController.text.trim().isEmpty
                    ? null
                    : _createTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Create Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}