import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/player.dart';

/// Player status bar widget showing health, mana, energy
class PlayerStatusBar extends StatelessWidget {
  final Player player;

  const PlayerStatusBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentGold, width: 2),
              gradient: const LinearGradient(
                colors: [AppTheme.accentCosmic, AppTheme.primaryLight],
              ),
            ),
            child: const Icon(Icons.person, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv.${player.level}',
                        style: const TextStyle(
                          color: AppTheme.textGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Health bar
                _buildStatBar(
                  icon: Icons.favorite,
                  value: player.health,
                  maxValue: player.maxHealth,
                  color: AppTheme.healthRed,
                  iconColor: AppTheme.healthRed,
                ),
                const SizedBox(height: 4),

                // Mana bar
                _buildStatBar(
                  icon: Icons.auto_awesome,
                  value: player.mana,
                  maxValue: player.maxMana,
                  color: AppTheme.manaBlue,
                  iconColor: AppTheme.manaBlue,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Energy/Currency
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyChip(
                icon: Icons.bolt,
                value: '${player.energy}/${player.maxEnergy}',
                color: AppTheme.energyYellow,
              ),
              const SizedBox(height: 4),
              _buildCurrencyChip(
                icon: Icons.monetization_on,
                value: '${player.coins}',
                color: AppTheme.textGold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar({
    required IconData icon,
    required int value,
    required int maxValue,
    required Color color,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (value / maxValue).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          child: Text(
            '$value/$maxValue',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
