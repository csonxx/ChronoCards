import 'package:flutter/foundation.dart';
import '../../domain/entities/player.dart';
import '../../domain/combat/martial_arts_system.dart';

/// 装备类型
enum EquipmentSlotType {
  weapon,    // 武器
  armor,     // 防具
  accessory1, // 饰品1
  accessory2, // 饰品2
}

/// 装备物品
class EquipmentItem {
  final String id;
  final String name;
  final String description;
  final EquipmentSlotType slotType;
  final int attackBonus;
  final int defenseBonus;
  final int healthBonus;
  final int qiBonus;      // 内力加成
  final int staminaBonus; // 体力加成
  final int levelRequired;
  final String iconEmoji;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.slotType,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.healthBonus = 0,
    this.qiBonus = 0,
    this.staminaBonus = 0,
    this.levelRequired = 1,
    this.iconEmoji = '📦',
  });

  EquipmentItem copyWith({
    String? id,
    String? name,
    String? description,
    EquipmentSlotType? slotType,
    int? attackBonus,
    int? defenseBonus,
    int? healthBonus,
    int? qiBonus,
    int? staminaBonus,
    int? levelRequired,
    String? iconEmoji,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      slotType: slotType ?? this.slotType,
      attackBonus: attackBonus ?? this.attackBonus,
      defenseBonus: defenseBonus ?? this.defenseBonus,
      healthBonus: healthBonus ?? this.healthBonus,
      qiBonus: qiBonus ?? this.qiBonus,
      staminaBonus: staminaBonus ?? this.staminaBonus,
      levelRequired: levelRequired ?? this.levelRequired,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }
}

/// EquipmentProvider - 装备系统状态管理
class EquipmentProvider extends ChangeNotifier {
  // 当前已装备的物品 (slot -> item)
  final Map<EquipmentSlotType, EquipmentItem?> _equippedItems = {
    EquipmentSlotType.weapon: null,
    EquipmentSlotType.armor: null,
    EquipmentSlotType.accessory1: null,
    EquipmentSlotType.accessory2: null,
  };

  // 预设物品列表 (用于选择界面)
  final List<EquipmentItem> _availableItems = [];

  // 是否加载中
  bool _isLoading = false;

  EquipmentProvider() {
    _loadMockItems();
  }

  // Getters
  Map<EquipmentSlotType, EquipmentItem?> get equippedItems => _equippedItems;
  List<EquipmentItem> get availableItems => _availableItems;
  bool get isLoading => _isLoading;

  /// 获取指定槽位的装备
  EquipmentItem? getEquipped(EquipmentSlotType slot) => _equippedItems[slot];

  /// 计算总属性加成
  int get totalAttackBonus {
    int bonus = 0;
    for (final item in _equippedItems.values) {
      if (item != null) bonus += item.attackBonus;
    }
    return bonus;
  }

  int get totalDefenseBonus {
    int bonus = 0;
    for (final item in _equippedItems.values) {
      if (item != null) bonus += item.defenseBonus;
    }
    return bonus;
  }

  int get totalHealthBonus {
    int bonus = 0;
    for (final item in _equippedItems.values) {
      if (item != null) bonus += item.healthBonus;
    }
    return bonus;
  }

  int get totalQiBonus {
    int bonus = 0;
    for (final item in _equippedItems.values) {
      if (item != null) bonus += item.qiBonus;
    }
    return bonus;
  }

  int get totalStaminaBonus {
    int bonus = 0;
    for (final item in _equippedItems.values) {
      if (item != null) bonus += item.staminaBonus;
    }
    return bonus;
  }

  /// 装备物品到指定槽位
  void equipItem(EquipmentItem item) {
    _equippedItems[item.slotType] = item;
    notifyListeners();
  }

  /// 卸下指定槽位的装备
  void unequipItem(EquipmentSlotType slot) {
    _equippedItems[slot] = null;
    notifyListeners();
  }

  /// 获取指定槽位可用的物品列表
  List<EquipmentItem> getAvailableForSlot(EquipmentSlotType slot) {
    return _availableItems.where((item) => item.slotType == slot).toList();
  }

  /// 加载Mock数据
  void _loadMockItems() {
    _availableItems.addAll([
      // 武器
      const EquipmentItem(
        id: 'weapon_iron_sword',
        name: '铁剑',
        description: '基础近战武器',
        slotType: EquipmentSlotType.weapon,
        attackBonus: 10,
        levelRequired: 1,
        iconEmoji: '⚔️',
      ),
      const EquipmentItem(
        id: 'weapon_steel_blade',
        name: '精钢刀',
        description: '锋利的钢制长刀',
        slotType: EquipmentSlotType.weapon,
        attackBonus: 18,
        defenseBonus: 2,
        levelRequired: 3,
        iconEmoji: '🔪',
      ),
      const EquipmentItem(
        id: 'weapon_dragon_saber',
        name: '龙泉剑',
        description: '传说中的神兵利器',
        slotType: EquipmentSlotType.weapon,
        attackBonus: 35,
        qiBonus: 15,
        levelRequired: 8,
        iconEmoji: '🐉',
      ),
      // 防具
      const EquipmentItem(
        id: 'armor_leather',
        name: '皮甲',
        description: '基础的皮革护甲',
        slotType: EquipmentSlotType.armor,
        defenseBonus: 8,
        healthBonus: 20,
        levelRequired: 1,
        iconEmoji: '🥋',
      ),
      const EquipmentItem(
        id: 'armor_iron_plate',
        name: '铁甲',
        description: '坚固的铁质铠甲',
        slotType: EquipmentSlotType.armor,
        defenseBonus: 18,
        healthBonus: 50,
        levelRequired: 5,
        iconEmoji: '🛡️',
      ),
      const EquipmentItem(
        id: 'armor_jade_vest',
        name: '玉蚕衣',
        description: '轻便而坚韧的防护内甲',
        slotType: EquipmentSlotType.armor,
        defenseBonus: 25,
        healthBonus: 80,
        qiBonus: 10,
        levelRequired: 10,
        iconEmoji: '💎',
      ),
      // 饰品1
      const EquipmentItem(
        id: 'acc1_power_ring',
        name: '力量戒指',
        description: '增加攻击力的戒指',
        slotType: EquipmentSlotType.accessory1,
        attackBonus: 5,
        levelRequired: 1,
        iconEmoji: '💍',
      ),
      const EquipmentItem(
        id: 'acc1_qi_pendant',
        name: '灵气玉佩',
        description: '增加内力上限',
        slotType: EquipmentSlotType.accessory1,
        qiBonus: 20,
        staminaBonus: 10,
        levelRequired: 4,
        iconEmoji: '📿',
      ),
      // 饰品2
      const EquipmentItem(
        id: 'acc2_speed_boots',
        name: '疾风靴',
        description: '增加闪避率',
        slotType: EquipmentSlotType.accessory2,
        defenseBonus: 3,
        staminaBonus: 15,
        levelRequired: 2,
        iconEmoji: '👢',
      ),
      const EquipmentItem(
        id: 'acc2_dragon_amulet',
        name: '龙纹护符',
        description: '全面属性提升',
        slotType: EquipmentSlotType.accessory2,
        attackBonus: 8,
        defenseBonus: 8,
        healthBonus: 30,
        qiBonus: 10,
        levelRequired: 6,
        iconEmoji: '🏮',
      ),
    ]);

    // 默认装备铁剑和皮甲
    final ironSword = _availableItems.firstWhere((i) => i.id == 'weapon_iron_sword');
    final leatherArmor = _availableItems.firstWhere((i) => i.id == 'armor_leather');
    equipItem(ironSword);
    equipItem(leatherArmor);
  }
}
