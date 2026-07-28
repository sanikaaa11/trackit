import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/account_scope.dart';
import '../tasks/domain/task_notifier.dart';
import '../notes/domain/note_notifier.dart';
import '../journal/domain/journal_notifier.dart';
import '../expenses/domain/expense_notifier.dart';
import '../habits/domain/habit_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // CRITICAL: load scope FIRST before any provider reads data
    await AccountScope.loadFromPrefs();

    // CRITICAL: invalidate all data providers so they reload
    // with the correct user scope
    ref.invalidate(tasksProvider);
    ref.invalidate(notesProvider);
    ref.invalidate(journalProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(habitsProvider);

    final prefs = await SharedPreferences.getInstance();
    final hasSavedEmail = AccountScope.hasActiveUser;
    final hasCompletedOnboarding = hasSavedEmail &&
        (prefs.getBool(
              AccountScope.scopedPrefKey('hasCompletedOnboarding'),
            ) ??
            false);

    if (!mounted) return;

    if (!hasSavedEmail) {
      context.go('/auth');
    } else if (hasCompletedOnboarding) {
      context.go('/home');
    } else {
      context.go('/onboarding/welcome');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tasks,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.screenPadding),
              const Text(
                'TrackIt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.sm),
              Text(
                'main character mode: on ✨',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}