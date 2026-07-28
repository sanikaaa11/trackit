import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/habit_model.dart';
import '../domain/habit_notifier.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final todayStatus = ref.watch(todayHabitStatusProvider);
    final repository = ref.watch(habitRepositoryProvider);

    final now = DateTime.now();
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayWeekday = now.weekday; // 1=Mon, 7=Sun

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Habits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, color: AppColors.habits),
            onPressed: () {},
          ),
        ],
      ),
      body: habits.isEmpty
          ? _EmptyState()
          : ListView(
              padding: EdgeInsets.all(AppSizes.md),
              children: [
                // Weekly strip
                _WeekStrip(
                  weekDays: weekDays,
                  todayWeekday: todayWeekday,
                  habits: habits,
                  todayStatus: todayStatus,
                ),
                SizedBox(height: AppSizes.md),

                // Habit cards
                ...habits.map(
                  (habit) => _HabitCard(
                    habit: habit,
                    isCompletedToday: todayStatus[habit.id] ?? false,
                    repository: repository,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.habits,
        onPressed: () => context.push('/habits/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekDays,
    required this.todayWeekday,
    required this.habits,
    required this.todayStatus,
  });

  final List<String> weekDays;
  final int todayWeekday;
  final List<Habit> habits;
  final Map<String, bool> todayStatus;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: AppSizes.fontXs,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: AppSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekday = index + 1; // 1=Mon
              final isToday = weekday == todayWeekday;
              final dayDate = now.subtract(
                Duration(days: todayWeekday - weekday),
              );
              final isFuture = dayDate.isAfter(now);

              return Column(
                children: [
                  Text(
                    weekDays[index],
                    style: TextStyle(
                      color: isToday
                          ? AppColors.habits
                          : AppColors.textHint,
                      fontSize: 11,
                      fontWeight: isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: AppSizes.xs),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.habits
                          : isFuture
                          ? Colors.transparent
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: isToday
                          ? null
                          : Border.all(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${dayDate.day}',
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : isFuture
                            ? AppColors.textHint
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends ConsumerStatefulWidget {
  const _HabitCard({
    required this.habit,
    required this.isCompletedToday,
    required this.repository,
  });

  final Habit habit;
  final bool isCompletedToday;
  final dynamic repository;

  @override
  ConsumerState<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<_HabitCard> {
  bool _showCalendar = false;

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final isCompleted = widget.isCompletedToday;
    final currentStreak =
        ref.watch(habitStreakProvider(habit.id))['current'] ?? 0;
    final repository = ref.watch(habitRepositoryProvider);

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Column(
          children: [
            // Main card row
            Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  // Habit icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.habits.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  // Name + streak
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              habit.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (habit.isMedication) ...[
                              SizedBox(width: AppSizes.xs),
                              Text(
                                '💊',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            Text(
                              '🔥',
                              style: const TextStyle(fontSize: 13),
                            ),
                            SizedBox(width: AppSizes.xs),
                            Text(
                              '$currentStreak day streak',
                              style: TextStyle(
                                color: currentStreak > 0
                                    ? AppColors.habits
                                    : AppColors.textHint,
                                fontSize: 13,
                                fontWeight: currentStreak > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Toggle calendar button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showCalendar = !_showCalendar),
                    child: Icon(
                      _showCalendar
                          ? Icons.keyboard_arrow_up
                          : Icons.calendar_month_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppSizes.sm),
                  // Complete checkbox
                  GestureDetector(
                    onTap: () => ref
                        .read(habitsProvider.notifier)
                        .toggleToday(habit.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.habits
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.habits,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Calendar heatmap (expandable)
            if (_showCalendar) ...[
              Divider(
                height: 1,
                color: AppColors.border,
              ),
              Padding(
                padding: EdgeInsets.all(AppSizes.md),
                child: _MonthCalendar(
                  habit: habit,
                  repository: repository,
                ),
              ),
            ],

            // Medication doses
            if (habit.isMedication && habit.medicationTimes.isNotEmpty)
              _MedicationDoses(habit: habit),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
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
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.habits.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.habits,
                  size: 20,
                ),
              ),
              title: Text(
                'Edit habit',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push('/habits/add', extra: widget.habit);
              },
            ),
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
                'Delete habit',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                ),
              ),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Delete habit?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'All streak data will be lost.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel',
                            style: TextStyle(color: AppColors.textHint)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  ref
                      .read(habitsProvider.notifier)
                      .archiveHabit(widget.habit.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Month calendar heatmap widget
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.habit,
    required this.repository,
  });

  final Habit habit;
  final dynamic repository;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1=Mon

    // Get completed dates for this month
    final logs = repository.getLogsForHabit(habit.id) as List;
    final completedDates = <String>{};
    for (final log in logs) {
      if (log.isCompleted) {
        final date = DateTime.tryParse(log.date as String);
        if (date != null &&
            date.month == now.month &&
            date.year == now.year) {
          completedDates.add(log.date as String);
        }
      }
    }

    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label
        Text(
          DateFormat('MMMM yyyy').format(now),
          style: TextStyle(
            color: AppColors.habits,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: AppSizes.sm),
        // Day name headers
        Row(
          children: dayNames
              .map(
                (d) => Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: AppSizes.xs),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: daysInMonth + firstWeekday - 1,
          itemBuilder: (context, index) {
            // Empty cells before first day
            if (index < firstWeekday - 1) {
              return const SizedBox.shrink();
            }

            final day = index - firstWeekday + 2;
            final date = DateTime(now.year, now.month, day);
            final dateStr =
                DateFormat('yyyy-MM-dd').format(date);
            final isCompleted = completedDates.contains(dateStr);
            final isToday = day == now.day;
            final isFuture = date.isAfter(now);

            return Container(
              decoration: BoxDecoration(
                // Completed days get tinted
                color: isCompleted
                    ? AppColors.habits.withOpacity(0.35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                // Today gets border
                border: isToday
                    ? Border.all(
                        color: AppColors.habits,
                        width: 1.5,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  color: isCompleted
                      ? AppColors.habits
                      : isFuture
                      ? AppColors.textHint.withOpacity(0.4)
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isToday || isCompleted
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MedicationDoses extends ConsumerWidget {
  const _MedicationDoses({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(habitRepositoryProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = TimeOfDay.now();

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        0,
        AppSizes.md,
        AppSizes.md,
      ),
      child: Column(
        children:
            List.generate(habit.medicationTimes.length, (i) {
          final timeStr = habit.medicationTimes[i];
          final parts = timeStr.split(':');
          final doseTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
          final isTaken = repository.isMedicationDoseTaken(
            habit.id,
            today,
            i,
          );
          final isPast = doseTime.hour < now.hour ||
              (doseTime.hour == now.hour &&
                  doseTime.minute <= now.minute);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '${doseTime.hour.toString().padLeft(2, '0')}:${doseTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (isTaken)
                  GestureDetector(
                    onTap: () => ref
                        .read(habitsProvider.notifier)
                        .toggleMedicationDose(habit.id, today, i),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.habits,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                else if (!isPast)
                  GestureDetector(
                    onTap: () => ref
                        .read(habitsProvider.notifier)
                        .toggleMedicationDose(habit.id, today, i),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.habits,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 14,
                      ),
                      SizedBox(width: AppSizes.xs),
                      Text(
                        'Dose not taken',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      GestureDetector(
                        onTap: () => ref
                            .read(habitsProvider.notifier)
                            .toggleMedicationDose(
                                habit.id, today, i),
                        child: Text(
                          'Mark taken',
                          style: TextStyle(
                            color: AppColors.habits,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌱', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Build your first habit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to get started',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}