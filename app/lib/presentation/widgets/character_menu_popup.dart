import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/player.dart';

/// Character menu popup - appears when tapping on the character
class CharacterMenuPopup extends StatelessWidget {
  final Player player;
  final VoidCallback onViewStats;
  final VoidCallback onViewCards;
  final VoidCallback onSettings;
  final VoidCallback? onClose;

  const CharacterMenuPopup({
    super.key,
    required this.player,
    required this.onViewStats,
    required this.onViewCards,
    required this.onSettings,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required Player player,
    required VoidCallback onViewStats,
    required VoidCallback onViewCards,
    required VoidCallback onSettings,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CharacterMenuPopup(
        player: player,
        onViewStats: onViewStats,
        onViewCards: onViewCards,
        onSettings: onSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentCosmic.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with character avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentCosmic.withOpacity(0.3),
                    AppTheme.primaryDark,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentGold, AppTheme.accentCosmic],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 36,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                            'Level ${player.level}',
                            style: const TextStyle(
                              color: AppTheme.textGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  if (onClose != null)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onClose?.call();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Stats preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.favorite,
                    '${player.health}/${player.maxHealth}',
                    AppTheme.healthRed,
                  ),
                  _buildStatItem(
                    Icons.bolt,
                    '${player.mana}/${player.maxMana}',
                    Colors.blue,
                  ),
                  _buildStatItem(
                    Icons.energy_savings_leaf,
                    '${player.energy}/${player.maxEnergy}',
                    Colors.green,
                  ),
                ],
              ),
            ),

            const Divider(color: AppTheme.cardBorder, height: 1),

            // Menu items
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart,
                    label: 'View Stats',
                    description: 'Check detailed character stats',
                    onTap: () {
                      Navigator.pop(context);
                      onViewStats();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.style,
                    label: 'View Cards',
                    description: 'Browse your card collection',
                    onTap: () {
                      Navigator.pop(context);
                      onViewCards();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    description: 'Game settings and options',
                    onTap: () {
                      Navigator.pop(context);
                      onSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.accentGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
