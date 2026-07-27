import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/habit_model.dart';
import '../domain/habit_notifier.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
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
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Habits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: _WeeklyStrip(days: _days),
          ),
          SizedBox(height: AppSizes.md),
          Expanded(
            child: habits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_florist_outlined,
                          size: 64,
                          color: AppColors.habits,
                        ),
                        SizedBox(height: AppSizes.sm),
                        Text(
                          'Build your first habit',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: AppSizes.fontMd,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.md,
                      0,
                      AppSizes.md,
                      96 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return _HabitCard(habit: habit);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.habits,
        onPressed: () => context.push('/habits/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WeeklyStrip extends StatelessWidget {
  const _WeeklyStrip({required this.days});

  final List<String> days;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // Mon=1 ... Sun=7

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        final dayIndex = index + 1;
        final isToday = dayIndex == today;
        final isPast = dayIndex < today;

        Color circleColor;
        Color textColor;
        FontWeight fontWeight = FontWeight.w500;

        if (isToday) {
          circleColor = AppColors.habits;
          textColor = Colors.white;
          fontWeight = FontWeight.bold;
        } else if (isPast) {
          circleColor = AppColors.habits.withValues(alpha: 0.6);
          textColor = Colors.white;
        } else {
          circleColor = AppColors.surfaceVariant;
          textColor = AppColors.textHint;
        }

        return Column(
          children: [
            Text(
              days[index],
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: AppSizes.fontXs,
              ),
            ),
            SizedBox(height: AppSizes.xs),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayIndex',
                style: TextStyle(
                  color: textColor,
                  fontSize: AppSizes.fontSm,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  const _HabitCard({required this.habit});

  final Habit habit;

  TimeOfDay? _parseMedicationTime(String value) {
    try {
      final parts = value.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  bool _isPastDose(TimeOfDay now, TimeOfDay doseTime) {
    final nowMinutes = now.hour * 60 + now.minute;
    final doseMinutes = doseTime.hour * 60 + doseTime.minute;
    return nowMinutes > doseMinutes;
  }

  Future<void> _confirmDeleteHabit(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('"${habit.name}" will be archived.'),
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

    if (shouldDelete == true) {
      await ref.read(habitsProvider.notifier).archiveHabit(habit.id);
    }
  }

  Widget _buildMedicationDoseStatus({
    required BuildContext context,
    required WidgetRef ref,
    required String todayDate,
    required int doseIndex,
    required bool isTaken,
    required bool isPast,
  }) {
    final onTap = () {
      ref
          .read(habitsProvider.notifier)
          .toggleMedicationDose(habit.id, todayDate, doseIndex);
    };

    if (isTaken) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.habits,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        ),
      );
    }

    if (!isTaken && !isPast) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: AppColors.habits, width: 2),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(habitRepositoryProvider);
    final todayStatus = ref.watch(todayHabitStatusProvider);
    final isCompleted = todayStatus[habit.id] ?? false;
    final streak = repository.getCurrentStreak(habit.id);
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = TimeOfDay.now();
    final medicationTimesOfDay = habit.medicationTimesOfDay;

    final allMedicationDosesTaken =
        habit.isMedication &&
        medicationTimesOfDay.isNotEmpty &&
        List.generate(
          medicationTimesOfDay.length,
          (i) => repository.isMedicationDoseTaken(habit.id, todayDate, i),
        ).every((taken) => taken);

    TimeOfDay? nextUntakenMedicationTime;
    bool hasMissedUntakenDose = false;
    if (habit.isMedication && medicationTimesOfDay.isNotEmpty) {
      for (var i = 0; i < medicationTimesOfDay.length; i++) {
        final doseTime = medicationTimesOfDay[i];
        final isTaken = repository.isMedicationDoseTaken(
          habit.id,
          todayDate,
          i,
        );
        if (isTaken) continue;

        if (_isPastDose(now, doseTime)) {
          hasMissedUntakenDose = true;
        } else {
          nextUntakenMedicationTime = doseTime;
          break;
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.md - AppSizes.xs),
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/habits/detail/${habit.id}'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.habits.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  alignment: Alignment.center,
                  child: Text(habit.icon, style: const TextStyle(fontSize: 24)),
                ),
                SizedBox(width: AppSizes.md),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/habits/detail/${habit.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.fontLg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (habit.isMedication)
                            const Text(' 💊', style: TextStyle(fontSize: 12)),
                          IconButton(
                            onPressed: () => _confirmDeleteHabit(context, ref),
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            tooltip: 'Delete habit',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.xs),
                      if (habit.isMedication &&
                          habit.medicationTimes.isNotEmpty) ...[
                        Text(
                          allMedicationDosesTaken
                              ? 'All doses taken for today ✓'
                              : nextUntakenMedicationTime != null
                              ? 'Next dose: ${nextUntakenMedicationTime.format(context)}'
                              : hasMissedUntakenDose
                              ? 'Dose not taken'
                              : 'Next dose: --',
                          style: TextStyle(
                            color: allMedicationDosesTaken
                                ? AppColors.expenses
                                : hasMissedUntakenDose
                                ? AppColors.error
                                : AppColors.habits,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                      ],
                      Row(
                        children: [
                          Text(
                            '$streak',
                            style: TextStyle(
                              color: AppColors.habits,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(' 🔥 '),
                          Text(
                            'streak',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (habit.isMedication && habit.medicationTimes.isNotEmpty) ...[
                  SizedBox(height: AppSizes.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(habit.medicationTimes.length, (
                      index,
                    ) {
                      final doseTime = _parseMedicationTime(
                        habit.medicationTimes[index],
                      );
                      if (doseTime == null) return const SizedBox.shrink();

                      final isTaken = repository.isMedicationDoseTaken(
                        habit.id,
                        todayDate,
                        index,
                      );
                      final isPast = _isPastDose(now, doseTime);

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == habit.medicationTimes.length - 1
                              ? 0
                              : AppSizes.sm,
                        ),
                        child: Row(
                          children: [
                            Text(
                              doseTime.format(context),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            _buildMedicationDoseStatus(
                              context: context,
                              ref: ref,
                              todayDate: todayDate,
                              doseIndex: index,
                              isTaken: isTaken,
                              isPast: isPast,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          if (!habit.isMedication)
            GestureDetector(
              onTap: () =>
                  ref.read(habitsProvider.notifier).toggleToday(habit.id),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.habits : Colors.transparent,
                  border: Border.all(color: AppColors.habits, width: 2),
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
