import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'health_provider.dart';

class HealthCard extends ConsumerStatefulWidget {
  const HealthCard({super.key});

  @override
  ConsumerState<HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends ConsumerState<HealthCard> {
  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.habits.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text('🏃', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                'HEALTH TODAY',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppSizes.fontXs,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (health.permissionDenied)
                GestureDetector(
                  onTap: () => openAppSettings(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Allow permission →',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else if (!health.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Walk a bit to start tracking',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.md),

          // Steps count + goal
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(health.stepsToday),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${_formatNumber(health.stepGoal)} steps',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showGoalDialog,
                child: Icon(
                  Icons.tune_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: health.stepProgress,
              minHeight: 6,
              color: health.stepProgress >= 1.0
                  ? AppColors.success
                  : AppColors.habits,
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
          SizedBox(height: AppSizes.sm),

          // Calories row
          Row(
            children: [
              _CaloriePill(
                emoji: '🔥',
                label: '${health.caloriesBurnt.round()} cal',
                sublabel: 'from steps',
                color: AppColors.habits,
              ),
              SizedBox(width: AppSizes.sm),
              _CaloriePill(
                emoji: '💪',
                label: '${health.manualCalories} cal',
                sublabel: 'workout',
                color: AppColors.notes,
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showAddWorkoutSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.notes.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.notes.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.notes, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Workout',
                        style: TextStyle(
                          color: AppColors.notes,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Goal reached banner
          if (health.stepProgress >= 1.0) ...[
            SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'Step goal reached! Keep going 💪',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Future<void> _showGoalDialog() async {
    final health = ref.read(healthProvider);
    final controller =
        TextEditingController(text: health.stepGoal.toString());
    if (!mounted) return;

    final newGoal = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Daily step goal',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '8000',
            hintStyle: TextStyle(color: AppColors.textHint),
            suffixText: 'steps',
            suffixStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.habits)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(val);
            },
            child: Text('Save',
                style: TextStyle(
                    color: AppColors.habits,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (newGoal != null && newGoal > 0 && mounted) {
      ref.read(healthProvider.notifier).setStepGoal(newGoal);
    }
  }

  void _showAddWorkoutSheet() {
    if (!mounted) return;

    final calController = TextEditingController();
    final capturedContext = context;

    final presets = [
      {'label': '🚶 Walk 30min', 'cal': 120},
      {'label': '🏃 Run 30min', 'cal': 280},
      {'label': '🚴 Cycling 30min', 'cal': 240},
      {'label': '🧘 Yoga 30min', 'cal': 90},
      {'label': '🏋️ Gym 1hr', 'cal': 350},
      {'label': '🤸 HIIT 20min', 'cal': 200},
      {'label': '🏊 Swimming 30min', 'cal': 250},
      {'label': '⚽ Sports 1hr', 'cal': 400},
    ];

    showModalBottomSheet(
      context: capturedContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // KEY FIX: use builder that gives a properly constrained context
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              // KEY: give explicit width using MediaQuery
              width: MediaQuery.of(sheetCtx).size.width,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Log workout calories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('QUICK ADD',
                      style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      return GestureDetector(
                        onTap: () async {
                          final cal = preset['cal'] as int;
                          await ref
                              .read(healthProvider.notifier)
                              .addManualCalories(cal);
                          if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                          }
                          if (capturedContext.mounted) {
                            ScaffoldMessenger.of(capturedContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text('💪 +$cal cal logged!'),
                                backgroundColor: AppColors.surface,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${preset['label']} · ${preset['cal']} cal',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('CUSTOM',
                      style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  // KEY FIX: Row with fixed-size button, not full-width ElevatedButton
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: calController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter calories',
                            hintStyle:
                                TextStyle(color: AppColors.textHint),
                            suffixText: 'cal',
                            suffixStyle: TextStyle(
                                color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // KEY FIX: SizedBox with explicit width instead of
                      // full-width ElevatedButton
                      SizedBox(
                        width: 72,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final cal = int.tryParse(
                                    calController.text.trim()) ??
                                0;
                            if (cal <= 0) return;
                            await ref
                                .read(healthProvider.notifier)
                                .addManualCalories(cal);
                            if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                            if (capturedContext.mounted) {
                              ScaffoldMessenger.of(capturedContext)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                      Text('💪 +$cal cal logged!'),
                                  backgroundColor: AppColors.surface,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.notes,
                            foregroundColor: Colors.white,
                            // KEY FIX: remove minimumSize infinity
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add',
                              style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CaloriePill extends StatelessWidget {
  const _CaloriePill({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  final String emoji;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}