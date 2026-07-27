import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/badge_service.dart';
import 'dart:math' as math;

class BadgeCelebrationOverlay extends StatefulWidget {
  const BadgeCelebrationOverlay({
    super.key,
    required this.badgeId,
    required this.onDismiss,
  });

  final String badgeId;
  final VoidCallback onDismiss;

  @override
  State<BadgeCelebrationOverlay> createState() =>
      _BadgeCelebrationOverlayState();
}

class _BadgeCelebrationOverlayState extends State<BadgeCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<_ConfettiPiece> _confetti = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0, 0.3),
      ),
    );

    // Generate confetti pieces
    for (int i = 0; i < 30; i++) {
      _confetti.add(_ConfettiPiece());
    }

    _scaleController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Map<String, String>? get _badge {
    try {
      return kBadgeDefinitions
          .firstWhere((b) => b['id'] == widget.badgeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    if (badge == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        color: Colors.black.withOpacity(0.75),
        child: Stack(
          children: [
            // Confetti
            ...List.generate(_confetti.length, (index) {
              final piece = _confetti[index];
              return AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  final progress = _confettiController.value;
                  final screenW =
                      MediaQuery.of(context).size.width;
                  final screenH =
                      MediaQuery.of(context).size.height;
                  return Positioned(
                    left: piece.x * screenW,
                    top: (piece.startY +
                            (piece.endY - piece.startY) * progress) *
                        screenH,
                    child: Opacity(
                      opacity: (1 - progress).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: piece.rotation * progress * 6.28,
                        child: Container(
                          width: piece.size,
                          height: piece.size,
                          decoration: BoxDecoration(
                            color: piece.color,
                            borderRadius: BorderRadius.circular(
                              piece.isCircle ? piece.size : 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Card
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.habits.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Badge Unlocked! 🎉',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Badge image
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset(
                            badge['assetPath'] ?? '',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              badge['emoji'] ?? '🏆',
                              style: const TextStyle(fontSize: 60),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          badge['name'] ?? '',
                          style: TextStyle(
                            color: AppColors.habits,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge['description'] ?? '',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.habits,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Awesome! 🔥',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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



class _ConfettiPiece {
  final double x;
  final double startY;
  final double endY;
  final double size;
  final Color color;
  final double rotation;
  final bool isCircle;

  static final _rng = math.Random();
  static final _colors = [
    const Color(0xFF378ADD),
    const Color(0xFF7F77DD),
    const Color(0xFF06B6D4),
    const Color(0xFF1D9E75),
    const Color(0xFF9B6210),
    Colors.white,
    Colors.amber,
    Colors.pink,
  ];

  _ConfettiPiece()
      : x = _rng.nextDouble(),
        startY = _rng.nextDouble() * 0.3,
        endY = 0.5 + _rng.nextDouble() * 0.5,
        size = 6 + _rng.nextDouble() * 8,
        color = _colors[_rng.nextInt(_colors.length)],
        rotation = _rng.nextDouble() * 4,
        isCircle = _rng.nextBool();
}