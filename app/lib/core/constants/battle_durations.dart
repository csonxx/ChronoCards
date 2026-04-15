/// 战斗界面动画时长常量 - S5 MVP
class BattleDurations {
  BattleDurations._();

  // 血条/体力条变化
  static const Duration barChange = Duration(milliseconds: 200);

  // 受伤反馈
  static const Duration hurtFlash = Duration(milliseconds: 100);

  // 闪避无敌帧
  static const Duration dodgeInvincible = Duration(milliseconds: 200);

  // 伤害数字飘起
  static const Duration damageFloat = Duration(milliseconds: 600);

  // 攻击后硬直
  static const Duration attackCooldown = Duration(milliseconds: 300);

  // 敌人攻击间隔
  static const Duration enemyAttackInterval = Duration(milliseconds: 3000);
  static const Duration enemyAttackWindup = Duration(milliseconds: 300);

  // 战斗淡入
  static const Duration battleFadeIn = Duration(milliseconds: 500);

  // 结算界面淡入
  static const Duration resultFadeIn = Duration(milliseconds: 300);

  // 攻击命中闪白
  static const Duration hitFlash = Duration(milliseconds: 50);
}