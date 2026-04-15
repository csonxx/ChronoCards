/// 战斗相关游戏数值 - MVP固定值
class BattleConstants {
  BattleConstants._();

  // 玩家属性
  static const int playerMaxHp = 1000;
  static const int playerAttackDamage = 50;
  static const int playerLevel = 12;

  // 敌人属性
  static const int enemyMaxHp = 500;
  static const int enemyAttackDamage = 80;
  static const String enemyName = '山贼喽啰';

  // 体力系统
  static const int maxStamina = 100;
  static const int staminaRecoveryPerSec = 8;
  static const int dodgeStaminaCost = 15;

  // 无敌帧
  static const Duration invincibleDuration = Duration(milliseconds: 200);

  // 攻击后硬直
  static const Duration attackCooldown = Duration(milliseconds: 300);
}