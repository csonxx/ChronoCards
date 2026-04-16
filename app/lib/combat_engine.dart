/// ChronoCards ARPG - Combat Logic Engine
/// 战斗逻辑引擎（用于测试的模拟实现）

import 'combat_models.dart';

/// 伤害计算结果
class DamageResult {
  final int damage;
  final bool isCritical;
  final bool blocked;
  final bool perfectBlock;

  const DamageResult({
    required this.damage,
    this.isCritical = false,
    this.blocked = false,
    this.perfectBlock = false,
  });
}

/// 战斗状态
class CombatState {
  int playerHp;
  int playerStamina;
  double comboWindow;
  ComboPhase comboPhase;
  DodgeState dodgeState;
  BlockState blockState;
  SkillCooldownManager skillCooldowns;
  double lastAttackTime;
  double lastMoveTime;
  double dodgeLastUsedTime;
  bool isDead;

  CombatState({
    this.playerHp = 1000,
    this.playerStamina = 100,
    this.comboWindow = 0.6,
    this.comboPhase = ComboPhase.none,
    DodgeState? dodgeState,
    BlockState? blockState,
    SkillCooldownManager? skillCooldowns,
    this.lastAttackTime = -999,
    this.lastMoveTime = -999,
    this.dodgeLastUsedTime = -999,
    this.isDead = false,
  })  : dodgeState = dodgeState ?? const DodgeState(),
        blockState = blockState ?? const BlockState(),
        skillCooldowns = skillCooldowns ?? SkillCooldownManager();

  void update(double deltaTime) {
    if (isDead) return;

    // 气力自然回复 5点/秒
    if (playerStamina < 100) {
      playerStamina = (playerStamina + 5 * deltaTime).round().clamp(0, 100);
    }

    // 更新技能CD
    skillCooldowns.update(deltaTime);

    // 更新闪避状态
    if (dodgeState.isActive) {
      final remaining = dodgeState.remainingTime - deltaTime;
      if (remaining <= 0) {
        dodgeState = dodgeState.copyWith(isActive: false, remainingTime: 0);
      } else {
        dodgeState = dodgeState.copyWith(remainingTime: remaining);
      }
    }

    // 更新闪避CD
    if (dodgeState.cooldownRemaining > 0) {
      final cd = dodgeState.cooldownRemaining - deltaTime;
      dodgeState = dodgeState.copyWith(
        cooldownRemaining: cd > 0 ? cd : 0,
      );
    }

    // 连击窗口检测
    if (comboPhase != ComboPhase.none) {
      final timeSinceLastAttack = lastAttackTime;
      if (timeSinceLastAttack < 0 || (lastAttackTime - lastAttackTime).abs() > comboWindow) {
        comboPhase = ComboPhase.none;
      }
    }
  }
}

/// 战斗引擎
class CombatEngine {
  /// 计算普攻伤害（3段连击）
  int calcNormalAttackDamage(ComboPhase phase, int attack) {
    switch (phase) {
      case ComboPhase.none:
      case ComboPhase.first:
        return attack; // 100点
      case ComboPhase.second:
        return (attack * 1.2).round(); // 120点
      case ComboPhase.third:
        return (attack * 1.5).round(); // 150点
    }
  }

  /// 计算技能伤害
  int calcSkillDamage(Skill skill, int attack) {
    return skill.calcDamage(attack);
  }

  /// 计算实际受到伤害（考虑防御）
  int calcDamageTaken(int damage, int defense) {
    final reduced = damage - defense;
    return reduced > 0 ? reduced : 1; // 最小伤害1点
  }

  /// 计算格挡减免
  DamageResult applyBlock(int damage, bool isPerfectTiming) {
    if (isPerfectTiming) {
      return const DamageResult(damage: 0, perfectBlock: true);
    }
    return DamageResult(damage: (damage * 0.3).round(), blocked: true);
  }

  /// 检查闪避是否无敌
  bool isDodgeInvincible(CombatState state) {
    return state.dodgeState.isActive && state.dodgeState.remainingTime > 0;
  }

  /// 触发闪避
  bool tryDodge(CombatState state, double currentTime) {
    // 检查CD
    if (state.dodgeState.cooldownRemaining > 0) {
      return false;
    }
    // 检查气力
    if (state.playerStamina < 15) {
      return false;
    }

    // 消耗气力
    state.playerStamina -= 15;
    // 激活闪避（0.4秒无敌）
    state.dodgeState = state.dodgeState.copyWith(
      isActive: true,
      remainingTime: 0.4,
      cooldownRemaining: 1.2,
    );
    state.dodgeLastUsedTime = currentTime;
    return true;
  }

  /// 触发格挡
  void startBlock(CombatState state) {
    state.blockState = state.blockState.copyWith(isBlocking: true);
  }

  void endBlock(CombatState state) {
    state.blockState = state.blockState.copyWith(isBlocking: false);
  }

  /// 检查并执行完美格挡判定
  bool checkPerfectBlock(CombatState state, double timeSinceLastHit) {
    return state.blockState.isBlocking &&
        timeSinceLastHit <= state.blockState.perfectBlockWindow;
  }

  /// 技能是否可以释放
  bool canUseSkill(CombatState state, Skill skill) {
    if (state.isDead) return false;
    if (state.playerStamina < skill.staminaCost) return false;
    if (!state.skillCooldowns.isReady(skill.key)) return false;
    return true;
  }

  /// 使用技能
  bool useSkill(CombatState state, Skill skill, double currentTime) {
    if (!canUseSkill(state, skill)) return false;

    state.playerStamina -= skill.staminaCost;
    state.skillCooldowns.startCooldown(skill.key, skill.cooldown);
    state.lastAttackTime = currentTime;
    return true;
  }

  /// 普攻连击处理
  ComboPhase advanceCombo(CombatState state, double currentTime) {
    final timeSinceLastAttack = currentTime - state.lastAttackTime;

    if (state.comboPhase == ComboPhase.none ||
        timeSinceLastAttack > state.comboWindow) {
      state.comboPhase = ComboPhase.first;
    } else if (state.comboPhase == ComboPhase.first) {
      state.comboPhase = ComboPhase.second;
    } else if (state.comboPhase == ComboPhase.second) {
      state.comboPhase = ComboPhase.third;
    } else {
      // 3段后重置
      state.comboPhase = ComboPhase.first;
    }

    state.lastAttackTime = currentTime;
    return state.comboPhase;
  }

  /// 重置连击
  void resetCombo(CombatState state) {
    state.comboPhase = ComboPhase.none;
  }

  /// 模拟移动（更新最后移动时间用于延迟测试）
  void move(CombatState state, double currentTime) {
    state.lastMoveTime = currentTime;
  }

  /// 敌人攻击玩家
  DamageResult enemyAttack({
    required CombatState state,
    required int enemyDamage,
    required double currentTime,
    required double lastHitTime,
  }) {
    // 检查闪避无敌
    if (isDodgeInvincible(state)) {
      return const DamageResult(damage: 0);
    }

    // 检查完美格挡
    final timeSinceLastHit = currentTime - lastHitTime;
    final isPerfectBlock = checkPerfectBlock(state, timeSinceLastHit);
    if (state.blockState.isBlocking) {
      if (isPerfectBlock) {
        // 完美格挡：完全免伤 + 回复气力15点
        state.playerStamina = (state.playerStamina + 15).clamp(0, 100);
        return const DamageResult(damage: 0, perfectBlock: true);
      }
      // 普通格挡：减免70%
      final actualDamage = calcDamageTaken(enemyDamage, 0); // 先计算原始伤害
      final blockedDamage = applyBlock(actualDamage, false);
      state.playerHp -= blockedDamage.damage;
      if (state.playerHp <= 0) {
        state.playerHp = 0;
        state.isDead = true;
      }
      return DamageResult(damage: blockedDamage.damage, blocked: true);
    }

    // 无格挡
    final damage = calcDamageTaken(enemyDamage, 0);
    state.playerHp -= damage;
    if (state.playerHp <= 0) {
      state.playerHp = 0;
      state.isDead = true;
    }
    return DamageResult(damage: damage);
  }

  /// 计算击杀时间（模拟多次攻击）
  double calcKillTime({
    required int attackerAttack,
    required int defenderHp,
    required int defenderDefense,
    required double attackInterval,
  }) {
    int remainingHp = defenderHp;
    double time = 0;

    while (remainingHp > 0) {
      final damage = calcDamageTaken(attackerAttack, defenderDefense);
      remainingHp -= damage;
      time += attackInterval;
    }

    return time;
  }
}
