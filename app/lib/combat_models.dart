/// ChronoCards ARPG - Core Combat Models
/// 用于测试的核心战斗数值模型

class CharacterStats {
  final int hp;
  final int attack;
  final int defense;
  final int maxStamina;
  final double moveSpeed;
  final double dodgeCooldown;
  final double blockReduction;

  const CharacterStats({
    this.hp = 1000,
    this.attack = 100,
    this.defense = 20,
    this.maxStamina = 100,
    this.moveSpeed = 3.5,
    this.dodgeCooldown = 1.2,
    this.blockReduction = 0.7,
  });

  CharacterStats copyWith({
    int? hp,
    int? attack,
    int? defense,
    int? maxStamina,
    double? moveSpeed,
    double? dodgeCooldown,
    double? blockReduction,
  }) {
    return CharacterStats(
      hp: hp ?? this.hp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      maxStamina: maxStamina ?? this.maxStamina,
      moveSpeed: moveSpeed ?? this.moveSpeed,
      dodgeCooldown: dodgeCooldown ?? this.dodgeCooldown,
      blockReduction: blockReduction ?? this.blockReduction,
    );
  }
}

class EnemyStats {
  final int hp;
  final int attack;
  final int defense;

  const EnemyStats({
    required this.hp,
    required this.attack,
    required this.defense,
  });
}

/// 技能定义
class Skill {
  final String name;
  final String key;
  final double cooldown;
  final int staminaCost;
  final double damageMultiplier;
  final int fixedDamage;
  final double animationDuration;
  final bool hasSuperArmor;

  const Skill({
    required this.name,
    required this.key,
    required this.cooldown,
    required this.staminaCost,
    this.damageMultiplier = 0,
    this.fixedDamage = 0,
    this.animationDuration = 0.5,
    this.hasSuperArmor = false,
  });

  int calcDamage(int characterAttack) {
    if (fixedDamage > 0) return fixedDamage;
    return (characterAttack * damageMultiplier).round();
  }
}

/// 普攻连击阶段
enum ComboPhase { none, first, second, third }

/// 闪避状态
class DodgeState {
  final bool isActive;
  final double remainingTime;
  final double cooldownRemaining;
  final double invincibilityDuration;

  const DodgeState({
    this.isActive = false,
    this.remainingTime = 0,
    this.cooldownRemaining = 0,
    this.invincibilityDuration = 0.4,
  });

  DodgeState copyWith({
    bool? isActive,
    double? remainingTime,
    double? cooldownRemaining,
    double? invincibilityDuration,
  }) {
    return DodgeState(
      isActive: isActive ?? this.isActive,
      remainingTime: remainingTime ?? this.remainingTime,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      invincibilityDuration: invincibilityDuration ?? this.invincibilityDuration,
    );
  }
}

/// 格挡状态
class BlockState {
  final bool isBlocking;
  final double perfectBlockWindow;
  final double recentBlockTime;

  const BlockState({
    this.isBlocking = false,
    this.perfectBlockWindow = 0.1,
    this.recentBlockTime = 0,
  });

  BlockState copyWith({
    bool? isBlocking,
    double? perfectBlockWindow,
    double? recentBlockTime,
  }) {
    return BlockState(
      isBlocking: isBlocking ?? this.isBlocking,
      perfectBlockWindow: perfectBlockWindow ?? this.perfectBlockWindow,
      recentBlockTime: recentBlockTime ?? this.recentBlockTime,
    );
  }
}

/// 技能CD管理器
class SkillCooldownManager {
  final Map<String, double> _cooldowns = {};

  double getCooldown(String skillKey) => _cooldowns[skillKey] ?? 0;

  bool isReady(String skillKey) => _cooldowns[skillKey] == null || _cooldowns[skillKey]! <= 0;

  void startCooldown(String skillKey, double duration) {
    _cooldowns[skillKey] = duration;
  }

  void update(double deltaTime) {
    for (var key in _cooldowns.keys.toList()) {
      final remaining = _cooldowns[key]! - deltaTime;
      if (remaining <= 0) {
        _cooldowns.remove(key);
      } else {
        _cooldowns[key] = remaining;
      }
    }
  }

  void reset() => _cooldowns.clear();
}

/// 预设技能
class Skills {
  static const Skill normalAttack = Skill(
    name: '普攻',
    key: 'J',
    cooldown: 0,
    staminaCost: 0,
    fixedDamage: 100,
    animationDuration: 0.3,
  );

  static const Skill jinGangQuan = Skill(
    name: '少林·金刚拳',
    key: 'K',
    cooldown: 5,
    staminaCost: 20,
    damageMultiplier: 2.5,
    animationDuration: 0.6,
    hasSuperArmor: true,
  );

  static const Skill taiJiJian = Skill(
    name: '武当·太极剑',
    key: 'L',
    cooldown: 8,
    staminaCost: 30,
    damageMultiplier: 1.8,
    animationDuration: 0.9,
    hasSuperArmor: false,
  );

  static const Skill qingFengJian = Skill(
    name: '峨眉·清风剑',
    key: 'U',
    cooldown: 6,
    staminaCost: 25,
    damageMultiplier: 1.6,
    animationDuration: 0.4,
    hasSuperArmor: false,
  );

  static const Skill poJianShi = Skill(
    name: '华山·破剑式',
    key: 'I',
    cooldown: 10,
    staminaCost: 35,
    damageMultiplier: 4.0,
    animationDuration: 0.8,
    hasSuperArmor: true,
  );

  static const Skill daGouBang = Skill(
    name: '丐帮·打狗棒',
    key: 'O',
    cooldown: 7,
    staminaCost: 25,
    damageMultiplier: 1.3,
    animationDuration: 0.5,
    hasSuperArmor: false,
  );

  static Skill? fromKey(String key) {
    switch (key.toUpperCase()) {
      case 'J': return normalAttack;
      case 'K': return jinGangQuan;
      case 'L': return taiJiJian;
      case 'U': return qingFengJian;
      case 'I': return poJianShi;
      case 'O': return daGouBang;
      default: return null;
    }
  }
}

/// 预设敌人
class Enemies {
  static const EnemyStats bandit = EnemyStats(
    hp: 300,
    attack: 30,
    defense: 0,
  );

  static const EnemyStats banditChief = EnemyStats(
    hp: 1200,
    attack: 60,
    defense: 0,
  );
}
