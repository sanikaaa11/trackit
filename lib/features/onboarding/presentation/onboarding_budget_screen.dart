import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/utils/account_scope.dart';
import '../../expenses/data/expense_repository.dart';

class OnboardingBudgetScreen extends StatefulWidget {
  const OnboardingBudgetScreen({super.key});

  @override
  State<OnboardingBudgetScreen> createState() => _OnboardingBudgetScreenState();
}

class _OnboardingBudgetScreenState extends State<OnboardingBudgetScreen> {
  late final TextEditingController budgetController;

  @override
  void initState() {
    super.initState();
    budgetController = TextEditingController();
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  Future<void> _handleLetsGo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budget = double.tryParse(budgetController.text) ?? 0;

      await prefs.setDouble('monthlyBudget', budget);
      await prefs.setBool(AccountScope.scopedPrefKey('hasCompletedOnboarding'), true);
      await ExpenseRepository().setMonthlyBudget(budget);
      await ExpenseRepository().setHasCompletedOnboarding(true);

      unawaited(
        UserProfileService.saveUserProfile(
          email: prefs.getString('userEmail') ?? AccountScope.currentUserEmail ?? '',
          name: prefs.getString('userName') ?? '',
          emoji: prefs.getString('userEmoji') ?? '🔥',
          userVibe: prefs.getInt('userVibe') ?? 0,
          monthlyBudget: budget,
          hasCompletedOnboarding: true,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding saved — continuing...')),
      );
      context.go('/onboarding/ready');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete onboarding: $e')),
        );
      }
    }
  }

  Future<void> _handleSkip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AccountScope.scopedPrefKey('hasCompletedOnboarding'), true);
      await ExpenseRepository().setHasCompletedOnboarding(true);

      unawaited(
        UserProfileService.saveUserProfile(
          email: prefs.getString('userEmail') ?? AccountScope.currentUserEmail ?? '',
          name: prefs.getString('userName') ?? '',
          emoji: prefs.getString('userEmoji') ?? '🔥',
          userVibe: prefs.getInt('userVibe') ?? 0,
          monthlyBudget: 0,
          hasCompletedOnboarding: true,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding skipped — continuing...')),
      );
      context.go('/onboarding/ready');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to skip onboarding: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/onboarding/vibe');
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
                      onPressed: () => context.go('/onboarding/vibe'),
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                    ),
                    Text(
                      '3/4',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: AppSizes.fontSm,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.xl),
                const Text(
                  'Set your monthly budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'You can always change this in settings',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontMd,
                  ),
                ),
                SizedBox(height: AppSizes.lg),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSizes.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹',
                                style: TextStyle(
                                  color: AppColors.expenses,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: AppSizes.sm),
                              IntrinsicWidth(
                                child: TextField(
                                  controller: budgetController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.expenses,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.expenses,
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.expenses,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.md),
                          Text(
                            'per month',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: AppSizes.fontMd,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLetsGo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onboarding,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSizes.md + AppSizes.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: Text(
                          'Let\'s go',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.fontMd,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _handleSkip,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: AppSizes.fontMd,
                          ),
                        ),
                      ),
                    ),
                  ],
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
