import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/notification_service.dart';
import '../data/habit_model.dart';
import '../domain/habit_notifier.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  final String? habitId;
  const AddHabitScreen({super.key, this.habitId});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController nameController;
  late final TextEditingController medicationDoseController;
  Habit? _editingHabit;

  String selectedIcon = '🏃';
  String frequency = 'Daily';
  List<int> selectedDays = [];
  bool isMedication = false;
  TimeOfDay? selectedReminderTime;
  final List<TimeOfDay> medicationTimes = [];

  final List<String> icons = const [
    '🏃',
    '💧',
    '📖',
    '🌙',
    '🍎',
    '💪',
    '🧘',
    '✍️',
    '🎸',
    '☀️',
    '🎯',
    '💊',
  ];

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    medicationDoseController = TextEditingController();
    _loadIfEditing();
  }

  void _loadIfEditing() {
    final id = widget.habitId;
    if (id == null || id.isEmpty) return;

    final repo = ref.read(habitRepositoryProvider);
    final matches = repo.getAllHabits().where((h) => h.id == id).toList();
    if (matches.isEmpty) return;
    final existing = matches.first;
    _editingHabit = existing;

    setState(() {
      selectedIcon = existing.icon;
      frequency = existing.frequency;
      selectedDays = List<int>.from(existing.targetDays);
      isMedication = existing.isMedication;
      selectedReminderTime = existing.reminderTime != null
          ? TimeOfDay(
              hour: int.parse(existing.reminderTime!.split(':')[0]),
              minute: int.parse(existing.reminderTime!.split(':')[1]),
            )
          : null;
      medicationDoseController.text = existing.medicationDose ?? '';
      medicationTimes.clear();
      medicationTimes.addAll(existing.medicationTimesOfDay);
      nameController.text = existing.name;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    medicationDoseController.dispose();
    super.dispose();
  }

  String _formatTimeString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDisplayTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickSingleReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );

    if (picked != null) {
      setState(() {
        selectedReminderTime = picked;
      });
    }
  }

  Future<void> _addMedicationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked == null) return;

    final value = _formatTimeString(picked);
    if (medicationTimes.contains(value)) return;

    setState(() {
      medicationTimes.add(picked);
      medicationTimes.sort((a, b) {
        final first = a.hour * 60 + a.minute;
        final second = b.hour * 60 + b.minute;
        return first.compareTo(second);
      });
    });
  }

  Future<void> _createHabit() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final reminderTime = !isMedication && selectedReminderTime != null
        ? _formatTimeString(selectedReminderTime!)
        : null;

    final habit = Habit.create(
      name: name,
      icon: selectedIcon,
      frequency: frequency,
      targetDays: frequency == 'Custom'
          ? List<int>.from(selectedDays)
          : const [],
      reminderTime: reminderTime,
      isMedication: isMedication,
      medicationDose:
          isMedication && medicationDoseController.text.trim().isNotEmpty
          ? medicationDoseController.text.trim()
          : null,
      medicationTimes: isMedication
          ? medicationTimes.map(_formatTimeString).toList()
          : const [],
    );
    Habit toSave = habit;
    if (_editingHabit != null) {
      // preserve id and createdAt when editing
      toSave = Habit(
        id: _editingHabit!.id,
        name: name,
        icon: selectedIcon,
        frequency: frequency,
        targetDays: frequency == 'Custom'
            ? List<int>.from(selectedDays)
            : const [],
        createdAt: _editingHabit!.createdAt,
        isArchived: _editingHabit!.isArchived,
        reminderTime: reminderTime,
        isMedication: isMedication,
        medicationDose:
            isMedication && medicationDoseController.text.trim().isNotEmpty
            ? medicationDoseController.text.trim()
            : null,
        medicationTimes: isMedication
            ? medicationTimes.map(_formatTimeString).toList()
            : const [],
      );
      // cancel previous notifications if needed
      if (_editingHabit!.isMedication) {
        await NotificationService.cancelMedicationReminders(
          _editingHabit!.id,
          _editingHabit!.medicationTimes.length,
        );
      } else if (_editingHabit!.reminderTime != null) {
        await NotificationService.cancelHabitReminder(
          NotificationService.habitNotificationId(_editingHabit!.id),
        );
      }
    }

    await ref.read(habitsProvider.notifier).addHabit(toSave);
    if (isMedication && medicationTimes.isNotEmpty) {
      await NotificationService.scheduleMedicationReminders(toSave);
    } else if (!isMedication && selectedReminderTime != null) {
      await NotificationService.scheduleHabitReminder(
        id: NotificationService.habitNotificationId(toSave.id),
        habitName: toSave.name,
        reminderTime: selectedReminderTime!,
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _deleteHabit() async {
    final editingHabit = _editingHabit;
    if (editingHabit == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('"${editingHabit.name}" will be archived.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await ref.read(habitsProvider.notifier).archiveHabit(editingHabit.id);
    if (mounted) context.go('/habits');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/habits');
            }
          },
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        title: Text(
          _editingHabit == null ? 'New Habit' : 'Edit Habit',
          style: TextStyle(
            color: AppColors.habits,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_editingHabit != null)
            IconButton(
              onPressed: _deleteHabit,
              icon: Icon(Icons.delete_outline, color: AppColors.error),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Habit name...',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    SizedBox(height: AppSizes.lg),
                    Row(
                      children: [
                        Text(
                          'This is a medication',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontSm,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isMedication,
                          activeColor: AppColors.habits,
                          onChanged: (value) {
                            setState(() {
                              isMedication = value;
                              if (isMedication) {
                                selectedReminderTime = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.lg),
                    Text(
                      'PICK AN ICON',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: AppSizes.fontXs,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: icons.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        final icon = icons[index];
                        final selected = icon == selectedIcon;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.habits
                                  : AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: AppSizes.lg),
                    Text(
                      'FREQUENCY',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: AppSizes.fontXs,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    Row(
                      children: ['Daily', 'Weekdays', 'Custom'].map((item) {
                        final selected = item == frequency;
                        return Padding(
                          padding: EdgeInsets.only(right: AppSizes.sm),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                frequency = item;
                                if (frequency != 'Custom') {
                                  selectedDays = [];
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                                vertical: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.habits
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLg,
                                ),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: AppSizes.fontSm,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (frequency == 'Custom') ...[
                      SizedBox(height: AppSizes.md),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: List.generate(_days.length, (index) {
                          final isSelected = selectedDays.contains(index);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedDays.remove(index);
                                } else {
                                  selectedDays.add(index);
                                  selectedDays.sort();
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                                vertical: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.habits
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLg,
                                ),
                              ),
                              child: Text(
                                _days[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: AppSizes.fontSm,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      curve: Curves.easeInOut,
                      child: isMedication
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: AppSizes.lg),
                                Text(
                                  'DOSAGE',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: AppSizes.fontXs,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: AppSizes.sm),
                                TextField(
                                  controller: medicationDoseController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '500mg, 1 tablet, 2 drops...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: AppSizes.fontSm,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSizes.lg),
                                Text(
                                  'REMINDER TIMES',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: AppSizes.fontXs,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: AppSizes.xs),
                                Text(
                                  'Up to 4 daily reminders',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: AppSizes.sm),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: medicationTimes.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: AppSizes.sm),
                                  itemBuilder: (context, index) {
                                    final time = medicationTimes[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.alarm,
                                            color: AppColors.habits,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _formatDisplayTime(time),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                medicationTimes.removeAt(index);
                                              });
                                            },
                                            icon: Icon(
                                              Icons.close,
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (medicationTimes.length < 4) ...[
                                  SizedBox(height: AppSizes.sm),
                                  GestureDetector(
                                    onTap: _addMedicationTime,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: AppColors.habits,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Add reminder time',
                                            style: TextStyle(
                                              color: AppColors.habits,
                                              fontSize: AppSizes.fontSm,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: AppSizes.lg),
                                Text(
                                  'REMINDER',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: AppSizes.fontXs,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: AppSizes.sm),
                                GestureDetector(
                                  onTap: _pickSingleReminderTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_outlined,
                                          color: AppColors.habits,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            selectedReminderTime == null
                                                ? 'No reminder'
                                                : 'Daily at ${selectedReminderTime!.format(context)}',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: AppSizes.fontSm,
                                            ),
                                          ),
                                        ),
                                        if (selectedReminderTime != null)
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedReminderTime = null;
                                              });
                                            },
                                            icon: Icon(
                                              Icons.close,
                                              color: AppColors.textHint,
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
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : _createHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.habits,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Text(
                  _editingHabit == null ? 'Create Habit' : 'Save Changes',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
