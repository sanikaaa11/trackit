import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/account_scope.dart';

const List<Map<String, String>> kBadgeDefinitions = [
  {
    'id': 'day1_energy',
    'name': 'Day 1 Energy',
    'emoji': '⚡',
    'description': 'Open TrackIt for the first time',
    'series': 'Starter',
    'assetPath': 'assets/badges/day1_energy.png',
  },
  {
    'id': 'first_task_done',
    'name': 'First Task Done',
    'emoji': '🚀',
    'description': 'Complete your very first task',
    'series': 'Starter',
    'assetPath': 'assets/badges/first_task_done.png',
  },
  {
    'id': 'streak_beast',
    'name': 'Streak Beast',
    'emoji': '🐉',
    'description': '7-day habit streak',
    'series': 'Consistency',
    'assetPath': 'assets/badges/streak_beast.png',
  },
  {
    'id': 'unstoppable',
    'name': 'Unstoppable',
    'emoji': '💀',
    'description': '30-day habit streak',
    'series': 'Consistency',
    'assetPath': 'assets/badges/unstoppable.png',
  },
  {
    'id': 'task_slayer',
    'name': 'Task Slayer',
    'emoji': '⚔️',
    'description': 'Complete 10 tasks in a week',
    'series': 'Productivity',
    'assetPath': 'assets/badges/task_slayer.png',
  },
  {
    'id': 'overachiever',
    'name': 'Overachiever',
    'emoji': '🤯',
    'description': 'Complete all habits 7 days in a row',
    'series': 'Productivity',
    'assetPath': 'assets/badges/overachiever.png',
  },
  {
    'id': 'locked_in',
    'name': 'Locked In',
    'emoji': '🎧',
    'description': 'Open TrackIt 14 days in a row',
    'series': 'Focus',
    'assetPath': 'assets/badges/locked_in.png',
  },
  {
    'id': 'monk_mode',
    'name': 'Monk Mode',
    'emoji': '🧘',
    'description': 'Complete all habits 7 days in a row',
    'series': 'Focus',
    'assetPath': 'assets/badges/monk_mode.png',
  },
  {
    'id': 'bare_minimum',
    'name': 'Bare Minimum',
    'emoji': '👑',
    'description': 'Complete exactly 1 habit for 7 days',
    'series': 'Gen Z',
    'assetPath': 'assets/badges/bare_minimum.png',
  },
  {
    'id': 'last_minute_god',
    'name': 'Last Minute God',
    'emoji': '😭',
    'description': 'Complete 3 tasks on their due date',
    'series': 'Gen Z',
    'assetPath': 'assets/badges/last_minute_god.png',
  },
  {
    'id': 'touch_grass',
    'name': 'Touch Grass',
    'emoji': '🌿',
    'description': 'Return after 2+ days away',
    'series': 'Gen Z',
    'assetPath': 'assets/badges/touch_grass.png',
  },
  {
    'id': 'comeback_arc',
    'name': 'Comeback Arc',
    'emoji': '📈',
    'description': 'Resume a habit after 3+ missed days',
    'series': 'Gen Z',
    'assetPath': 'assets/badges/comeback_arc.png',
  },
  {
    'id': 'budget_villain',
    'name': 'Budget Villain',
    'emoji': '💰',
    'description': 'Go over budget for the month',
    'series': 'Module',
    'assetPath': 'assets/badges/budget_villain.png',
  },
  {
    'id': 'dear_diary',
    'name': 'Dear Diary',
    'emoji': '📔',
    'description': 'Write your first journal entry',
    'series': 'Module',
    'assetPath': 'assets/badges/dear_diary.png',
  },
];

final badgeServiceProvider = Provider<BadgeService>((ref) => BadgeService());

class BadgeService {
  static const String _boxName = 'badges_box';
  static const String _lastOpenKey = 'badge_last_open';
  static const String _openStreakKey = 'badge_open_streak';
  static const String _lastMinuteKey = 'badge_last_minute_count';

  Box<bool> get _box => Hive.box<bool>(_boxName);

  bool isEarned(String badgeId) {
    return _box.get(AccountScope.scopedHiveKey(badgeId)) ?? false;
  }

  List<String> getEarnedBadgeIds() {
    return kBadgeDefinitions
        .map((b) => b['id']!)
        .where(isEarned)
        .toList();
  }

  List<Map<String, String>> getEarnedBadges() {
    final ids = getEarnedBadgeIds().toSet();
    return kBadgeDefinitions
        .where((b) => ids.contains(b['id']))
        .toList()
        .reversed
        .toList();
  }

  Future<void> awardBadge(String badgeId) async {
    if (isEarned(badgeId)) return;
    await _box.put(AccountScope.scopedHiveKey(badgeId), true);
  }

  Future<String?> checkAndAward(
    String trigger,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (trigger) {
        case 'app_opened':
          return await _onAppOpened();
        case 'task_completed':
          return await _onTaskCompleted(data);
        case 'habit_toggled':
          return await _onHabitToggled(data);
        case 'journal_written':
          return await _onJournalWritten();
        case 'expense_logged':
          return await _onExpenseLogged(data);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> _onAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();

    // Day 1 Energy — very first open
    if (!isEarned('day1_energy')) {
      await awardBadge('day1_energy');
      await prefs.setString(_lastOpenKey, today);
      await prefs.setInt(_openStreakKey, 1);
      return 'day1_energy';
    }

    final lastOpen = prefs.getString(_lastOpenKey) ?? '';
    if (lastOpen == today) return null; // already counted today

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    // Touch Grass — 2+ days gap
    if (lastOpen.isNotEmpty && lastOpen != yesterday) {
      final last = DateTime.tryParse(lastOpen);
      if (last != null) {
        final gap = DateTime.now().difference(last).inDays;
        if (gap >= 2 && !isEarned('touch_grass')) {
          await prefs.setString(_lastOpenKey, today);
          await prefs.setInt(_openStreakKey, 1);
          await awardBadge('touch_grass');
          return 'touch_grass';
        }
      }
    }

    // Update open streak
    int streak = prefs.getInt(_openStreakKey) ?? 0;
    streak = (lastOpen == yesterday) ? streak + 1 : 1;
    await prefs.setInt(_openStreakKey, streak);
    await prefs.setString(_lastOpenKey, today);

    // Locked In — 14 consecutive days
    if (streak >= 14 && !isEarned('locked_in')) {
      await awardBadge('locked_in');
      return 'locked_in';
    }

    return null;
  }

  Future<String?> _onTaskCompleted(Map<String, dynamic> data) async {
    final totalCompleted = data['totalCompleted'] as int? ?? 0;
    final completedThisWeek = data['completedThisWeek'] as int? ?? 0;
    final isOnDueDate = data['isOnDueDate'] as bool? ?? false;

    if (totalCompleted >= 1 && !isEarned('first_task_done')) {
      await awardBadge('first_task_done');
      return 'first_task_done';
    }

    if (completedThisWeek >= 10 && !isEarned('task_slayer')) {
      await awardBadge('task_slayer');
      return 'task_slayer';
    }

    if (isOnDueDate && !isEarned('last_minute_god')) {
      final prefs = await SharedPreferences.getInstance();
      int count = prefs.getInt(_lastMinuteKey) ?? 0;
      count++;
      await prefs.setInt(_lastMinuteKey, count);
      if (count >= 3) {
        await awardBadge('last_minute_god');
        return 'last_minute_god';
      }
    }

    return null;
  }

  Future<String?> _onHabitToggled(Map<String, dynamic> data) async {
    final maxStreak = data['maxStreak'] as int? ?? 0;
    final allCompletedConsecutive = data['allCompletedConsecutive'] as int? ?? 0;
    final exactlyOneConsecutive = data['exactlyOneConsecutive'] as int? ?? 0;
    final resumedAfterMiss = data['resumedAfterMiss'] as bool? ?? false;

    if (maxStreak >= 7 && !isEarned('streak_beast')) {
      await awardBadge('streak_beast');
      return 'streak_beast';
    }
    if (maxStreak >= 30 && !isEarned('unstoppable')) {
      await awardBadge('unstoppable');
      return 'unstoppable';
    }
    if (allCompletedConsecutive >= 7 && !isEarned('overachiever')) {
      await awardBadge('overachiever');
      return 'overachiever';
    }
    if (allCompletedConsecutive >= 7 && !isEarned('monk_mode')) {
      await awardBadge('monk_mode');
      return 'monk_mode';
    }
    if (exactlyOneConsecutive >= 7 && !isEarned('bare_minimum')) {
      await awardBadge('bare_minimum');
      return 'bare_minimum';
    }
    if (resumedAfterMiss && !isEarned('comeback_arc')) {
      await awardBadge('comeback_arc');
      return 'comeback_arc';
    }

    return null;
  }

  Future<String?> _onJournalWritten() async {
    if (!isEarned('dear_diary')) {
      await awardBadge('dear_diary');
      return 'dear_diary';
    }
    return null;
  }

  Future<String?> _onExpenseLogged(Map<String, dynamic> data) async {
    final isOverBudget = data['isOverBudget'] as bool? ?? false;
    if (isOverBudget && !isEarned('budget_villain')) {
      await awardBadge('budget_villain');
      return 'budget_villain';
    }
    return null;
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);
}