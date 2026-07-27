import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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
    return BottomNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onTap: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      backgroundColor: AppColors.surface,
      unselectedItemColor: AppColors.textHint,
      selectedItemColor: _selectedColorForIndex(navigationShell.currentIndex),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      iconSize: AppSizes.iconMd,
      selectedFontSize: AppSizes.fontSm,
      unselectedFontSize: AppSizes.fontXs,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_rounded,
            color: navigationShell.currentIndex == 0
                ? AppColors.tasks
                : AppColors.textHint,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.check_circle_outline_rounded,
            color: navigationShell.currentIndex == 1
                ? AppColors.tasks
                : AppColors.textHint,
          ),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.note_alt_outlined,
            color: navigationShell.currentIndex == 2
                ? AppColors.notes
                : AppColors.textHint,
          ),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.account_balance_wallet_outlined,
            color: navigationShell.currentIndex == 3
                ? AppColors.expenses
                : AppColors.textHint,
          ),
          label: 'Expenses',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.self_improvement_outlined,
            color: navigationShell.currentIndex == 4
                ? AppColors.habits
                : AppColors.textHint,
          ),
          label: 'Habits',
        ),
      ],
    );
  }
}
