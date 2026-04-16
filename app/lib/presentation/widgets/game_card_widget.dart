import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_card.dart';

/// Game card widget for displaying cards
class GameCardWidget extends StatelessWidget {
  final GameCard card;
  final bool isBack;
  final bool showDetails;
  final bool isSelected;
  final VoidCallback? onTap;

  const GameCardWidget({
    super.key,
    required this.card,
    this.isBack = false,
    this.showDetails = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 170,
        transform: isSelected
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        child: isBack ? _buildCardBack() : _buildCardFront(),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentCosmic,
            AppTheme.primaryLight,
          ],
        ),
        border: Border.all(color: AppTheme.accentGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCosmic.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 40,
              color: AppTheme.textGold,
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.textGold, width: 2),
              ),
              child: const Icon(
                Icons.question_mark,
                size: 32,
                color: AppTheme.textGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _getRarityColor().withOpacity(0.2),
        border: Border.all(
          color: isSelected ? AppTheme.textGold : _getRarityColor(),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRarityColor().withOpacity(0.4),
            blurRadius: isSelected ? 15 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRarityColor().withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    card.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.manaBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 10,
                        color: AppTheme.manaBlue,
                      ),
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
              ],
            ),
          ),

          // Card image area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _getTypeIcon(),
                  size: 40,
                  color: _getRarityColor(),
                ),
              ),
            ),
          ),

          // Card stats
          Container(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (card.attack > 0)
                  _buildStatBadge(
                    Icons.sports_martial_arts,
                    '${card.attack}',
                    AppTheme.healthRed,
                  )
                else
                  const SizedBox(width: 24),
                if (card.defense > 0)
                  _buildStatBadge(
                    Icons.shield,
                    '${card.defense}',
                    AppTheme.manaBlue,
                  )
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),

          // Card footer with type
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: Text(
              _getTypeName(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getTypeColor(),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
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

  Color _getRarityColor() {
    switch (card.rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.legendary:
        return AppTheme.textGold;
    }
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

  String _getTypeName() {
    switch (card.type) {
      case CardType.attack:
        return 'ATTACK';
      case CardType.defense:
        return 'DEFENSE';
      case CardType.skill:
        return 'SKILL';
      case CardType.magic:
        return 'MAGIC';
      case CardType.special:
        return 'SPECIAL';
    }
  }
}
