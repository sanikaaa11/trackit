import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/account_scope.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
    await AccountScope.loadFromPrefs();
    final prefs = await SharedPreferences.getInstance();
    final hasSavedEmail = AccountScope.hasActiveUser;
    final hasCompletedOnboarding =
        hasSavedEmail &&
        (prefs.getBool(AccountScope.scopedPrefKey('hasCompletedOnboarding')) ??
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
                  fontFamily: 'Inter',
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
