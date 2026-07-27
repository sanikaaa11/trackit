import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trackit/core/utils/notification_service.dart';

import '../data/habit_model.dart';
import '../data/habit_repository.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository());

final habitsProvider =
    StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitNotifier(repository, ref);
});

final todayHabitStatusProvider = StateProvider<Map<String, bool>>(
  (ref) => <String, bool>{},
);

// Streak cache provider — rebuilds when habits state changes
final habitStreakProvider =
    Provider.family<Map<String, int>, String>((ref, habitId) {
  // Watch habitsProvider so this rebuilds when habits change
  ref.watch(habitsProvider);
  final repository = ref.read(habitRepositoryProvider);
  return {
    'current': repository.getCurrentStreak(habitId),
    'longest': repository.getLongestStreak(habitId),
    'total': repository.getTotalCompletions(habitId),
  };
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  HabitNotifier(this.repository, this.ref) : super([]) {
    _load();
  }

  final HabitRepository repository;
  final Ref ref;

  void _load() {
    state = repository.getAllHabits();
    _syncTodayStatus();
  }

  void _syncTodayStatus() {
    // Deferred to the next microtask so this never runs while
    // HabitNotifier (or any provider) is still being constructed —
    // Riverpod disallows writing to another provider mid-initialization.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(todayHabitStatusProvider.notifier).state =
          repository.getTodayStatus();
    });
  }

  void loadHabits() {
    state = List.from(repository.getAllHabits()); // force new list reference
    _syncTodayStatus();
  }

  Future<void> addHabit(Habit habit) async {
    await repository.addHabit(habit);
    loadHabits();
  }

  Future<void> archiveHabit(String id) async {
    final habitMatches = state.where((item) => item.id == id).toList();
    final habit = habitMatches.isNotEmpty ? habitMatches.first : null;

    if (habit?.isMedication == true) {
      await NotificationService.cancelMedicationReminders(
        id,
        habit?.medicationTimes.length ?? 0,
      );
    } else {
      await NotificationService.cancelHabitReminder(
        NotificationService.habitNotificationId(id),
      );
    }
    await repository.archiveHabit(id);
    loadHabits();
  }

  Future<void> toggleToday(String habitId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await repository.toggleHabitForDate(habitId, today);
    // Force full reload so streaks recalculate
    loadHabits();
  }

  Future<void> toggleMedicationDose(
    String habitId,
    String date,
    int doseIndex,
  ) async {
    await repository.toggleMedicationDose(habitId, date, doseIndex);
    loadHabits();
  }
}

final habitLogsProvider =
    Provider.family<List<HabitLog>, String>((ref, habitId) {
  // Watch habitsProvider so logs refresh when habits change
  ref.watch(habitsProvider);
  final repository = ref.read(habitRepositoryProvider);
  return repository.getLogsForHabit(habitId);
});