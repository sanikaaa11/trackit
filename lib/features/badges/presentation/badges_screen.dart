import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/badge_service.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeService = ref.watch(badgeServiceProvider);
    final earnedIds = badgeService.getEarnedBadgeIds().toSet();

    final earned = kBadgeDefinitions
        .where((b) => earnedIds.contains(b['id']))
        .toList();
    final locked = kBadgeDefinitions
        .where((b) => !earnedIds.contains(b['id']))
        .toList();

    // Group by series
    final series = <String, List<Map<String, String>>>{};
    for (final badge in kBadgeDefinitions) {
      final s = badge['series'] ?? 'Other';
      series.putIfAbsent(s, () => []).add(badge);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Badges',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  Text(
                    '🏆',
                    style: const TextStyle(fontSize: 32),
                  ),
                  SizedBox(width: AppSizes.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${earned.length} / ${kBadgeDefinitions.length} earned',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        earned.isEmpty
                            ? 'Start using TrackIt to earn badges!'
                            : 'Keep going, ${locked.length} more to unlock',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.lg),

            // Sections by series
            ...series.entries.map((entry) {
              final serieName = entry.key;
              final badges = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serieName.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppSizes.fontXs,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      final isEarned = earnedIds.contains(badge['id']);
                      return _BadgeCard(
                        badge: badge,
                        isEarned: isEarned,
                        onTap: () =>
                            _showBadgeDetail(context, badge, isEarned),
                      );
                    },
                  ),
                  SizedBox(height: AppSizes.lg),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    Map<String, String> badge,
    bool isEarned,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge image
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  badge['assetPath'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      badge['emoji'] ?? '🏆',
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isEarned
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEarned ? '✓ Earned' : '🔒 Locked',
                  style: TextStyle(
                    color: isEarned
                        ? AppColors.success
                        : AppColors.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                badge['description'] ?? '',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                badge['series'] ?? '',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isEarned,
    this.onTap,
  });

  final Map<String, String> badge;
  final bool isEarned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isEarned
                ? AppColors.habits.withOpacity(0.4)
                : AppColors.border,
            width: isEarned ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: AppSizes.sm),
            // Badge image with grayscale if locked
            SizedBox(
              width: 64,
              height: 64,
              child: ColorFiltered(
                colorFilter: isEarned
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.saturation,
                      )
                    : const ColorFilter.matrix([
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                child: Opacity(
                  opacity: isEarned ? 1.0 : 0.35,
                  child: Image.asset(
                    badge['assetPath'] ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        badge['emoji'] ?? '🏆',
                        style: TextStyle(
                          fontSize: 40,
                          color: isEarned ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isEarned)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🔒',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            SizedBox(height: AppSizes.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge['name'] ?? '',
                style: TextStyle(
                  color: isEarned ? Colors.white : AppColors.textHint,
                  fontSize: 11,
                  fontWeight: isEarned ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}