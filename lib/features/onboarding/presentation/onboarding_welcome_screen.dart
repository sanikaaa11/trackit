import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/account_scope.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  final nameController = TextEditingController();
  String selectedEmoji = '🔥';

  final List<String> emojis = [
    '🔥', '⚡', '💫', '🎯', '🌸', '🦋', '👾', '🎨',
    '🏔️', '🦊', '🐉', '🌊', '☁️', '🍀', '🎭', '🦁',
    '🌻', '🪐', '💎', '✨',
  ];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (nameController.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    // Save with scoped key so it's tied to this user account
    await prefs.setString(
      AccountScope.scopedPrefKey('userName'),
      nameController.text.trim(),
    );
    await prefs.setString(
      AccountScope.scopedPrefKey('userEmoji'),
      selectedEmoji,
    );
    if (!mounted) return;
    context.go('/onboarding/vibe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    '1/4',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Live preview
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.onboarding.withOpacity(0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    selectedEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (nameController.text.trim().isNotEmpty)
                Center(
                  child: Text(
                    nameController.text.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              Text(
                'Welcome to TrackIt',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "let's make this yours 🫶",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'WHAT\'S YOUR NAME?',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontXs,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'What should we call you?',
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'PICK AN EMOJI',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontXs,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  final isSelected = selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => selectedEmoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.onboarding.withOpacity(0.2)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.onboarding
                              : Colors.transparent,
                          width: 2,
                        ),
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
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: nameController.text.trim().isEmpty
                      ? null
                      : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onboarding,
                    disabledBackgroundColor:
                        AppColors.onboarding.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}