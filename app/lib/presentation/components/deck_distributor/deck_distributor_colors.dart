import 'package:flutter/material.dart';

// ========== 发牌员通用色彩系统 ==========
// 来源：mvp_ui_roadmap.md 全局色彩规范（丐帮江湖风）
class DeckDistributorColors {
  DeckDistributorColors._();

  // 主色（土黄）— 用于中立/和平场景（茶馆/客栈/商贩）
  static const Color earthYellow = Color(0xFFC4A35A);
  static const Color earthYellowLight = Color(0xFFE8D5A3); // 气泡底色
  static const Color earthYellowDark = Color(0xFF8B7355);

  // 辅色（暗青）— 用于紧张/危险场景（敌人）
  static const Color darkCyan = Color(0xFF4A5568);
  static const Color darkCyanDeep = Color(0xFF3D4A5C); // 气泡边框

  // 点缀（朱砂红）— 用于奖励/激活/紧急
  static const Color vermillion = Color(0xFFC94A4A);
  static const Color vermillionDeep = Color(0xFF8B2020);

  // 资源（金）— 用于货币/高价值物品
  static const Color gold = Color(0xFFD4A843);

  // 草药绿 — 用于恢复/休息相关
  static const Color herbGreen = Color(0xFF6B8E6B);
  static const Color teaGreen = Color(0xFF5D8A66);

  // 能量/法力蓝
  static const Color manaBlue = Color(0xFF4ECDC4);
  static const Color energyYellow = Color(0xFFFFE66D);

  // 茶馆配色
  static const Color teahousePrimary = teaGreen;
  static const Color teahouseSecondary = darkCyan;

  // 客栈配色
  static const Color innWarmYellow = Color(0xFFE8A832);
  static const Color innRed = vermillion;

  // 敌人配色
  static const Color enemyDarkIron = Color(0xFF4A4A5A);
  static const Color enemyBloodRed = vermillionDeep;
  static const Color enemyBlack = Color(0xFF1A202C);

  // 商贩配色
  static const Color merchantCloth = Color(0xFFA08060);
  static const Color merchantGold = gold;
}

// ========== 发牌员通用状态 ==========
enum DeckDistributorState {
  idle,    // 空闲
  active,  // 激活
  cooldown, // 冷却中
}

// ========== 发牌员基类组件 ==========
/// 发牌员基础widget，提供通用状态管理和动画
abstract class BaseDeckDistributorWidget extends StatefulWidget {
  final DeckDistributorState state;
  final VoidCallback? onTap;
  final String? tooltip;

  const BaseDeckDistributorWidget({
    super.key,
    required this.state,
    this.onTap,
    this.tooltip,
  });
}
