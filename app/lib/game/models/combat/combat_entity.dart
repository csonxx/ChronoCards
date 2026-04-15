import 'elemental_system.dart';

/// 战斗中的角色/敌人基础数据
class CombatEntity {
  final String id;
  final String name;
  final int level;
  
  // 生命值
  final int maxHp;
  final int currentHp;
  
  // 体力（闪避、格挡、轻功消耗）
  final int maxStamina;
  final int currentStamina;
  
  // 内力/真气（技能消耗）
  final int maxQi;
  final int currentQi;
  
  // 剑意/气功（大招充能）
  final int maxSwordIntent;
  final int currentSwordIntent;
  
  // 战斗属性
  final int attack;
  final int defense;
  final int elementMastery; // 元素精通
  
  // 元素附着
  final List<ElementalStatus> elementalStatuses;
  
  // 状态标志
  final bool isInvincible;
  final bool isBlocking;
  final bool isPerfectBlock;
  final bool isFrozen;      // 冻结状态
  final bool isStunned;      // 眩晕状态
  final bool isBurning;      // 燃烧状态
  
  const CombatEntity({
    required this.id,
    required this.name,
    this.level = 1,
    required this.maxHp,
    required this.currentHp,
    this.maxStamina = 100,
    this.currentStamina = 100,
    this.maxQi = 80,
    this.currentQi = 80,
    this.maxSwordIntent = 100,
    this.currentSwordIntent = 0,
    this.attack = 100,
    this.defense = 50,
    this.elementMastery = 0,
    this.elementalStatuses = const [],
    this.isInvincible = false,
    this.isBlocking = false,
    this.isPerfectBlock = false,
    this.isFrozen = false,
    this.isStunned = false,
    this.isBurning = false,
  });

  /// 工厂方法：创建满状态角色
  factory CombatEntity.full({
    required String id,
    required String name,
    int level = 1,
    required int maxHp,
    int maxStamina = 100,
    int maxQi = 80,
    int maxSwordIntent = 100,
    int attack = 100,
    int defense = 50,
    int elementMastery = 0,
  }) {
    return CombatEntity(
      id: id,
      name: name,
      level: level,
      maxHp: maxHp,
      currentHp: maxHp,
      maxStamina: maxStamina,
      currentStamina: maxStamina,
      maxQi: maxQi,
      currentQi: maxQi,
      maxSwordIntent: maxSwordIntent,
      currentSwordIntent: 0,
      attack: attack,
      defense: defense,
      elementMastery: elementMastery,
    );
  }

  /// 是否死亡
  bool get isDead => currentHp <= 0;
  
  /// 生命百分比
  double get hpPercent => maxHp > 0 ? currentHp / maxHp : 0;
  
  /// 体力百分比
  double get staminaPercent => maxStamina > 0 ? currentStamina / maxStamina : 0;
  
  /// 内力百分比
  double get qiPercent => maxQi > 0 ? currentQi / maxQi : 0;
  
  /// 剑意百分比
  double get swordIntentPercent => maxSwordIntent > 0 ? currentSwordIntent / maxSwordIntent : 0;
  
  /// 低血量警告（<30%）
  bool get isLowHp => hpPercent < 0.3;
  
  /// 能否闪避
  bool get canDodge => currentStamina >= 15 && !isInvincible;
  
  /// 能否格挡
  bool get canBlock => currentStamina >= 15;
  
  /// 获取指定元素的状态
  ElementalStatus? getElementalStatus(ElementType element) {
    try {
      return elementalStatuses.firstWhere((s) => s.element == element);
    } catch (_) {
      return null;
    }
  }

  /// 受伤处理
  CombatEntity takeDamage(int damage, {bool ignoreDefense = false}) {
    if (isDead) return this;
    
    int actualDamage = damage;
    if (!ignoreDefense) {
      actualDamage = (damage - defense * 0.5).clamp(1, damage).round();
    }
    
    // 检查冻结状态（冻结时伤害减半）
    if (isFrozen) {
      actualDamage = (actualDamage * 0.5).round();
    }
    
    final newHp = (currentHp - actualDamage).clamp(0, maxHp);
    
    return copyWith(
      currentHp: newHp,
      isInvincible: false, // 受伤清除无敌
    );
  }

  /// 恢复生命
  CombatEntity heal(int amount) {
    final newHp = (currentHp + amount).clamp(0, maxHp);
    return copyWith(currentHp: newHp);
  }

  /// 消耗体力
  CombatEntity consumeStamina(int amount) {
    final newStamina = (currentStamina - amount).clamp(0, maxStamina);
    return copyWith(currentStamina: newStamina);
  }

  /// 消耗内力
  CombatEntity consumeQi(int amount) {
    final newQi = (currentQi - amount).clamp(0, maxQi);
    return copyWith(currentQi: newQi);
  }

  /// 积累剑意
  CombatEntity addSwordIntent(int amount) {
    final newIntent = (currentSwordIntent + amount).clamp(0, maxSwordIntent);
    return copyWith(currentSwordIntent: newIntent);
  }

  /// 添加元素附着
  CombatEntity addElementalStatus(ElementalStatus status) {
    final existing = getElementalStatus(status.element);
    List<ElementalStatus> newStatuses;
    
    if (existing != null) {
      // 更新已有元素（叠加）
      newStatuses = elementalStatuses.map((s) {
        if (s.element == status.element) {
          return status.addStack();
        }
        return s;
      }).toList();
    } else {
      // 添加新元素
      newStatuses = [...elementalStatuses, status];
    }
    
    return copyWith(elementalStatuses: newStatuses);
  }

  /// 清除元素状态
  CombatEntity clearElementalStatus(ElementType element) {
    return copyWith(
      elementalStatuses: elementalStatuses.where((s) => s.element != element).toList(),
    );
  }

  /// 清除所有元素状态
  CombatEntity clearAllElementalStatuses() {
    return copyWith(elementalStatuses: []);
  }

  CombatEntity copyWith({
    String? id,
    String? name,
    int? level,
    int? maxHp,
    int? currentHp,
    int? maxStamina,
    int? currentStamina,
    int? maxQi,
    int? currentQi,
    int? maxSwordIntent,
    int? currentSwordIntent,
    int? attack,
    int? defense,
    int? elementMastery,
    List<ElementalStatus>? elementalStatuses,
    bool? isInvincible,
    bool? isBlocking,
    bool? isPerfectBlock,
    bool? isFrozen,
    bool? isStunned,
    bool? isBurning,
  }) {
    return CombatEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      maxStamina: maxStamina ?? this.maxStamina,
      currentStamina: currentStamina ?? this.currentStamina,
      maxQi: maxQi ?? this.maxQi,
      currentQi: currentQi ?? this.currentQi,
      maxSwordIntent: maxSwordIntent ?? this.maxSwordIntent,
      currentSwordIntent: currentSwordIntent ?? this.currentSwordIntent,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      elementMastery: elementMastery ?? this.elementMastery,
      elementalStatuses: elementalStatuses ?? this.elementalStatuses,
      isInvincible: isInvincible ?? this.isInvincible,
      isBlocking: isBlocking ?? this.isBlocking,
      isPerfectBlock: isPerfectBlock ?? this.isPerfectBlock,
      isFrozen: isFrozen ?? this.isFrozen,
      isStunned: isStunned ?? this.isStunned,
      isBurning: isBurning ?? this.isBurning,
    );
  }
}
