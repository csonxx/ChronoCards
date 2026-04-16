import 'package:flutter/material.dart';

/// 水墨风配色系统 - S5战斗界面MVP
class BattleColors {
  BattleColors._();

  // 主背景
  static const Color primaryBg = Color(0xFF0F0F1A);      // 深墨
  static const Color secondaryBg = Color(0xFF1A1A2E);   // 墨色

  // 边框/分割
  static const Color border = Color(0xFF3d3d5c);        // 水墨线

  // 主文字
  static const Color textPrimary = Color(0xFFFFFFFF);   // 宣纸白

  // HP条
  static const Color hpBarFull = Color(0xFF4ade80);     // 气血充足绿
  static const Color hpBarLow = Color(0xFFef4444);       // 低血量红
  static const Color hpBarEnemy = Color(0xFFc0392b);     // 敌人血条朱红

  // 体力条
  static const Color staminaBar = Color(0xFFF59E0B);    // 琥珀金

  // 按钮
  static const Color attackButton = Color(0xFFc0392b);  // 朱红攻击
  static const Color dodgeButton = Color(0xFF3B82F6);   // 蓝色闪避

  // 伤害数字
  static const Color damagePlayer = Color(0xFFef4444);  // 玩家受伤红色
  static const Color damageEnemy = Color(0xFFFFD93D);   // 攻击敌人金色
}