import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/game_card.dart';

/// 阵营专属卡牌组件
/// 根据阵营主题色显示不同风格的卡牌
class FactionCardWidget extends StatelessWidget {
  final GameCard card;
  final Color factionColor;
  final bool isOwned;
  final VoidCallback? onTap;

  const FactionCardWidget({
    super.key,
    required this.card,
    required this.factionColor,
    this.isOwned = false,
    this.onTap,
  });

  /// 6大阵营颜色
  static const Map<String, Color> factionColors = {
    'mingjiao': Color(0xFFFF6B35),   // 明教 - 火焰橙
    'shaolin': Color(0xFFFFD700),   // 少林 - 金色
    'wudang': Color(0xFF4ECDC4),     // 武当 - 青绿
    'jinyiwei': Color(0xFF8B0000),   // 锦衣卫 - 深红
    'wudu': Color(0xFF9ACD32),      // 五毒教 - 毒绿
    'gaibang': Color(0xFFCD853F),   // 丐帮 - 土黄
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              factionColor.withOpacity(0.3),
              factionColor.withOpacity(0.1),
              AppTheme.cardBackground,
            ],
          ),
          border: Border.all(
            color: isOwned ? factionColor : factionColor.withOpacity(0.3),
            width: isOwned ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: factionColor.withOpacity(isOwned ? 0.4 : 0.2),
              blurRadius: isOwned ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Faction emblem watermark
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  _getFactionIcon(),
                  size: 60,
                  color: factionColor,
                ),
              ),
            ),
            // Owned badge
            if (isOwned)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: factionColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card name
                  Text(
                    card.name,
                    style: TextStyle(
                      color: factionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Card image area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: factionColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getTypeIcon(),
                          size: 28,
                          color: factionColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Cost and type row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cost badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.manaBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.manaBlue.withOpacity(0.5),
                          ),
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
                      // Attack/Defense
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (card.attack > 0) ...[
                            Icon(
                              Icons.sports_martial_arts,
                              size: 10,
                              color: AppTheme.healthRed,
                            ),
                            Text(
                              '${card.attack}',
                              style: const TextStyle(
                                color: AppTheme.healthRed,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (card.defense > 0) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.shield,
                              size: 10,
                              color: AppTheme.manaBlue,
                            ),
                            Text(
                              '${card.defense}',
                              style: const TextStyle(
                                color: AppTheme.manaBlue,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // Rarity indicator
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getRarityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _getRarityName(),
                      style: TextStyle(
                        color: _getRarityColor(),
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

  String _getRarityName() {
    switch (card.rarity) {
      case CardRarity.common:
        return '普通';
      case CardRarity.uncommon:
        return '优秀';
      case CardRarity.rare:
        return '稀有';
      case CardRarity.epic:
        return '史诗';
      case CardRarity.legendary:
        return '传说';
    }
  }

  IconData _getFactionIcon() {
    // Default icon, can be customized per faction
    return Icons.groups;
  }
}

/// 阵营卡牌网格展示组件
class FactionCardGrid extends StatelessWidget {
  final List<GameCard> cards;
  final String factionId;
  final List<String> ownedCardIds;
  final Function(GameCard)? onCardTap;

  const FactionCardGrid({
    super.key,
    required this.cards,
    required this.factionId,
    this.ownedCardIds = const [],
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final factionColor = FactionCardWidget.factionColors[factionId] ??
        AppTheme.accentGold;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 100 / 140,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return FactionCardWidget(
          card: card,
          factionColor: factionColor,
          isOwned: ownedCardIds.contains(card.id),
          onTap: () => onCardTap?.call(card),
        );
      },
    );
  }
}
