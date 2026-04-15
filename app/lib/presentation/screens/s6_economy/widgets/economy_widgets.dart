import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/battle_colors.dart';

/// 水墨风稀有度颜色
class RarityColors {
  static const Map<int, Color> colors = {
    1: Color(0xFF9E9E9E), // 灰色 - 普通
    2: Color(0xFF4CAF50), // 绿色 - 优秀
    3: Color(0xFF2196F3), // 蓝色 - 稀有
    4: Color(0xFF9C27B0), // 紫色 - 史诗
    5: Color(0xFFFF9800), // 橙色 - 传说
  };

  static Color getColor(int rarity) => colors[rarity] ?? colors[1]!;
}

/// 拍卖物品卡片组件
class AuctionItemCard extends StatelessWidget {
  final String name;
  final String description;
  final int rarity;
  final int currentPrice;
  final int buyoutPrice;
  final String timeRemaining;
  final int bidCount;
  final bool isHighestBidder;
  final VoidCallback? onTap;

  const AuctionItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.rarity,
    required this.currentPrice,
    required this.buyoutPrice,
    required this.timeRemaining,
    required this.bidCount,
    this.isHighestBidder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = RarityColors.getColor(rarity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: BattleColors.secondaryBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighestBidder ? AppTheme.accentGold : rarityColor.withOpacity(0.5),
            width: isHighestBidder ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：名称 + 稀有度
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: rarityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: BattleColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isHighestBidder)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '领先',
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 描述
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                description,
                style: TextStyle(
                  color: BattleColors.textPrimary.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // 底部：价格 + 时间 + 竞价次数
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: BattleColors.primaryBg.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // 当前价格
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前',
                        style: TextStyle(
                          color: BattleColors.textPrimary.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatPrice(currentPrice),
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // 一口价
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '一口价',
                        style: TextStyle(
                          color: BattleColors.textPrimary.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.flash_on, color: AppTheme.energyYellow, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatPrice(buyoutPrice),
                            style: const TextStyle(
                              color: AppTheme.energyYellow,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 时间
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '剩余',
                        style: TextStyle(
                          color: BattleColors.textPrimary.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        timeRemaining,
                        style: TextStyle(
                          color: _getTimeColor(timeRemaining),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // 竞价次数
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.manaBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$bidCount次',
                      style: const TextStyle(
                        color: AppTheme.manaBlue,
                        fontSize: 10,
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

  String _formatPrice(int price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(1)}万';
    }
    return price.toString();
  }

  Color _getTimeColor(String time) {
    if (time.contains('秒') || (time.contains('分') && !time.contains('小时'))) {
      return AppTheme.healthRed;
    } else if (time.contains('小时')) {
      return AppTheme.energyYellow;
    }
    return AppTheme.manaBlue;
  }
}

/// 分类标签按钮
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentGold.withOpacity(0.2)
              : BattleColors.secondaryBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentGold : BattleColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentGold : BattleColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 黑市物品卡片
class BlackMarketItemCard extends StatelessWidget {
  final String name;
  final String description;
  final int rarity;
  final int price;
  final VoidCallback? onBuy;

  const BlackMarketItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.rarity,
    required this.price,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = RarityColors.getColor(rarity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: BattleColors.secondaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: rarityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: BattleColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              description,
              style: TextStyle(
                color: BattleColors.textPrimary.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: BattleColors.primaryBg.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.healthRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.healthRed),
                    ),
                    child: const Text(
                      '购买',
                      style: TextStyle(
                        color: AppTheme.healthRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(1)}万';
    }
    return price.toString();
  }
}

/// 交易记录项
class TransactionItem extends StatelessWidget {
  final String type;
  final int amount;
  final String itemName;
  final String time;
  final String status;

  const TransactionItem({
    super.key,
    required this.type,
    required this.amount,
    required this.itemName,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount > 0;
    final icon = _getTypeIcon();
    final color = isPositive ? AppTheme.manaBlue : AppTheme.healthRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: BattleColors.border.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    color: BattleColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$time · $type',
                  style: TextStyle(
                    color: BattleColors.textPrimary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$amount',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (type) {
      case 'deposit':
        return Icons.add_circle;
      case 'purchase':
        return Icons.shopping_cart;
      case 'bid':
        return Icons.gavel;
      case 'buyout':
        return Icons.flash_on;
      case 'sale':
        return Icons.sell;
      default:
        return Icons.swap_horiz;
    }
  }
}

/// 我的竞拍项
class MyBidItem extends StatelessWidget {
  final String itemName;
  final int myBid;
  final int currentHighest;
  final String timeRemaining;
  final bool isHighestBidder;
  final String status;

  const MyBidItem({
    super.key,
    required this.itemName,
    required this.myBid,
    required this.currentHighest,
    required this.timeRemaining,
    required this.isHighestBidder,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isHighestBidder ? AppTheme.manaBlue : AppTheme.healthRed;
    final statusText = isHighestBidder ? '领先' : '被超越';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BattleColors.secondaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighestBidder ? AppTheme.manaBlue.withOpacity(0.5) : AppTheme.healthRed.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    color: BattleColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '我的: ${_formatPrice(myBid)}',
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '当前: ${_formatPrice(currentHighest)}',
                      style: TextStyle(
                        color: BattleColors.textPrimary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeRemaining,
                style: TextStyle(
                  color: _getTimeColor(timeRemaining),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(1)}万';
    }
    return price.toString();
  }

  Color _getTimeColor(String time) {
    if (time.contains('秒') || (time.contains('分') && !time.contains('小时'))) {
      return AppTheme.healthRed;
    } else if (time.contains('小时')) {
      return AppTheme.energyYellow;
    }
    return AppTheme.manaBlue;
  }
}
