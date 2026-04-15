import 'package:equatable/equatable.dart';

/// 角色数据模型 - 玩家和敌人共用
/// 使用 Equatable 实现值相等性比较
class BattleEntity extends Equatable {
  final String name;
  final int maxHp;
  final int currentHp;
  final int attackDamage;
  final int level;

  const BattleEntity({
    required this.name,
    required this.maxHp,
    required this.attackDamage,
    this.level = 1,
    required this.currentHp,
  });

  /// 工厂方法：创建满血角色
  factory BattleEntity.full({
    required String name,
    required int maxHp,
    required int attackDamage,
    int level = 1,
  }) {
    return BattleEntity(
      name: name,
      maxHp: maxHp,
      attackDamage: attackDamage,
      level: level,
      currentHp: maxHp,
    );
  }

  /// 是否死亡
  bool get isDead => currentHp <= 0;

  /// 生命百分比
  double get hpPercentage => maxHp > 0 ? currentHp / maxHp : 0.0;

  /// 是否低血量（<30%）
  bool get isLowHp => hpPercentage < 0.3;

  /// 受到伤害，返回新的 BattleEntity
  BattleEntity takeDamage(int damage) {
    final newHp = (currentHp - damage).clamp(0, maxHp);
    return copyWith(currentHp: newHp);
  }

  /// 恢复生命，返回新的 BattleEntity
  BattleEntity heal(int amount) {
    final newHp = (currentHp + amount).clamp(0, maxHp);
    return copyWith(currentHp: newHp);
  }

  /// 重置为满血
  BattleEntity reset() {
    return copyWith(currentHp: maxHp);
  }

  @override
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
      currentHp: currentHp ?? this.currentHp,
      attackDamage: attackDamage ?? this.attackDamage,
      level: level ?? this.level,
    );
  }

  @override
  List<Object?> get props => [name, maxHp, currentHp, attackDamage, level];
}
