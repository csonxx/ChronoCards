import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/game_card.dart';

/// Battle card widget - compact version for battle hand
class BattleCardWidget extends StatelessWidget {
  final GameCard card;
  final bool isSelected;
  final bool isPlayable;
  final VoidCallback? onTap;

  const BattleCardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isPlayable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 110,
        transform: isSelected
            ? (Matrix4.identity()..translate(0.0, -10.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.cardBackground,
          border: Border.all(
            color: isSelected ? AppTheme.textGold : _getTypeColor(),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.textGold.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            // Cost badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.manaBlue.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 10, color: AppTheme.manaBlue),
                  Text(
                    '${card.cost}',
                    style: const TextStyle(
                      color: AppTheme.manaBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Icon
            Expanded(
              child: Center(
                child: Icon(
                  _getTypeIcon(),
                  size: 28,
                  color: _getTypeColor(),
                ),
              ),
            ),

            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                card.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (card.attack > 0) ...[
                    Icon(Icons.sports_martial_arts,
                        size: 10, color: AppTheme.healthRed),
                    Text(
                      '${card.attack}',
                      style: const TextStyle(
                        color: AppTheme.healthRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (card.attack > 0 && card.defense > 0)
                    const SizedBox(width: 4),
                  if (card.defense > 0) ...[
                    Icon(Icons.shield, size: 10, color: AppTheme.manaBlue),
                    Text(
                      '${card.defense}',
                      style: const TextStyle(
                        color: AppTheme.manaBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (card.type) {
      case CardType.attack:
        return Icons.sports_martial_arts;
      case CardType.defense:
        return Icons.shield;
      case CardType.skill:
        return Icons.auto_fix_high;
      case CardType.magic:
        return Icons.auto_awesome;
      case CardType.special:
        return Icons.star;
    }
  }

  Color _getTypeColor() {
    switch (card.type) {
      case CardType.attack:
        return AppTheme.healthRed;
      case CardType.defense:
        return AppTheme.manaBlue;
      case CardType.skill:
        return AppTheme.energyYellow;
      case CardType.magic:
        return AppTheme.accentMystic;
      case CardType.special:
        return AppTheme.textGold;
    }
  }
}
