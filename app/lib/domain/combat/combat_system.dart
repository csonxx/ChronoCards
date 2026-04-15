import 'dart:async';
import 'package:equatable/equatable.dart';
import 'stamina_system.dart';

/// 攻击硬直状态
class StaggerState extends Equatable {
  final bool isStaggered;
  final int staggerUntilMs;
  final int staggerRecoverMs;

  const StaggerState({
    this.isStaggered = false,
    this.staggerUntilMs = 0,
    this.staggerRecoverMs = 500,
  });

  StaggerState applyStagger(int currentTimeMs) {
    return StaggerState(
      isStaggered: true,
      staggerUntilMs: currentTimeMs + staggerRecoverMs,
      staggerRecoverMs: staggerRecoverMs,
    );
  }

  StaggerState update(int currentTimeMs) {
    if (!isStaggered) return this;
    if (currentTimeMs >= staggerUntilMs) {
      return const StaggerState();
    }
    return this;
  }

  StaggerState copyWith({
    bool? isStaggered,
    int? staggerUntilMs,
    int? staggerRecoverMs,
  }) {
    return StaggerState(
      isStaggered: isStaggered ?? this.isStaggered,
      staggerUntilMs: staggerUntilMs ?? this.staggerUntilMs,
      staggerRecoverMs: staggerRecoverMs ?? this.staggerRecoverMs,
    );
  }

  @override
  List<Object?> get props => [isStaggered, staggerUntilMs, staggerRecoverMs];
}

/// 闪避结果
class DodgeResult extends Equatable {
  final bool success;
  final bool iFramesExtended; // 这次闪避是否延长了无敌帧
  final int iFrameEndMs;

  const DodgeResult({
    required this.success,
    this.iFramesExtended = false,
    this.iFrameEndMs = 0,
  });

  @override
  List<Object?> get props => [success, iFramesExtended, iFrameEndMs];
}

/// 格挡结果
class BlockResult extends Equatable {
  final bool success;
  final bool isPerfectBlock;
  final int damageReduced;
  final int damageReflected; // 完美反击伤害
  final bool brokeAttacker'sStagger; // 打破攻击方硬直

  const BlockResult({
    required this.success,
    this.isPerfectBlock = false,
    this.damageReduced = 0,
    this.damageReflected = 0,
    this.brokeAttacker'sStagger = false,
  });

  @override
  List<Object?> get props => [success, isPerfectBlock, damageReduced, damageReflected, brokeAttacker'sStagger];
}

/// 战斗系统 - 整合闪避、格挡、伤害计算、硬直
class CombatSystem {
  // 无敌帧参数
  static const int baseInvincibleDurationMs = 200;
  static const int maxInvincibleStackMs = 600; // 最多叠加到600ms
  static const int dodgeStaminaCost = 15;

  // 格挡参数
  static const int blockStaminaCost = 15;
  static const int perfectBlockWindowMs = 200;
  static const int perfectBlockReflectDamage = 20;
  static const int perfectBlockWindowBonusMs = 100; // 完美格挡成功后下次窗口+100ms

  // 攻击硬直参数
  static const int lightAttackStaggerMs = 300;
  static const int heavyAttackStaggerMs = 500;
  static const int skillStaggerMs = 200;

  // 完美格挡窗口加成（连续完美格挡时）
  int _perfectBlockWindowBonus = 0;

  // 完美反击累积加成
  int _perfectBlockCombo = 0;

  /// 闪避：尝试激活/延长无敌帧
  /// 返回成功与否以及新的无敌帧截止时间
  DodgeResult tryDodge(StaminaResources resources, int currentTimeMs) {
    if (resources.stamina < dodgeStaminaCost) {
      return const DodgeResult(success: false);
    }

    // 计算新的无敌帧截止时间
    int newEndMs;
    bool extended = false;

    if (resources.isInvincible && resources.invincibleUntilMs > currentTimeMs) {
      // 已处于无敌帧中，叠加时间（取max而不是叠加，避免无限延长）
      final remaining = resources.invincibleUntilMs - currentTimeMs;
      final additional = baseInvincibleDurationMs;
      newEndMs = (currentTimeMs + remaining + additional).clamp(
        currentTimeMs,
        currentTimeMs + maxInvincibleStackMs,
      );
      extended = true;
    } else {
      // 全新无敌帧
      newEndMs = currentTimeMs + baseInvincibleDurationMs;
    }

    return DodgeResult(
      success: true,
      iFramesExtended: extended,
      iFrameEndMs: newEndMs,
    );
  }

  /// 更新无敌帧状态（每帧调用）
  StaminaResources updateInvincibility(StaminaResources resources, int currentTimeMs) {
    if (!resources.isInvincible) return resources;
    if (currentTimeMs >= resources.invincibleUntilMs) {
      return resources.deactivateInvincible();
    }
    return resources;
  }

  /// 开始格挡
  StaminaResources startBlock(StaminaResources resources, int currentTimeMs) {
    if (resources.stamina < blockStaminaCost) return resources;
    return resources.startBlock(currentTimeMs);
  }

  /// 格挡判定：判断 incomingDamage 是否被格挡
  /// 返回格挡结果，包含伤害减免和反击信息
  BlockResult evaluateBlock({
    required StaminaResources resources,
    required int incomingDamage,
    required int currentTimeMs,
    required bool attackerIsStaggered,
  }) {
    if (!resources.isBlocking) {
      return const BlockResult(success: false);
    }

    // 检查是否在完美格挡窗口内
    final timeSinceBlock = currentTimeMs - resources.lastBlockTimeMs;
    final effectiveWindow = perfectBlockWindowMs + _perfectBlockWindowBonus;
    final isPerfectBlock = timeSinceBlock <= effectiveWindow;

    if (isPerfectBlock) {
      // 完美格挡：完全免伤 + 反击
      _perfectBlockCombo++;
      _perfectBlockWindowBonus = (_perfectBlockCombo * perfectBlockWindowBonusMs).clamp(0, 200);

      return BlockResult(
        success: true,
        isPerfectBlock: true,
        damageReduced: incomingDamage,
        damageReflected: perfectBlockReflectDamage + (_perfectBlockCombo * 5),
        brokeAttacker'sStagger: attackerIsStaggered,
      );
    } else {
      // 普通格挡：减伤70%
      _perfectBlockCombo = 0;
      _perfectBlockWindowBonus = 0;
      final reduced = (incomingDamage * 0.7).round();

      return BlockResult(
        success: true,
        isPerfectBlock: false,
        damageReduced: reduced,
        damageReflected: 0,
      );
    }
  }

  /// 伤害计算：护盾优先消耗
  /// 返回实际扣血量（护盾已在内扣减）
  DamageApplicationResult applyDamageToEntity({
    required StaminaResources resources,
    required int rawDamage,
    required bool ignoreDefense,
    required int defense,
    required bool isFrozen,
  }) {
    // 1. 防御减伤
    int damageAfterDefense = rawDamage;
    if (!ignoreDefense) {
      damageAfterDefense = (rawDamage - defense * 0.5).round().clamp(1, rawDamage * 2);
    }

    // 2. 冻结状态减伤50%
    if (isFrozen) {
      damageAfterDefense = (damageAfterDefense * 0.5).round();
    }

    // 3. 护盾优先消耗
    int shieldConsumed = 0;
    int hpDamage = damageAfterDefense;
    int newShield = resources.shield;
    int newHp = resources.hp;

    if (resources.shield > 0) {
      if (resources.shield >= hpDamage) {
        // 护盾完全吸收
        newShield = resources.shield - hpDamage;
        hpDamage = 0;
        shieldConsumed = hpDamage;
      } else {
        // 护盾部分吸收，剩余伤害扣HP
        hpDamage = hpDamage - resources.shield;
        shieldConsumed = resources.shield;
        newShield = 0;
      }
    }

    newHp = (resources.hp - hpDamage).clamp(0, resources.maxHp);

    return DamageApplicationResult(
      shieldConsumed: shieldConsumed,
      hpLost: resources.hp - newHp,
      finalHp: newHp,
      finalShield: newShield,
      wasShieldBroken: shieldConsumed > 0 && newShield == 0 && hpDamage > 0,
    );
  }

  /// 计算普攻/技能对目标造成的伤害
  int calculateAttackDamage({
    required int attackerAttack,
    required double damageMultiplier,
    required int baseDamage,
    required int targetDefense,
    required bool isCrit,
    required int elementBonus,
  }) {
    int damage = (attackerAttack * damageMultiplier + baseDamage).round();
    damage += elementBonus;

    if (isCrit) {
      damage = (damage * 1.5).round();
    }

    // 防御减伤
    int finalDamage = (damage - targetDefense * 0.3).round().clamp(1, damage * 2);
    return finalDamage;
  }

  /// 获取攻击硬直时间
  int getStaggerDuration(StaggerType type) {
    switch (type) {
      case StaggerType.light:
        return lightAttackStaggerMs;
      case StaggerType.heavy:
        return heavyAttackStaggerMs;
      case StaggerType.skill:
        return skillStaggerMs;
    }
  }
}

enum StaggerType { light, heavy, skill }

/// 伤害应用结果
class DamageApplicationResult extends Equatable {
  final int shieldConsumed;
  final int hpLost;
  final int finalHp;
  final int finalShield;
  final bool wasShieldBroken; // 护盾被击碎

  const DamageApplicationResult({
    required this.shieldConsumed,
    required this.hpLost,
    required this.finalHp,
    required this.finalShield,
    this.wasShieldBroken = false,
  });

  @override
  List<Object?> get props => [shieldConsumed, hpLost, finalHp, finalShield, wasShieldBroken];
}
