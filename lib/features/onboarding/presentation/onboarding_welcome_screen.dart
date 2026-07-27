import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/account_scope.dart';
import '../../expenses/data/expense_repository.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  late final TextEditingController nameController;
  String selectedEmoji = '🔥';
  final List<String> emojis = [
    '🔥',
    '⚡',
    '💫',
    '🎯',
    '🌸',
    '🦋',
    '👾',
    '🎨',
    '🏔️',
    '🦊',
    '🐉',
    '🌊',
    '☁️',
    '🍀',
    '🎭',
    '🦁',
    '🌻',
    '🪐',
    '💎',
    '✨',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AccountScope.scopedPrefKey('userName'), nameController.text);
    await prefs.setString(AccountScope.scopedPrefKey('userEmoji'), selectedEmoji);
    await prefs.setString('userName', nameController.text);
    await prefs.setString('userEmoji', selectedEmoji);
    await ExpenseRepository().setUserName(nameController.text);
    await ExpenseRepository().setUserEmoji(selectedEmoji);

    if (!mounted) return;
    context.go('/onboarding/vibe');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return WillPopScope(
      onWillPop: () async {
        context.go('/auth');
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            0,
            AppSizes.screenPadding,
            AppSizes.md + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: AppSizes.iconMd,
                    child: IconButton(
                      onPressed: () => context.go('/auth'),
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '1/4',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.xl),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                ),
                padding: EdgeInsets.all(AppSizes.cardPadding + AppSizes.md),
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.onboarding.withValues(alpha: 0.45),
                                  AppColors.onboarding.withValues(alpha: 0.0),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              selectedEmoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSizes.md),
                    const Text(
                      'Welcome to TrackIt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'let\'s make this yours 🫶',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontMd,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                'WHAT\'S YOUR NAME?',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontXs,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: AppSizes.sm),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What should we call you?',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.md,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              SizedBox(height: AppSizes.md),
              Text(
                'PICK AN EMOJI',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontXs,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: AppSizes.sm),
              SizedBox(
                height: keyboardOpen ? 120 : 210,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: AppSizes.sm),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    final isSelected = emoji == selectedEmoji;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmoji = emoji;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.onboarding
                              : AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white,
                                  width: 2,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: nameController.text.isEmpty ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onboarding,
                    disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.3),
                    padding:
                        EdgeInsets.symmetric(vertical: AppSizes.md + AppSizes.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Continue →',
                    style: TextStyle(
                      color: nameController.text.isEmpty
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
