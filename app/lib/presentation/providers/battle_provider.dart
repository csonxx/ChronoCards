import 'package:flutter/foundation.dart';
import '../../../domain/entities/game_card.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/enemy.dart';
import '../../../domain/combat/martial_arts_system.dart';
import 'equipment_provider.dart';
import 'martial_arts_provider.dart';

/// Battle phase enum
enum BattlePhase {
  playerTurn,
  enemyTurn,
  actionResolution,
  gameOver,
}

/// 战斗中激活的技能效果
class ActiveSkillEffect {
  final String skillId;
  final String skillName;
  final int remainingMs;
  final int value; // 护盾值 / 增伤值 / 闪避率
  final bool isEskill;
  final bool isQskill;

  ActiveSkillEffect({
    required this.skillId,
    required this.skillName,
    required this.remainingMs,
    required this.value,
    this.isEskill = false,
    this.isQskill = false,
  });
}

/// BattleProvider - ChangeNotifier based state management for battles
/// Integrated with EquipmentProvider and MartialArtsProvider
class BattleProvider extends ChangeNotifier {
  Player _player = const Player(id: 'player_1', name: 'Player');
  Enemy _enemy = const Enemy(
    id: 'enemy_1',
    name: 'Shadow Fiend',
    health: 50,
    maxHealth: 50,
    attack: 8,
    defense: 5,
    level: 1,
  );
  List<GameCard> _hand = [];
  List<GameCard> _selectedCards = [];
  int _turn = 1;
  BattlePhase _phase = BattlePhase.playerTurn;
  bool _isLoading = false;
  String? _error;
  String _animationType = '';

  // ===== 装备/武学集成 =====
  EquipmentProvider? _equipmentProvider;
  MartialArtsProvider? _martialArtsProvider;

  // 玩家护盾（来自内功）
  int _playerShield = 0;
  int _maxShield = 0;

  // 战斗中激活的技能效果
  final List<ActiveSkillEffect> _activeEffects = [];

  // 增伤倍率（来自外功/内功）
  double _damageMultiplier = 1.0;

  // 闪避率（来自轻功）
  double _dodgeChance = 0.0;

  // 玩家属性加成（来自装备）
  int _equipmentAttackBonus = 0;
  int _equipmentDefenseBonus = 0;
  int _equipmentHealthBonus = 0;

  // 技能冷却追踪
  final Map<String, int> _skillCooldowns = {}; // skillId -> remaining ms

  // Getters
  Player get player => _player;
  Enemy get enemy => _enemy;
  List<GameCard> get hand => _hand;
  List<GameCard> get selectedCards => _selectedCards;
  int get turn => _turn;
  BattlePhase get phase => _phase;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get animationType => _animationType;

  // 装备/武学 Getters
  int get playerShield => _playerShield;
  int get maxShield => _maxShield;
  double get damageMultiplier => _damageMultiplier;
  double get dodgeChance => _dodgeChance;
  List<ActiveSkillEffect> get activeEffects => _activeEffects;
  Map<String, int> get skillCooldowns => _skillCooldowns;

  bool get isPlayerTurn => _phase == BattlePhase.playerTurn;
  bool get hasSelectedCards => _selectedCards.isNotEmpty;

  /// 设置装备Provider（由外部注入）
  void setEquipmentProvider(EquipmentProvider provider) {
    _equipmentProvider = provider;
    _syncEquipmentBonus();
    notifyListeners();
  }

  /// 设置武学Provider（由外部注入）
  void setMartialArtsProvider(MartialArtsProvider provider) {
    _martialArtsProvider = provider;
    _syncMartialArtsBonus();
    notifyListeners();
  }

  /// 同步装备属性加成到战斗属性
  void _syncEquipmentBonus() {
    if (_equipmentProvider == null) return;
    _equipmentAttackBonus = _equipmentProvider!.totalAttackBonus;
    _equipmentDefenseBonus = _equipmentProvider!.totalDefenseBonus;
    _equipmentHealthBonus = _equipmentProvider!.totalHealthBonus;
  }

  /// 同步武学加成（内功防御、外功增伤、轻功闪避）
  void _syncMartialArtsBonus() {
    if (_martialArtsProvider == null) return;

    // 内功加成
    final innerGong = _martialArtsProvider!.activeInnerGong;
    if (innerGong != null) {
      if (innerGong.shieldValue > 0) {
        _maxShield = innerGong.shieldValue;
      }
      // 内功元素加成
      if (innerGong.element != ElementType.none) {
        _damageMultiplier = 1.15; // 元素内功+15%伤害
      }
    }

    // 外功不改变倍率，但外功技能本身有伤害

    // 轻功加成
    final lightSkill = _martialArtsProvider!.activeLightSkill;
    if (lightSkill != null) {
      // 轻功闪避效果（燕回步等）
      if (lightSkill.id == 'light_swallow_step') {
        _dodgeChance = 0.25; // 25%闪避
      } else if (lightSkill.id == 'light_cloud_walk') {
        _dodgeChance = 0.40; // 40%闪避
      }
    }
  }

  /// 获取技能剩余冷却时间(ms)
  int getSkillCooldown(String skillId) {
    return _skillCooldowns[skillId] ?? 0;
  }

  /// 检查E技能是否可用
  bool isESkillReady(String skillId) {
    final remaining = _skillCooldowns[skillId] ?? 0;
    return remaining <= 0;
  }

  /// 检查Q技能是否可用
  bool isQSkillReady(String skillId) {
    final remaining = _skillCooldowns[skillId] ?? 0;
    return remaining <= 0;
  }

  /// 使用E技能（轻功/外功）
  Future<void> useESkill(String skillId) async {
    if (_phase != BattlePhase.playerTurn) return;
    if (!isESkillReady(skillId)) return;

    final skill = _getMartialSkill(skillId);
    if (skill == null) return;

    // 检查气力
    if (_player.mana < skill.qiCost) {
      _error = '内力不足';
      notifyListeners();
      return;
    }

    _animationType = 'skill_e_${skill.type.name}';
    notifyListeners();

    // 消耗内力
    _player = _player.copyWith(mana: _player.mana - skill.qiCost);

    if (skill.target == SkillTarget.self) {
      // 轻功类：闪避/加速
      if (skill.staminaCost > 0) {
        // 燕回步 - 闪避
        _dodgeChance = 0.25;
        _addActiveEffect(skill, 2500); // 持续2.5秒
      }
      if (skill.shieldValue > 0) {
        // 内功护盾（E技能）
        _playerShield = skill.shieldValue;
        _maxShield = skill.shieldValue;
        _addActiveEffect(skill, 5000);
      }
    } else if (skill.target == SkillTarget.enemy) {
      // 外功类：伤害
      final damage = _calculateSkillDamage(skill);
      _enemy = _enemy.copyWith(
        health: (_enemy.health - damage).clamp(0, _enemy.maxHealth),
      );

      // 硬直效果
      if (skill.staggerValue > 0) {
        // 敌人眩晕/停顿（简化处理）
        _animationType = 'stagger';
      }

      // 元素效果
      if (skill.element != ElementType.none) {
        _animationType = 'element_${skill.element.name}';
      }
    }

    // 设置冷却
    if (skill.cooldownMs > 0) {
      _skillCooldowns[skillId] = skill.cooldownMs;
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    _animationType = '';
    _checkBattleEnd();
  }

  /// 使用Q技能（内功/外功大招）
  Future<void> useQSkill(String skillId) async {
    if (_phase != BattlePhase.playerTurn) return;
    if (!isQSkillReady(skillId)) return;

    final skill = _getMartialSkill(skillId);
    if (skill == null) return;

    // 检查气力
    if (_player.mana < skill.qiCost) {
      _error = '内力不足';
      notifyListeners();
      return;
    }

    _animationType = 'skill_q_${skill.type.name}';
    notifyListeners();

    // 消耗内力
    _player = _player.copyWith(mana: _player.mana - skill.qiCost);

    if (skill.target == SkillTarget.self) {
      // 内功护盾（Q技能，如气功罩）
      if (skill.shieldValue > 0) {
        _playerShield = skill.shieldValue;
        _maxShield = skill.shieldValue;
        _addActiveEffect(skill, 8000);
      }

      // 元素增益
      if (skill.element == ElementType.fire) {
        _damageMultiplier = 1.25;
        _addActiveEffect(skill, 10000);
      } else if (skill.element == ElementType.ice) {
        _equipmentDefenseBonus += 20; // 寒冰+防御
        _addActiveEffect(skill, 10000);
      }
    } else if (skill.target == SkillTarget.enemy) {
      // 外功大招：烈焰掌、雷霆拳
      var damage = _calculateSkillDamage(skill);

      // 破甲效果
      if (skill.breaksArmor) {
        damage = (damage * 1.3).toInt(); // 破甲+30%伤害
      }

      // AOE
      if (skill.isAoe) {
        _animationType = 'aoe';
      }

      _enemy = _enemy.copyWith(
        health: (_enemy.health - damage).clamp(0, _enemy.maxHealth),
      );

      // 硬直
      if (skill.staggerValue > 0) {
        _animationType = 'heavy_stagger';
      }

      // 元素特效
      if (skill.element != ElementType.none) {
        _animationType = 'element_${skill.element.name}';
      }
    }

    // 设置冷却
    if (skill.cooldownMs > 0) {
      _skillCooldowns[skillId] = skill.cooldownMs;
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 700));

    _animationType = '';
    _checkBattleEnd();
  }

  /// 获取武学技能
  MartialSkill? _getMartialSkill(String skillId) {
    if (_martialArtsProvider == null) return null;
    try {
      return _martialArtsProvider!.learnedSkills.firstWhere((s) => s.id == skillId);
    } catch (_) {
      return null;
    }
  }

  /// 计算技能伤害（含装备加成）
  int _calculateSkillDamage(MartialSkill skill) {
    var damage = skill.damage;

    // 装备武器攻击加成
    damage += _equipmentAttackBonus;

    // 增伤倍率
    damage = (damage * _damageMultiplier).toInt();

    // 外功基础增伤
    if (skill.type == MartialArtType.outerGong) {
      damage = (damage * 1.1).toInt();
    }

    return damage;
  }

  /// 添加激活效果
  void _addActiveEffect(MartialSkill skill, int durationMs) {
    _activeEffects.removeWhere((e) => e.skillId == skill.id);
    _activeEffects.add(ActiveSkillEffect(
      skillId: skill.id,
      skillName: skill.name,
      remainingMs: durationMs,
      value: skill.shieldValue > 0 ? skill.shieldValue : (skill.staggerValue > 0 ? skill.staggerValue : 0),
      isEskill: skill.isEskill,
      isQskill: skill.isQskill,
    ));
  }

  /// 每帧更新（供外部Timer调用，减少技能冷却）
  void tickCooldowns(int deltaMs) {
    bool changed = false;

    _skillCooldowns.forEach((skillId, remaining) {
      if (remaining > 0) {
        _skillCooldowns[skillId] = (remaining - deltaMs).clamp(0, 999999);
        changed = true;
      }
    });

    // 更新激活效果持续时间
    for (int i = _activeEffects.length - 1; i >= 0; i--) {
      _activeEffects[i] = ActiveSkillEffect(
        skillId: _activeEffects[i].skillId,
        skillName: _activeEffects[i].skillName,
        remainingMs: (_activeEffects[i].remainingMs - deltaMs).clamp(0, 999999),
        value: _activeEffects[i].value,
        isEskill: _activeEffects[i].isEskill,
        isQskill: _activeEffects[i].isQskill,
      );
      if (_activeEffects[i].remainingMs <= 0) {
        _activeEffects.removeAt(i);
        changed = true;
      }
    }

    // 检查护盾是否过期
    if (_playerShield > 0 && _maxShield > 0) {
      // 护盾随时间自然衰减（简化处理）
      if (_activeEffects.where((e) => e.skillId.contains('qigong') || e.skillId.contains('ice')).isEmpty) {
        _playerShield = 0;
        _maxShield = 0;
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  /// Start a new battle
  Future<void> startBattle(String enemyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 同步装备加成
      _syncEquipmentBonus();
      _syncMartialArtsBonus();

      // 计算初始生命（含装备加成）
      final baseMaxHealth = 100 + _equipmentHealthBonus;

      _player = Player(
        id: 'player_1',
        name: 'Chrono Traveler',
        health: baseMaxHealth,
        maxHealth: baseMaxHealth,
        mana: 20 + (_equipmentProvider?.totalQiBonus ?? 0),
        maxMana: 20 + (_equipmentProvider?.totalQiBonus ?? 0),
      );

      _enemy = Enemy(
        id: enemyId,
        name: 'Shadow Fiend',
        health: 80,
        maxHealth: 80,
        attack: 12,
        defense: 5,
        level: 1,
      );

      _hand = _generateBattleHand();
      _selectedCards = [];
      _turn = 1;
      _phase = BattlePhase.playerTurn;
      _animationType = '';
      _playerShield = 0;
      _maxShield = 0;
      _damageMultiplier = 1.0;
      _dodgeChance = 0.0;
      _activeEffects.clear();
      _skillCooldowns.clear();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start battle: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a card for attack
  void selectCard(GameCard card) {
    if (_phase != BattlePhase.playerTurn) return;

    if (!_selectedCards.any((c) => c.id == card.id)) {
      _selectedCards = [..._selectedCards, card];
      notifyListeners();
    }
  }

  /// Deselect a card
  void deselectCard(String cardId) {
    _selectedCards = _selectedCards.where((c) => c.id != cardId).toList();
    notifyListeners();
  }

  /// Clear all selected cards
  void clearSelectedCards() {
    _selectedCards = [];
    notifyListeners();
  }

  /// Execute attack with selected cards
  /// 伤害计算：卡牌伤害 + 装备攻击加成（含武器）
  Future<void> executeAttack() async {
    if (_selectedCards.isEmpty) return;

    _animationType = 'attack';
    notifyListeners();

    int totalDamage = 0;
    for (final card in _selectedCards) {
      totalDamage += card.attack;
    }

    // 装备武器加成
    totalDamage += _equipmentAttackBonus;

    // 增伤倍率
    totalDamage = (totalDamage * _damageMultiplier).toInt();

    // 敌人防御（装备防御部分忽略）
    final effectiveDefense = (_enemy.defense - _equipmentDefenseBonus ~/ 2).clamp(0, 999);
    final damage = totalDamage - effectiveDefense;

    _enemy = _enemy.copyWith(
      health: (_enemy.health - damage).clamp(0, _enemy.maxHealth),
    );

    _hand = _hand.where((c) => !_selectedCards.contains(c)).toList();
    _selectedCards = [];

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _animationType = '';
    _checkBattleEnd();
  }

  /// Execute a skill card
  Future<void> executeSkill(GameCard card) async {
    _animationType = 'skill';
    notifyListeners();

    if (card.type == CardType.defense) {
      // 防御牌增加内力/护盾
      _player = _player.copyWith(
        mana: _player.mana + card.defense,
      );
    }

    _hand = _hand.where((c) => c.id != card.id).toList();

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _animationType = '';
    notifyListeners();
  }

  /// End player turn
  void endPlayerTurn() {
    _selectedCards = [];
    _phase = BattlePhase.enemyTurn;
    notifyListeners();

    _processEnemyTurn();
  }

  /// Process enemy turn
  Future<void> _processEnemyTurn() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _enemyAttack();
  }

  /// Enemy attacks player
  /// 伤害计算：敌人攻击 - 玩家装备防御 - 护盾吸收 - 闪避
  Future<void> _enemyAttack() async {
    _animationType = 'enemy_attack';
    notifyListeners();

    var baseDamage = _enemy.attack;

    // 检查闪避（轻功）
    if (_dodgeChance > 0) {
      final roll = DateTime.now().millisecondsSinceEpoch % 100 / 100.0;
      if (roll < _dodgeChance) {
        _animationType = 'dodge';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));
        _turn++;
        _phase = BattlePhase.playerTurn;
        _animationType = '';
        notifyListeners();
        return;
      }
    }

    // 护盾吸收
    if (_playerShield > 0) {
      final absorbed = _playerShield.clamp(0, baseDamage);
      _playerShield -= absorbed;
      baseDamage -= absorbed;
      if (absorbed > 0) {
        _animationType = 'shield_hit';
      }
      if (_playerShield <= 0) {
        _maxShield = 0;
      }
    }

    // 装备防御减伤
    baseDamage -= _equipmentDefenseBonus;

    // 装备防御减伤（内功无defenseBonus字段，用装备替代）
    baseDamage = baseDamage.clamp(1, 999); // 至少1伤害

    _player = _player.copyWith(
      health: (_player.health - baseDamage).clamp(0, _player.maxHealth),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    _turn++;
    _phase = BattlePhase.playerTurn;
    _animationType = '';

    _checkBattleEnd();
  }

  /// Check if battle has ended
  void _checkBattleEnd() {
    if (_enemy.health <= 0) {
      _phase = BattlePhase.gameOver;
      _animationType = 'victory';
    } else if (_player.health <= 0) {
      _phase = BattlePhase.gameOver;
      _animationType = 'defeat';
    }
    notifyListeners();
  }


  /// Check if player won
  bool get isVictory => _enemy.health <= 0 && _phase == BattlePhase.gameOver;

  /// Check if player lost
  bool get isDefeat => _player.health <= 0 && _phase == BattlePhase.gameOver;

  /// Generate initial battle hand
  List<GameCard> _generateBattleHand() {
    return [
      const GameCard(
        id: 'battle_card_1',
        name: 'Quick Strike',
        description: 'Fast attack',
        type: CardType.attack,
        rarity: CardRarity.common,
        cost: 1,
        attack: 8,
        defense: 0,
      ),
      const GameCard(
        id: 'battle_card_2',
        name: 'Heavy Blow',
        description: 'Strong attack',
        type: CardType.attack,
        rarity: CardRarity.uncommon,
        cost: 3,
        attack: 15,
        defense: 0,
      ),
      const GameCard(
        id: 'battle_card_3',
        name: 'Stone Wall',
        description: 'Defensive stance',
        type: CardType.defense,
        rarity: CardRarity.common,
        cost: 2,
        attack: 0,
        defense: 10,
      ),
      const GameCard(
        id: 'battle_card_4',
        name: 'Fireball',
        description: 'Magic attack',
        type: CardType.magic,
        rarity: CardRarity.rare,
        cost: 4,
        attack: 20,
        defense: 0,
      ),
    ];
  }
}
