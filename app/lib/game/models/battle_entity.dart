/// 角色数据模型 - 玩家和敌人共用
class BattleEntity {
  final String name;
  final int maxHp;
  int currentHp;
  final int attackDamage;
  int level;
  
  BattleEntity({
    required this.name,
    required this.maxHp,
    required this.attackDamage,
    this.level = 1,
  }) : currentHp = maxHp;

  /// 是否死亡
  bool get isDead => currentHp <= 0;

  /// 生命百分比
  double get hpPercentage => currentHp / maxHp;

  /// 是否低血量（<30%）
  bool get isLowHp => hpPercentage < 0.3;

  /// 受到伤害
  void takeDamage(int damage) {
    currentHp = (currentHp - damage).clamp(0, maxHp);
  }

  /// 恢复生命
  void heal(int amount) {
    currentHp = (currentHp + amount).clamp(0, maxHp);
  }

  /// 重置
  void reset() {
    currentHp = maxHp;
  }

  BattleEntity copyWith({
    String? name,
    int? maxHp,
    int? currentHp,
    int? attackDamage,
    int? level,
  }) {
    return BattleEntity(
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      attackDamage: attackDamage ?? this.attackDamage,
      level: level ?? this.level,
    )..currentHp = currentHp ?? this.currentHp;
  }
}