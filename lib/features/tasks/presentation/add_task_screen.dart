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
  late final TextEditingController titleController;
  late final TextEditingController descController;
  DateTime? selectedDate;
  String priority = 'Medium';

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreateTask() async {
    if (titleController.text.isEmpty) return;

    final task = Task.create(
      title: titleController.text,
      description: descController.text.isEmpty ? null : descController.text,
      dueDate: selectedDate,
      priority: priority,
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        title: const Text(
          'New Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 24),
                border: InputBorder.none,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.tasks),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.tasks, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: AppSizes.md),
            TextField(
              controller: descController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add description...',
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(AppSizes.md),
              ),
            ),
            SizedBox(height: AppSizes.xl),
            Text(
              'DUE DATE',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: _selectDateTime,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.tasks),
                    SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'No due date'
                            : DateFormat(
                                'MMM dd, yyyy • hh:mm a',
                              ).format(selectedDate!),
                        style: TextStyle(
                          color: selectedDate == null
                              ? AppColors.textHint
                              : Colors.white,
                          fontSize: AppSizes.fontMd,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSizes.xl),
            Text(
              'PRIORITY',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                final isSelected = priority == p;
                return GestureDetector(
                  onTap: () => setState(() => priority = p),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityBgColor(p),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getPriorityBorderColor(p),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        color: _getPriorityTextColor(p),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: AppSizes.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: titleController.text.isEmpty
                    ? null
                    : _handleCreateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tasks,
                  disabledBackgroundColor: AppColors.textHint.withOpacity(0.3),
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.md + AppSizes.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Text(
                  'Create Task',
                  style: TextStyle(
                    color: titleController.text.isEmpty
                        ? AppColors.textHint
                        : Colors.white,
                    fontSize: AppSizes.fontMd,
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
}
