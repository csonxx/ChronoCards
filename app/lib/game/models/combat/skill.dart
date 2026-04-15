import 'elemental_system.dart';

/// 技能类型
enum SkillType {
  lightAttack,   // 轻攻击
  heavyAttack,   // 重攻击
  E,             // E技能（冷却技能）
  Q,             // Q技能（大招）
  dodge,         // 闪避
  block,         // 格挡
  dash,          // 突进
  jump,          // 跳跃
}

/// 武学流派
enum MartialArtType {
  neigong,   // 内功：防御/续航/元素
  waigong,   // 外功：输出
  qinggong,  // 轻功：机动
}

/// 技能定义
class Skill {
  final String id;
  final String name;
  final String description;
  final SkillType type;
  final MartialArtType category;
  
  // 消耗
  final int staminaCost;
  final int qiCost;
  final int swordIntentCost; // 剑意消耗（Q技能需要）
  
  // 冷却
  final double cooldown;        // 总冷却时间（秒）
  final double currentCooldown; // 当前剩余冷却
  
  // 伤害
  final int baseDamage;         // 基础伤害
  final double damageMultiplier; // 伤害倍率
  
  // 效果
  final ElementType? elementalType; // 附带元素
  final int applyElementStacks;     // 附加元素层数
  
  // 特殊标记
  final bool isInvincible;    // 释放时无敌
  final bool isRanged;        // 远程技能
  final bool isAOE;           // AOE技能
  
  const Skill({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    this.category = MartialArtType.waigong,
    this.staminaCost = 0,
    this.qiCost = 0,
    this.swordIntentCost = 0,
    required this.cooldown,
    this.currentCooldown = 0,
    required this.baseDamage,
    this.damageMultiplier = 1.0,
    this.elementalType,
    this.applyElementStacks = 1,
    this.isInvincible = false,
    this.isRanged = false,
    this.isAOE = false,
  });

  /// 是否可用
  bool get isReady => currentCooldown <= 0;
  
  /// 获取冷却百分比
  double get cooldownPercent => cooldown > 0 ? (cooldown - currentCooldown) / cooldown : 1.0;

  /// 冷却更新
  Skill tickCooldown(double deltaSeconds) {
    if (currentCooldown > 0) {
      return copyWith(currentCooldown: (currentCooldown - deltaSeconds).clamp(0, cooldown));
    }
    return this;
  }

  /// 重置冷却
  Skill resetCooldown() => copyWith(currentCooldown: 0);

  Skill copyWith({
    String? id,
    String? name,
    String? description,
    SkillType? type,
    MartialArtType? category,
    int? staminaCost,
    int? qiCost,
    int? swordIntentCost,
    double? cooldown,
    double? currentCooldown,
    int? baseDamage,
    double? damageMultiplier,
    ElementType? elementalType,
    int? applyElementStacks,
    bool? isInvincible,
    bool? isRanged,
    bool? isAOE,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      staminaCost: staminaCost ?? this.staminaCost,
      qiCost: qiCost ?? this.qiCost,
      swordIntentCost: swordIntentCost ?? this.swordIntentCost,
      cooldown: cooldown ?? this.cooldown,
      currentCooldown: currentCooldown ?? this.currentCooldown,
      baseDamage: baseDamage ?? this.baseDamage,
      damageMultiplier: damageMultiplier ?? this.damageMultiplier,
      elementalType: elementalType ?? this.elementalType,
      applyElementStacks: applyElementStacks ?? this.applyElementStacks,
      isInvincible: isInvincible ?? this.isInvincible,
      isRanged: isRanged ?? this.isRanged,
      isAOE: isAOE ?? this.isAOE,
    );
  }
}

/// 预设技能库
class SkillLibrary {
  // 轻攻击（普攻第一下）
  static const lightAttack = Skill(
    id: 'light_attack',
    name: '轻击',
    description: '快速攻击，造成轻量伤害',
    type: SkillType.lightAttack,
    category: MartialArtType.waigong,
    baseDamage: 30,
    damageMultiplier: 0.4,
    cooldown: 0.3,
  );

  // 重攻击（普攻第三下）
  static const heavyAttack = Skill(
    id: 'heavy_attack',
    name: '重击',
    description: '重击，造成大量伤害',
    type: SkillType.heavyAttack,
    category: MartialArtType.waigong,
    baseDamage: 80,
    damageMultiplier: 1.0,
    cooldown: 0.8,
  );

  // 闪避
  static const dodge = Skill(
    id: 'dodge',
    name: '闪避',
    description: '快速闪避，获得无敌帧',
    type: SkillType.dodge,
    category: MartialArtType.qinggong,
    staminaCost: 15,
    cooldown: 0.5,
    baseDamage: 0,
    isInvincible: true,
  );

  // 格挡
  static const block = Skill(
    id: 'block',
    name: '格挡',
    description: '架盾格挡，减少受到的伤害',
    type: SkillType.block,
    category: MartialArtType.neigong,
    staminaCost: 15,
    cooldown: 0,
    baseDamage: 0,
  );

  // E技能1 - 烈焰斩
  static const fireSlash = Skill(
    id: 'fire_slash',
    name: '烈焰斩',
    description: '挥舞武器，附带火焰伤害',
    type: SkillType.E,
    category: MartialArtType.waigong,
    qiCost: 20,
    cooldown: 5.0,
    baseDamage: 150,
    damageMultiplier: 1.5,
    elementalType: ElementType.fire,
    applyElementStacks: 1,
  );

  // E技能2 - 雷鸣掌
  static const thunderPalm = Skill(
    id: 'thunder_palm',
    name: '雷鸣掌',
    description: '掌风附带雷电，可感电敌人',
    type: SkillType.E,
    category: MartialArtType.neigong,
    qiCost: 30,
    cooldown: 8.0,
    baseDamage: 120,
    damageMultiplier: 1.2,
    elementalType: ElementType.thunder,
    applyElementStacks: 1,
    isRanged: true,
  );

  // Q技能 - 剑意爆发
  static const swordIntentBurst = Skill(
    id: 'sword_intent_burst',
    name: '剑意爆发',
    description: '凝聚全身剑意，造成巨额伤害',
    type: SkillType.Q,
    category: MartialArtType.waigong,
    qiCost: 50,
    swordIntentCost: 100,
    cooldown: 20.0,
    baseDamage: 400,
    damageMultiplier: 3.0,
    elementalType: ElementType.wind,
    applyElementStacks: 2,
    isAOE: true,
  );

  // 所有E技能列表
  static const List<Skill> eSkills = [fireSlash, thunderPalm];

  // 所有Q技能列表
  static const List<Skill> qSkills = [swordIntentBurst];
}
