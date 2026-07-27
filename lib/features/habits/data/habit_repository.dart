import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/account_scope.dart';
import 'habit_model.dart';

class HabitRepository {
  static const String habitsBoxName = 'habits_box';
  static const String logsBoxName = 'habit_logs_box';
  static const String medDosesBoxName = 'med_doses_box';

  Future<void> init() async {
    if (!Hive.isBoxOpen(habitsBoxName)) {
      await Hive.openBox<Habit>(habitsBoxName);
    }
    if (!Hive.isBoxOpen(logsBoxName)) {
      await Hive.openBox<HabitLog>(logsBoxName);
    }
    if (!Hive.isBoxOpen(medDosesBoxName)) {
      await Hive.openBox<bool>(medDosesBoxName);
    }
  }

  Box<Habit> get _habitsBox => Hive.box<Habit>(habitsBoxName);
  Box<HabitLog> get _logsBox => Hive.box<HabitLog>(logsBoxName);
  Box<bool> get _medDosesBox => Hive.box<bool>(medDosesBoxName);

  List<Habit> getAllHabits() {
    final habits = _habitsBox.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _habitsBox.get(key))
        .whereType<Habit>()
        .where((habit) => !habit.isArchived)
        .toList();
    habits.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return habits;
  }

  Future<void> addHabit(Habit habit) async {
    await _habitsBox.put(AccountScope.scopedHiveKey(habit.id), habit);
  }

  Future<void> archiveHabit(String id) async {
    final habit = _habitsBox.get(AccountScope.scopedHiveKey(id));
    if (habit == null) return;
    habit.isArchived = true;
    await habit.save();
  }

  Future<void> toggleHabitForDate(String habitId, String date) async {
    final logId = '${habitId}_$date';
    final scopedLogId = AccountScope.scopedHiveKey(logId);
    final existing = _logsBox.get(scopedLogId);

    if (existing != null) {
      await _logsBox.delete(scopedLogId);
      return;
    }

    final log = HabitLog.create(
      habitId: habitId,
      date: date,
      isCompleted: true,
    );
    await _logsBox.put(scopedLogId, log);
  }

  bool isCompletedForDate(String habitId, String date) {
    final log = _logsBox.get(AccountScope.scopedHiveKey('${habitId}_$date'));
    return log?.isCompleted ?? false;
  }

  Future<void> toggleMedicationDose(
    String habitId,
    String date,
    int doseIndex,
  ) async {
    final key = '${habitId}_${date}_dose_$doseIndex';
    final existing = _medDosesBox.get(key) ?? false;
    await _medDosesBox.put(key, !existing);
  }

  bool isMedicationDoseTaken(String habitId, String date, int doseIndex) {
    final key = '${habitId}_${date}_dose_$doseIndex';
    return _medDosesBox.get(key) ?? false;
  }

  List<HabitLog> getLogsForHabit(String habitId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 42));

    final logs = _logsBox.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _logsBox.get(key))
        .whereType<HabitLog>()
        .where((log) {
          if (log.habitId != habitId || !log.isCompleted) return false;
          final logDate = _parseDate(log.date);
          return logDate != null && !logDate.isBefore(_startOfDay(cutoff));
        })
        .toList();

    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  int getCurrentStreak(String habitId) {
    final completedDates = _completedDateSet(habitId);
    int streak = 0;
    final today = _startOfDay(DateTime.now());

    // Start from today, if today not done then start from yesterday
    // (don't break streak just because today isn't done yet)
    var day = completedDates.contains(_formatDate(today))
        ? today
        : today.subtract(const Duration(days: 1));

    while (completedDates.contains(_formatDate(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int getLongestStreak(String habitId) {
    final completed = _completedDateSet(habitId)
        .map(_parseDate)
        .whereType<DateTime>()
        .map(_startOfDay)
        .toList();

    if (completed.isEmpty) return 0;

    completed.sort((a, b) => a.compareTo(b));

    int longest = 1;
    int current = 1;

    for (int i = 1; i < completed.length; i++) {
      final prev = completed[i - 1];
      final next = completed[i];
      final diff = next.difference(prev).inDays;

      if (diff == 1) {
        current++;
      } else if (diff > 1) {
        current = 1;
      }
      if (current > longest) longest = current;
    }

    return longest;
  }

  int getTotalCompletions(String habitId) {
    return _logsBox.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _logsBox.get(key))
        .whereType<HabitLog>()
        .where((log) => log.habitId == habitId && log.isCompleted)
        .length;
  }

  Map<String, bool> getTodayStatus() {
    final today = _formatDate(DateTime.now());
    final habits = getAllHabits();
    return {
      for (final habit in habits)
        habit.id: isCompletedForDate(habit.id, today),
    };
  }

  Set<String> _completedDateSet(String habitId) {
    return _logsBox.keys
        .where(AccountScope.matchesCurrentScopeKey)
        .map((key) => _logsBox.get(key))
        .whereType<HabitLog>()
        .where((log) => log.habitId == habitId && log.isCompleted)
        .map((log) => log.date)
        .toSet();
  }

  DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // ── Cross-habit badge helpers ──────────────────────────────────────

  /// Consecutive days (ending today, or yesterday if today isn't fully
  /// done yet) where every active habit was completed.
  int getAllCompletedConsecutiveStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;

    bool dayFullyComplete(DateTime d) {
      final dateStr = _formatDate(d);
      return habits.every((h) => isCompletedForDate(h.id, dateStr));
    }

    final today = _startOfDay(DateTime.now());
    var day = dayFullyComplete(today)
        ? today
        : today.subtract(const Duration(days: 1));

    int streak = 0;
    while (dayFullyComplete(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Consecutive days (ending today, or yesterday if today isn't done
  /// yet) where exactly one active habit was completed.
  int getExactlyOneCompletedConsecutiveStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;

    bool dayExactlyOne(DateTime d) {
      final dateStr = _formatDate(d);
      final count =
          habits.where((h) => isCompletedForDate(h.id, dateStr)).length;
      return count == 1;
    }

    final today = _startOfDay(DateTime.now());
    var day = dayExactlyOne(today)
        ? today
        : today.subtract(const Duration(days: 1));

    int streak = 0;
    while (dayExactlyOne(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// True if this habit was completed today after 3+ consecutive missed
  /// days (i.e. a gap of 4+ days since its last completion before today).
  bool hasResumedAfterMiss(String habitId, {int missThreshold = 3}) {
    final today = _startOfDay(DateTime.now());
    final todayStr = _formatDate(today);

    if (!isCompletedForDate(habitId, todayStr)) return false;

    final priorCompletions = _completedDateSet(habitId)
        .map(_parseDate)
        .whereType<DateTime>()
        .map(_startOfDay)
        .where((d) => d.isBefore(today))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (priorCompletions.isEmpty) return false;

    final lastBeforeToday = priorCompletions.last;
    final gapDays = today.difference(lastBeforeToday).inDays;
    final missedDays = gapDays - 1;

    return missedDays >= missThreshold;
  }
}