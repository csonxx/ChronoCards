import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enemy.dart';

/// Enemy widget for battle screen
class BattleEnemyWidget extends StatelessWidget {
  final Enemy enemy;

  const BattleEnemyWidget({super.key, required this.enemy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enemy name and level
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (enemy.isBoss)
                const Icon(Icons.whatshot, color: AppTheme.accentGold, size: 24)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1000.ms, color: AppTheme.textGold),
              const SizedBox(width: 8),
              Text(
                enemy.name,
                style: TextStyle(
                  color: enemy.isBoss ? AppTheme.accentGold : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${enemy.level}',
                  style: TextStyle(
                    color: enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Enemy sprite
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  enemy.isBoss
                      ? AppTheme.accentGold.withOpacity(0.3)
                      : AppTheme.healthRed.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed)
                      .withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              enemy.isBoss ? Icons.whatshot : Icons.dangerous,
              size: 48,
              color: enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1, 1),
                duration: 1000.ms,
              ),

          const SizedBox(height: 16),

          // Health bar
          _buildEnemyHealthBar(),
        ],
      ),
    );
  }

  Widget _buildEnemyHealthBar() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HP',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${enemy.health}/${enemy.maxHealth}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (enemy.health / enemy.maxHealth).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        enemy.isBoss ? AppTheme.accentGold : AppTheme.healthRed,
                        enemy.isBoss
                            ? AppTheme.energyYellow
                            : AppTheme.healthRed.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: (enemy.isBoss
                                ? AppTheme.accentGold
                                : AppTheme.healthRed)
                            .withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
