import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/account_scope.dart';
import 'ai_chat_sheet.dart';
import '../../badges/data/badge_service.dart';
import '../../badges/presentation/badge_celebration_overlay.dart';
import '../../expenses/domain/expense_notifier.dart';
import '../../habits/domain/habit_notifier.dart';
import '../../notes/domain/note_notifier.dart';
import '../../tasks/domain/task_notifier.dart';
import '../../health/health_card.dart';

final _dashboardUserProvider = FutureProvider.autoDispose<_DashboardUser>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return _DashboardUser(
    name: prefs.getString(AccountScope.scopedPrefKey('userName')) ?? '',
    emoji: prefs.getString(AccountScope.scopedPrefKey('userEmoji')) ?? '🔥',
  );
});

// Provider that reads earned badges from BadgeService
final _earnedBadgesProvider = Provider<List<Map<String, String>>>((ref) {
  final badgeService = ref.watch(badgeServiceProvider);
  final earnedIds = badgeService.getEarnedBadgeIds();

  // Get full badge definitions for earned badges, most recent first
  final earned = kBadgeDefinitions
      .where((b) => earnedIds.contains(b['id']))
      .toList()
      .reversed
      .toList();

  return earned;
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAppOpenedBadge());
  }

  Future<void> _checkAppOpenedBadge() async {
    final badgeService = ref.read(badgeServiceProvider);
    final badgeId = await badgeService.checkAndAward('app_opened', {});
    if (badgeId != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        builder: (ctx) => BadgeCelebrationOverlay(
          badgeId: badgeId,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
        ? 'Good afternoon,'
        : 'Good evening,';

    final userAsync = ref.watch(_dashboardUserProvider);
    final tasks = ref.watch(tasksProvider);
    final notes = ref.watch(notesProvider);
    final expenses = ref.watch(expensesProvider);
    final habits = ref.watch(habitsProvider);
    final todayStatus = ref.watch(todayHabitStatusProvider);
    final earnedBadges = ref.watch(_earnedBadgesProvider);

    final pendingTasks = tasks.where((t) => !t.isComplete).length;
    final month = DateTime.now();
    final monthlySpent = expenses
        .where(
          (e) =>
              !e.isIncome &&
              e.date.month == month.month &&
              e.date.year == month.year,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    final todayCompletedHabits =
        todayStatus.values.where((v) => v).length;
    final totalHabits = habits.length;
    final completedRatio =
        totalHabits == 0 ? 0.0 : todayCompletedHabits / totalHabits;

    final user = userAsync.valueOrNull ??
        const _DashboardUser(name: '', emoji: '🔥');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              AppSizes.sm,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontMd,
                      ),
                    ),
                    Text(
                      user.name.isEmpty ? 'TrackIt User' : user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AiChatSheet(),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: EdgeInsets.only(right: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.notes.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.notes.withOpacity(0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.notes,
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.sm),

            // Module cards grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.sm,
              mainAxisSpacing: AppSizes.sm,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ModuleCard(
                  color: AppColors.tasks,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'TASKS',
                  value: '$pendingTasks Pending',
                  onTap: () => context.go('/tasks'),
                ),
                _ModuleCard(
                  color: AppColors.notes,
                  icon: Icons.note_alt_outlined,
                  label: 'NOTES',
                  value: '${notes.length} Notes',
                  onTap: () => context.go('/notes'),
                ),
                _ModuleCard(
                  color: AppColors.expenses,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'EXPENSES',
                  value: '₹${NumberFormat('#,##0').format(monthlySpent)}',
                  onTap: () => context.go('/expenses'),
                ),
                _ModuleCard(
                  color: AppColors.journal,
                  icon: Icons.menu_book_outlined,
                  label: 'JOURNAL',
                  value: 'Write Today',
                  onTap: () => context.push('/journal'),
                ),
              ],
            ),
            SizedBox(height: AppSizes.md),

            // Health card — ABOVE habits now
            const HealthCard(),
            SizedBox(height: AppSizes.md),

            // Habits card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.self_improvement_outlined,
                        color: AppColors.habits,
                      ),
                      SizedBox(width: AppSizes.sm),
                      Text(
                        'HABITS',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: AppSizes.fontXs,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(completedRatio * 100).round()}%',
                        style: TextStyle(
                          color: AppColors.habits,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizes.fontMd,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completedRatio,
                      minHeight: 8,
                      color: AppColors.habits,
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  Text(
                    '$todayCompletedHabits/$totalHabits completed today',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.md),

            // Recent Badges
            Row(
              children: [
                Text(
                  'Recent Badges',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.fontLg,
                  ),
                ),
                const Spacer(),
                if (earnedBadges.isNotEmpty)
                  GestureDetector(
                    onTap: () => context.push('/badges'),
                    child: Text(
                      'See all →',
                      style: TextStyle(
                        color: AppColors.tasks,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSizes.sm),

            if (earnedBadges.isEmpty)
              Row(
                children: [
                  _LockedBadgePlaceholder(label: 'Complete a task'),
                  SizedBox(width: AppSizes.sm),
                  _LockedBadgePlaceholder(label: 'Write in journal'),
                  SizedBox(width: AppSizes.sm),
                  _LockedBadgePlaceholder(label: 'Build a streak'),
                ],
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: earnedBadges.take(5).map((badge) {
                    return _EarnedBadgeCard(
                      badge: badge,
                      onTap: () => context.push('/badges'),
                    );
                  }).toList(),
                ),
              ),

            SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}

class _EarnedBadgeCard extends StatelessWidget {
  const _EarnedBadgeCard({
    required this.badge,
    this.onTap,
  });

  final Map<String, String> badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = badge['assetPath'] ?? '';
    final emoji = badge['emoji'] ?? '🏆';
    final name = badge['name'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: EdgeInsets.only(right: AppSizes.sm),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.habits.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  assetPath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to emoji if image not found
                    return Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedBadgePlaceholder extends StatelessWidget {
  const _LockedBadgePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '🔒',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(height: AppSizes.sm),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: AppSizes.xs),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardUser {
  const _DashboardUser({required this.name, required this.emoji});

  final String name;
  final String emoji;
}