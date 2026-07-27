import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../expenses/data/expense_repository.dart';

class OnboardingVibeScreen extends StatefulWidget {
  const OnboardingVibeScreen({super.key});

  @override
  State<OnboardingVibeScreen> createState() => _OnboardingVibeScreenState();
}

class _OnboardingVibeScreenState extends State<OnboardingVibeScreen> {
  int? selectedVibe;

  final List<Map<String, String>> vibes = [
    {
      'emoji': '📚',
      'title': 'Stay on top of studies',
      'subtitle': 'Tasks + Habits first',
    },
    {
      'emoji': '💼',
      'title': 'Manage work & life',
      'subtitle': 'Tasks + Expenses first',
    },
    {
      'emoji': '🌱',
      'title': 'Build better habits',
      'subtitle': 'Habits + Journal first',
    },
    {
      'emoji': '💰',
      'title': 'Track my spending',
      'subtitle': 'Expenses + Tasks first',
    },
  ];

  Future<void> _handleContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userVibe', selectedVibe ?? 0);
    await ExpenseRepository().setUserVibe(selectedVibe ?? 0);

    if (!mounted) return;
    context.go('/onboarding/budget');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/onboarding/welcome');
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go('/onboarding/welcome'),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                  ),
                  Text(
                    '2/4',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.xl),
              const Text(
                'I\'m mainly here to...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.sm),
              Text(
                'This helps us personalise your dashboard',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.fontMd,
                ),
              ),
              SizedBox(height: AppSizes.lg),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: AppSizes.sm),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSizes.md,
                    crossAxisSpacing: AppSizes.md,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: vibes.length,
                  itemBuilder: (context, index) {
                    final vibe = vibes[index];
                    final isSelected = selectedVibe == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedVibe = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.onboarding,
                                  width: 2,
                                )
                              : null,
                        ),
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vibe['emoji']!,
                              style: const TextStyle(fontSize: 30),
                            ),
                            SizedBox(height: AppSizes.sm),
                            Text(
                              vibe['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: AppSizes.xs),
                            Text(
                              vibe['subtitle']!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedVibe == null ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onboarding,
                    disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.3),
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.md + AppSizes.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Continue →',
                    style: TextStyle(
                      color: selectedVibe == null
                          ? AppColors.textHint
                          : Colors.white,
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
