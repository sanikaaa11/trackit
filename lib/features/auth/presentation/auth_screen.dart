import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/account_scope.dart';
import '../data/auth_repository.dart';

final _authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) return 'Please enter your email';
    if (!email.contains('@')) return 'Please enter a valid email';
    if (password.isEmpty) return 'Please enter your password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (!isLogin && confirmPasswordController.text.trim() != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleAuth() async {
    final validationError = _validate();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    setState(() => isLoading = true);

    final repo = ref.read(_authRepositoryProvider);
    final email = emailController.text.trim().toLowerCase();

    try {
      if (isLogin) {
        final error = await repo.login(email, passwordController.text.trim());
        if (error != null) {
          _showSnackBar(error, isError: true);
          setState(() => isLoading = false);
          return;
        }

        // Set account scope
        await AccountScope.setCurrentUserEmail(email);

        // Check if onboarding was already completed for this user
        final prefs = await SharedPreferences.getInstance();
        final onboardingKey = AccountScope.scopedPrefKey('hasCompletedOnboarding');
        final hasOnboarded = prefs.getBool(onboardingKey) ?? false;

        if (!mounted) return;

        if (hasOnboarded) {
          // Already set up — go straight to home, data is intact
          context.go('/home');
        } else {
          // First time logging in on this device — need onboarding
          context.go('/onboarding/welcome');
        }
      } else {
        // Sign up
        final error = await repo.signUp(email, passwordController.text.trim());
        if (error != null) {
          _showSnackBar(error, isError: true);
          setState(() => isLoading = false);
          return;
        }

        await AccountScope.setCurrentUserEmail(email);

        if (!mounted) return;
        // New account always goes through onboarding
        context.go('/onboarding/welcome');
      }
    } catch (e) {
      _showSnackBar('Something went wrong. Try again.', isError: true);
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // App identity
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.tasks,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TrackIt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'main character mode: on ✨',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Auth card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _ToggleTab(
                            label: 'Login',
                            isSelected: isLogin,
                            onTap: () => setState(() => isLogin = true),
                          ),
                          _ToggleTab(
                            label: 'Sign Up',
                            isSelected: !isLogin,
                            onTap: () => setState(() => isLogin = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => isPasswordVisible = !isPasswordVisible,
                          ),
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Confirm password for signup
                    if (!isLogin) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Confirm password',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => isConfirmPasswordVisible =
                                  !isConfirmPasswordVisible,
                            ),
                            icon: Icon(
                              isConfirmPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textHint,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Forgot password
                    if (isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showSnackBar(
                            'Password reset coming soon!',
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleAuth,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isLogin ? 'Login' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Google option
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () =>
                    _showSnackBar('Google sign in coming soon!'),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'G',
                        style: TextStyle(
                          color: AppColors.tasks,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
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

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tasks : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textHint,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}