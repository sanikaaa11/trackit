import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/account_scope.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/expense_notifier.dart';
import '../../habits/domain/habit_notifier.dart';
import '../../journal/domain/journal_notifier.dart';
import '../../notes/domain/note_notifier.dart';
import '../../tasks/domain/task_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String userName = '';
  String userEmoji = '🔥';
  String userEmail = '';
  double monthlyBudget = 0;
  bool isDarkMode = true;

  final List<String> _emojiOptions = const [
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
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final budget = ExpenseRepository().getMonthlyBudget();
    if (!mounted) return;

    setState(() {
      userName = prefs.getString(AccountScope.scopedPrefKey('userName')) ?? '';
      userEmoji =
          prefs.getString(AccountScope.scopedPrefKey('userEmoji')) ?? '🔥';
      userEmail = prefs.getString('userEmail') ?? '';
      monthlyBudget = budget;
    });
  }

  Future<void> _showEditProfileSheet() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final nameController = TextEditingController(text: userName);
    String selectedEmoji = userEmoji;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'YOUR EMOJI',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _emojiOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemBuilder: (context, index) {
                        final emoji = _emojiOptions[index];
                        final isSelected = emoji == selectedEmoji;

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.tasks
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
                    const SizedBox(height: 24),
                    Text(
                      'DISPLAY NAME',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        hintText: 'Your name',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          await prefs.setString(
                            AccountScope.scopedPrefKey('userName'),
                            newName,
                          );
                          await prefs.setString('userName', newName);
                          await prefs.setString(
                            AccountScope.scopedPrefKey('userEmoji'),
                            selectedEmoji,
                          );
                          await prefs.setString('userEmoji', selectedEmoji);

                          if (!mounted) return;
                          setState(() {
                            userName = newName;
                            userEmoji = selectedEmoji;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tasks,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showBudgetDialog() async {
    final controller = TextEditingController(
      text: monthlyBudget == 0 ? '' : monthlyBudget.toStringAsFixed(0),
    );

    final newBudget = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Update Monthly Budget',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                Navigator.of(context).pop(value);
              },
              child: Text('Save', style: TextStyle(color: AppColors.tasks)),
            ),
          ],
        );
      },
    );

    if (newBudget == null) return;

    await ExpenseRepository().setMonthlyBudget(newBudget);

    if (!mounted) return;
    setState(() {
      monthlyBudget = newBudget;
    });
  }

  Future<void> _showAboutDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'About TrackIt',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'TrackIt v1.0.0\nBuilt for focused productivity and mindful habits.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: AppColors.tasks)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSignOutDialog() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to sign out from TrackIt?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) return;

    await AccountScope.clearCurrentUserEmail();
    _resetScopedProviders();

    if (!mounted) return;
    context.go('/auth');
  }

  void _resetScopedProviders() {
    ref.invalidate(tasksProvider);
    ref.invalidate(notesProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(habitsProvider);
    ref.invalidate(journalProvider);
    ref.invalidate(todayHabitStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userEmoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: GestureDetector(
                          onTap: _showEditProfileSheet,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.tasks,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.sm + AppSizes.xs),
                  Text(
                    userName.isEmpty ? 'TrackIt User' : userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.lg),
            Row(
              children: [
                const Text(
                  'My Badges',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/badges'),
                  child: Text(
                    'See all →',
                    style: TextStyle(
                      color: AppColors.tasks,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.sm),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _BadgeTile(color: AppColors.tasks, emoji: '🏆'),
                  _BadgeTile(color: AppColors.notes, emoji: '📝'),
                  _BadgeTile(color: AppColors.habits, emoji: '🔥'),
                  _BadgeTile(color: AppColors.expenses, emoji: '💰'),
                ],
              ),
            ),
            SizedBox(height: AppSizes.lg),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Monthly Budget',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${monthlyBudget.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: AppSizes.sm),
                        Icon(
                          Icons.edit_outlined,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                    onTap: _showBudgetDialog,
                  ),
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Theme',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                        });
                      },
                      activeColor: AppColors.tasks,
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => context.push('/notifications'),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline,
                    label: 'About TrackIt',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.lg),
            Center(
              child: TextButton(
                onPressed: _showSignOutDialog,
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sm + AppSizes.xs),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.color, required this.emoji});

  final Color color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      margin: EdgeInsets.only(right: AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}
