import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../utils/account_scope.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/expenses/presentation/add_expense_screen.dart';
import '../../features/expenses/presentation/expense_history_screen.dart';
import '../../features/expenses/presentation/expense_home_screen.dart';
import '../../features/expenses/presentation/expense_report_screen.dart';
import '../../features/habits/presentation/add_habit_screen.dart';
import '../../features/habits/presentation/habit_detail_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/journal/presentation/journal_entry_screen.dart';
import '../../features/journal/presentation/journal_list_screen.dart';
import '../../features/notes/presentation/note_editor_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/onboarding/presentation/onboarding_budget_screen.dart';
import '../../features/onboarding/presentation/onboarding_ready_screen.dart';
import '../../features/onboarding/presentation/onboarding_vibe_screen.dart';
import '../../features/onboarding/presentation/onboarding_welcome_screen.dart';
import '../../features/profile/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tasks/presentation/add_task_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/badges/presentation/badges_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      await AccountScope.loadFromPrefs();
      final prefs = await SharedPreferences.getInstance();
      final hasSavedEmail = AccountScope.hasActiveUser;
      final hasCompletedOnboarding =
          hasSavedEmail &&
          (prefs.getBool(AccountScope.scopedPrefKey('hasCompletedOnboarding')) ??
              false);
      final location = state.matchedLocation;
      final isOnboardingRoute = location.startsWith('/onboarding');
      final isAuthRoute = location == '/auth';

      // Let splash handle its own delayed navigation logic.
      if (location == '/splash') {
        return null;
      }

      if (!hasSavedEmail && !isAuthRoute) {
        return '/auth';
      }

      if (hasSavedEmail && !hasCompletedOnboarding && !isOnboardingRoute) {
        return '/onboarding/welcome';
      }

      if (hasCompletedOnboarding && (isOnboardingRoute || isAuthRoute)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/vibe',
        builder: (context, state) => const OnboardingVibeScreen(),
      ),
      GoRoute(
        path: '/onboarding/budget',
        builder: (context, state) => const OnboardingBudgetScreen(),
      ),
      GoRoute(
        path: '/onboarding/ready',
        builder: (context, state) => const OnboardingReadyScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseHomeScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tasks/add',
        builder: (context, state) => const AddTaskScreen(),
      ),
      GoRoute(
        path: '/notes/edit/:id',
        builder: (context, state) =>
        NoteEditorScreen(noteId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalListScreen(),
      ),
      GoRoute(
        path: '/journal/entry/:date',
        builder: (context, state) =>
            JournalEntryScreen(date: state.pathParameters['date'] ?? ''),
      ),
      GoRoute(
        path: '/expenses/add',
        builder: (context, state) => AddExpenseScreen(
          extra: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/expenses/report',
        builder: (context, state) => const ExpenseReportScreen(),
      ),
      GoRoute(
        path: '/expenses/history',
        builder: (context, state) => const ExpenseHistoryScreen(),
      ),
      GoRoute(
        path: '/habits/add',
        builder: (context, state) => const AddHabitScreen(),
      ),
      GoRoute(
        path: '/habits/edit/:id',
        builder: (context, state) => AddHabitScreen(habitId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/habits/detail/:id',
        builder: (context, state) =>
            HabitDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location) {
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/notes')) return 2;
    if (location.startsWith('/expenses')) return 3;
    if (location.startsWith('/habits')) return 4;
    return 0;
  }

  Color _selectedColorForIndex(int index) {
    switch (index) {
      case 0:
        return AppColors.tasks;
      case 1:
        return AppColors.tasks;
      case 2:
        return AppColors.notes;
      case 3:
        return AppColors.expenses;
      case 4:
        return AppColors.habits;
      default:
        return AppColors.tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.surface,
        unselectedItemColor: AppColors.textHint,
        selectedItemColor: _selectedColorForIndex(currentIndex),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/tasks');
              break;
            case 2:
              context.go('/notes');
              break;
            case 3:
              context.go('/expenses');
              break;
            case 4:
              context.go('/habits');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: currentIndex == 0 ? AppColors.tasks : AppColors.textHint,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.check_box,
              color: currentIndex == 1 ? AppColors.tasks : AppColors.textHint,
            ),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.note,
              color: currentIndex == 2 ? AppColors.notes : AppColors.textHint,
            ),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.pie_chart,
              color: currentIndex == 3 ? AppColors.expenses : AppColors.textHint,
            ),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.track_changes,
              color: currentIndex == 4 ? AppColors.habits : AppColors.textHint,
            ),
            label: 'Habits',
          ),
        ],
      ),
    );
  }
}
