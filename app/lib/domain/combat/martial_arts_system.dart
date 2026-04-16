import 'dart:async';
import 'package:equatable/equatable.dart';

/// 武学技能类型
enum MartialArtType {
  innerGong,  // 内功：防御/护盾/元素属性
  outerGong,  // 外功：输出伤害
  lightSkill, // 轻功：机动/闪避
}

/// 技能目标类型
enum SkillTarget {
  self,
  enemy,
  aoe,        // 范围伤害
  ally,
}

/// 元素属性（关联elemental_system.dart）
enum ElementType {
  none,
  fire,
  water,
  thunder,
  ice,
  wind,
  earth,
  light,
  dark,
}

/// 单个技能定义
class MartialSkill extends Equatable {
  final String id;
  final String name;
  final String description;
  final MartialArtType type;
  final SkillTarget target;

  // 消耗
  final int qiCost;
  final int staminaCost;

  // 效果数值
  final int damage;         // 伤害值
  final int shieldValue;    // 护盾值
  final int healValue;      // 治疗值
  final int staggerValue;   // 硬直值

  // 元素
  final ElementType element;

  // 冷却
  final int cooldownMs;
  final int currentCooldownMs;

  // 特殊标记
  final bool isEskill;      // E技能
  final bool isQskill;      // Q技能
  final bool canPerfectBlock; // 可被完美格挡
  final bool breaksArmor;   // 破甲
  final bool isAoe;         // AOE
  final int levelRequired;  // 所需玩家等级

  const MartialSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.target = SkillTarget.enemy,
    this.qiCost = 0,
    this.staminaCost = 0,
    this.damage = 0,
    this.shieldValue = 0,
    this.healValue = 0,
    this.staggerValue = 0,
    this.element = ElementType.none,
    this.cooldownMs = 0,
    this.currentCooldownMs = 0,
    this.isEskill = false,
    this.isQskill = false,
    this.canPerfectBlock = true,
    this.breaksArmor = false,
    this.isAoe = false,
    this.levelRequired = 1,
  });

  bool get isReady => currentCooldownMs <= 0;
  bool get canUse => isReady && currentCooldownMs <= 0;

  double get cooldownPercent {
    if (cooldownMs <= 0) return 1.0;
    return 1.0 - (currentCooldownMs / cooldownMs);
  }

  MartialSkill use() {
    return copyWith(currentCooldownMs: cooldownMs);
  }

  MartialSkill tick(int deltaMs) {
    if (currentCooldownMs <= 0) return this;
    return copyWith(currentCooldownMs: (currentCooldownMs - deltaMs).clamp(0, cooldownMs));
  }

  MartialSkill resetCooldown() {
    return copyWith(currentCooldownMs: 0);
  }

  MartialSkill copyWith({
    String? id,
    String? name,
    String? description,
    MartialArtType? type,
    SkillTarget? target,
    int? qiCost,
    int? staminaCost,
    int? damage,
    int? shieldValue,
    int? healValue,
    int? staggerValue,
    ElementType? element,
    int? cooldownMs,
    int? currentCooldownMs,
    bool? isEskill,
    bool? isQskill,
    bool? canPerfectBlock,
    bool? breaksArmor,
    bool? isAoe,
    int? levelRequired,
  }) {
    return MartialSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      qiCost: qiCost ?? this.qiCost,
      staminaCost: staminaCost ?? this.staminaCost,
      damage: damage ?? this.damage,
      shieldValue: shieldValue ?? this.shieldValue,
      healValue: healValue ?? this.healValue,
      staggerValue: staggerValue ?? this.staggerValue,
      element: element ?? this.element,
      cooldownMs: cooldownMs ?? this.cooldownMs,
      currentCooldownMs: currentCooldownMs ?? this.currentCooldownMs,
      isEskill: isEskill ?? this.isEskill,
      isQskill: isQskill ?? this.isQskill,
      canPerfectBlock: canPerfectBlock ?? this.canPerfectBlock,
      breaksArmor: breaksArmor ?? this.breaksArmor,
      isAoe: isAoe ?? this.isAoe,
      levelRequired: levelRequired ?? this.levelRequired,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, type, target,
        qiCost, staminaCost, damage, shieldValue, healValue, staggerValue,
        element, cooldownMs, currentCooldownMs,
        isEskill, isQskill, canPerfectBlock, breaksArmor, isAoe, levelRequired,
      ];
}

/// 武学技能系统 - 管理角色的所有技能和CD
class MartialArtsSystem {
  // 已学习的技能列表
  final List<MartialSkill> skills;

  // 当前激活的内功/外功/轻功
  String? activeInnerGongId;
  String? activeOuterGongId;
  String? activeLightSkillId;

  // 内功属性加成
  final Map<ElementType, double> elementBonus; // 元素伤害加成
  final int defenseBonus;                       // 防御加成
  final int shieldPowerBonus;                  // 护盾强度加成

  Timer? _cooldownTimer;
  final int _tickIntervalMs;

  MartialArtsSystem({
    this.skills = const [],
    this.activeInnerGongId,
    this.activeOuterGongId,
    this.activeLightSkillId,
    this.elementBonus = const {},
    this.defenseBonus = 0,
    this.shieldPowerBonus = 0,
    int tickIntervalMs = 100,
  }) : _tickIntervalMs = tickIntervalMs;

  /// 获取E技能
  List<MartialSkill> get eSkills => skills.where((s) => s.isEskill).toList();

  /// 获取Q技能
  List<MartialSkill> get qSkills => skills.where((s) => s.isQskill).toList();

  /// 获取内功技能
  List<MartialSkill> get innerGongSkills =>
      skills.where((s) => s.type == MartialArtType.innerGong).toList();

  /// 获取外功技能
  List<MartialSkill> get outerGongSkills =>
      skills.where((s) => s.type == MartialArtType.outerGong).toList();

  /// 获取轻功技能
  List<MartialSkill> get lightSkills =>
      skills.where((s) => s.type == MartialArtType.lightSkill).toList();

  /// 启动CD计时
  void startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(
      Duration(milliseconds: _tickIntervalMs),
      (_) => _tickAllCooldowns(),
    );
  }

  void stopCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  void _tickAllCooldowns() {
    // This would need to be Stateful - for now just a tick trigger
  }

  /// 检查技能是否可用
  bool canUseSkill(String skillId, int currentQi, int currentStamina) {
    final skill = skills.firstWhere(
      (s) => s.id == skillId,
      orElse: () => const MartialSkill(id: '', name: 'Unknown', description: '', type: MartialArtType.innerGong),
    );
    if (skill.id.isEmpty) return false;
    if (!skill.isReady) return false;
    if (currentQi < skill.qiCost) return false;
    if (currentStamina < skill.staminaCost) return false;
    return true;
  }

  /// 使用技能（返回消耗后的新技能状态）
  MartialSkill? useSkill(String skillId) {
    final index = skills.indexWhere((s) => s.id == skillId);
    if (index < 0) return null;
    final skill = skills[index];
    if (!skill.isReady) return null;
    return skill.use();
  }

  /// 获取技能by id
  MartialSkill? getSkill(String id) {
    try {
      return skills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 预设模板：新手武学套装
  static List<MartialSkill> get beginnerSet => [
    // 内功 - 气功罩
    const MartialSkill(
      id: 'inner_qigong_shield',
      name: '气功罩',
      description: '凝聚内力形成护盾，抵挡伤害',
      type: MartialArtType.innerGong,
      target: SkillTarget.self,
      qiCost: 15,
      shieldValue: 30,
      cooldownMs: 8000,
      isQskill: true,
      element: ElementType.none,
    ),
    // 外功 - 冲拳
    const MartialSkill(
      id: 'outer_punch_rush',
      name: '冲拳',
      description: '快速冲刺出拳，造成单体伤害',
      type: MartialArtType.outerGong,
      target: SkillTarget.enemy,
      qiCost: 10,
      damage: 25,
      staggerValue: 10,
      cooldownMs: 1500,
      isEskill: true,
      element: ElementType.none,
    ),
    // 外功 - 烈焰掌
    const MartialSkill(
      id: 'outer_fire_palm',
      name: '烈焰掌',
      description: '注入火元素，造成灼烧伤害',
      type: MartialArtType.outerGong,
      target: SkillTarget.enemy,
      qiCost: 20,
      damage: 40,
      staggerValue: 5,
      cooldownMs: 5000,
      isQskill: true,
      element: ElementType.fire,
      breaksArmor: true,
    ),
    // 轻功 - 燕回步
    const MartialSkill(
      id: 'light_swallow_step',
      name: '燕回步',
      description: '轻盈闪避，获得短暂无敌帧',
      type: MartialArtType.lightSkill,
      target: SkillTarget.self,
      qiCost: 8,
      staminaCost: 15,
      cooldownMs: 3000,
      isEskill: true,
    ),
  ];

  void dispose() {
    stopCooldownTicker();
  }
}
