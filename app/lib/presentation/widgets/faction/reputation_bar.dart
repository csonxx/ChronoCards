import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 8级声望系统：仇恨 → 传说
enum ReputationLevel {
  hostile,      // 仇恨 (0)
  unfriendly,    // 冷淡 (1)
  neutral,       // 中立 (2)
  friendly,      // 友善 (3)
  respectful,     // 尊敬 (4)
  admired,        // 钦佩 (5)
  revered,        // 崇敬 (6)
  legendary,      // 传说 (7)
}

extension ReputationLevelExtension on ReputationLevel {
  String get name {
    switch (this) {
      case ReputationLevel.hostile:
        return '仇恨';
      case ReputationLevel.unfriendly:
        return '冷淡';
      case ReputationLevel.neutral:
        return '中立';
      case ReputationLevel.friendly:
        return '友善';
      case ReputationLevel.respectful:
        return '尊敬';
      case ReputationLevel.admired:
        return '钦佩';
      case ReputationLevel.revered:
        return '崇敬';
      case ReputationLevel.legendary:
        return '传说';
    }
  }

  String get icon {
    switch (this) {
      case ReputationLevel.hostile:
        return '😠';
      case ReputationLevel.unfriendly:
        return '😒';
      case ReputationLevel.neutral:
        return '😐';
      case ReputationLevel.friendly:
        return '🙂';
      case ReputationLevel.respectful:
        return '😊';
      case ReputationLevel.admired:
        return '😄';
      case ReputationLevel.revered:
        return '🤩';
      case ReputationLevel.legendary:
        return '👑';
    }
  }

  Color get color {
    switch (this) {
      case ReputationLevel.hostile:
        return const Color(0xFF8B0000);
      case ReputationLevel.unfriendly:
        return const Color(0xFFFF6347);
      case ReputationLevel.neutral:
        return const Color(0xFF808080);
      case ReputationLevel.friendly:
        return const Color(0xFF32CD32);
      case ReputationLevel.respectful:
        return const Color(0xFF4169E1);
      case ReputationLevel.admired:
        return const Color(0xFF9932CC);
      case ReputationLevel.revered:
        return const Color(0xFFFFD700);
      case ReputationLevel.legendary:
        return const Color(0xFFFFD700);
    }
  }

  /// 从声望值获取等级 (0-1000 映射到 0-7)
  static ReputationLevel fromValue(int reputation) {
    if (reputation < 0) return ReputationLevel.hostile;
    if (reputation < 50) return ReputationLevel.hostile;
    if (reputation < 150) return ReputationLevel.unfriendly;
    if (reputation < 300) return ReputationLevel.neutral;
    if (reputation < 500) return ReputationLevel.friendly;
    if (reputation < 700) return ReputationLevel.respectful;
    if (reputation < 850) return ReputationLevel.admired;
    if (reputation < 950) return ReputationLevel.revered;
    return ReputationLevel.legendary;
  }

  /// 获取当前等级需要的声望下限
  int get minValue {
    switch (this) {
      case ReputationLevel.hostile:
        return 0;
      case ReputationLevel.unfriendly:
        return 50;
      case ReputationLevel.neutral:
        return 150;
      case ReputationLevel.friendly:
        return 300;
      case ReputationLevel.respectful:
        return 500;
      case ReputationLevel.admired:
        return 700;
      case ReputationLevel.revered:
        return 850;
      case ReputationLevel.legendary:
        return 950;
    }
  }

  /// 获取下一级需要的声望上限
  int get maxValue {
    switch (this) {
      case ReputationLevel.hostile:
        return 50;
      case ReputationLevel.unfriendly:
        return 150;
      case ReputationLevel.neutral:
        return 300;
      case ReputationLevel.friendly:
        return 500;
      case ReputationLevel.respectful:
        return 700;
      case ReputationLevel.admired:
        return 850;
      case ReputationLevel.revered:
        return 950;
      case ReputationLevel.legendary:
        return 1000;
    }
  }
}

/// 声望进度条组件
class ReputationBar extends StatelessWidget {
  final int currentReputation;
  final bool showLabels;
  final double height;
  final bool expanded;

  const ReputationBar({
    super.key,
    required this.currentReputation,
    this.showLabels = true,
    this.height = 24,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = ReputationLevelExtension.fromValue(currentReputation);
    final progress = _calculateProgress(currentReputation, level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      level.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      level.name,
                      style: TextStyle(
                        color: level.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currentReputation / ${level.maxValue}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: level.color.withOpacity(0.5), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        level.color.withOpacity(0.2),
                        level.color.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          level.color.withOpacity(0.6),
                          level.color,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: level.color.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                // Level markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(8, (index) {
                    final markerLevel = ReputationLevel.values[index];
                    final isReached = currentReputation >= markerLevel.minValue;
                    return Container(
                      width: 2,
                      height: height * 0.6,
                      decoration: BoxDecoration(
                        color: isReached
                            ? markerLevel.color.withOpacity(0.8)
                            : AppTheme.cardBorder.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ReputationLevel.hostile.name,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                  ),
                ),
                Text(
                  ReputationLevel.legendary.name,
                  style: const TextStyle(
                    color: AppTheme.textGold,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  double _calculateProgress(int reputation, ReputationLevel level) {
    if (level == ReputationLevel.legendary) {
      return 1.0;
    }
    final levelProgress = reputation - level.minValue;
    final levelRange = level.maxValue - level.minValue;
    return levelProgress / levelRange;
  }
}

/// 声望等级图标列表（用于详情页展示）
class ReputationLevelIcons extends StatelessWidget {
  final ReputationLevel currentLevel;
  final double iconSize;

  const ReputationLevelIcons({
    super.key,
    required this.currentLevel,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ReputationLevel.values.map((level) {
        final isActive = level.index <= currentLevel.index;
        final isCurrent = level == currentLevel;

        return GestureDetector(
          onTap: () {
            // 可点击查看该等级详情
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isCurrent ? 4 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: level.color, width: 2)
                  : null,
              boxShadow: isActive && !isCurrent
                  ? [
                      BoxShadow(
                        color: level.color.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: isActive ? 1.0 : 0.3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    level.icon,
                    style: TextStyle(fontSize: iconSize * 0.7),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${level.index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isActive ? level.color : AppTheme.textSecondary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
