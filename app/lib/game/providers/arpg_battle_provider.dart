import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/combat/combat_entity.dart';
import '../models/combat/skill.dart';
import '../models/combat/elemental_system.dart';
import '../models/combat/enemy_ai.dart';
import '../../domain/combat/combat_system.dart';
import '../../domain/combat/enemy_behavior.dart';

/// ARPG战斗阶段
enum ARPGBattlePhase {
  intro,         // 战斗开始介绍
  combat,        // 战斗中
  playerTurn,    // 玩家主动阶段
  enemyTurn,     // 敌人行动阶段
  victory,       // 胜利
  defeat,        // 失败
  paused,        // 暂停
}

/// 战斗伤害信息
class DamageInfo {
  final int value;
  final bool isCrit;
  final bool isBlocked;
  final bool isPerfectBlock;
  final bool isDodged;
  final int shieldBroken; // 护盾被击碎时>0
  final ElementalReactionType? reaction;
  final String? reactionName;

  const DamageInfo({
    required this.value,
    this.isCrit = false,
    this.isBlocked = false,
    this.isPerfectBlock = false,
    this.isDodged = false,
    this.shieldBroken = 0,
    this.reaction,
    this.reactionName,
  });
}

/// ARPG战斗Provider - 基于Provider/ChangeNotifier架构（非BLoC）
/// 全功能Phase 1.1: 三资源系统 + 连击 + 技能 + 闪避无敌帧(可叠加) + 格挡反击 + 敌人行为系统 + 仇恨系统
class ARPGBattleProvider extends ChangeNotifier {
  // 战斗阶段
  ARPGBattlePhase _phase = ARPGBattlePhase.intro;
  ARPGBattlePhase get phase => _phase;

  // ===== 核心战斗系统 =====
  final CombatSystem _combatSystem = CombatSystem();

  // 玩家数据
  CombatEntity _player = CombatEntity.full(
    id: 'player',
    name: '江湖游侠',
    level: 12,
    maxHp: 1000,
    maxStamina: 100,
    maxQi: 80,
    attack: 150,
    defense: 80,
    elementMastery: 45,
  );
  CombatEntity get player => _player;

  // 敌人数据
  CombatEntity _enemy = CombatEntity.full(
    id: 'enemy',
    name: '明教弟子',
    level: 12,
    maxHp: 1200,
    maxStamina: 60,
    maxQi: 40,
    attack: 120,
    defense: 60,
    elementMastery: 30,
  );
  CombatEntity get enemy => _enemy;

  // 玩家硬直状态
  StaggerState _playerStagger = const StaggerState();
  StaggerState get playerStagger => _playerStagger;

  // ===== 敌人行为系统 =====
  EnemyAI? _enemyAI;
  EnemyBehavior? _enemyBehavior;

  // 玩家技能
  List<Skill> _playerSkills = [
    SkillLibrary.lightAttack,
    SkillLibrary.heavyAttack,
    SkillLibrary.dodge,
    SkillLibrary.block,
    ...SkillLibrary.eSkills,
    ...SkillLibrary.qSkills,
  ];
  List<Skill> get playerSkills => _playerSkills;

  // 连击状态
  int _comboStage = 1; // 1-3
  int get comboStage => _comboStage;

  // 攻击状态
  bool _isAttacking = false;
  bool get isAttacking => _isAttacking;

  // 伤害数字显示
  DamageInfo? _lastPlayerDamage;
  DamageInfo? _lastEnemyDamage;
  DamageInfo? get lastPlayerDamage => _lastPlayerDamage;
  DamageInfo? get lastEnemyDamage => _lastEnemyDamage;

  // 战斗日志
  final List<String> _battleLog = [];
  List<String> get battleLog => List.unmodifiable(_battleLog);

  // 时间管理
  Timer? _gameTimer;
  double _elapsedTime = 0;
  int _currentTimeMs = 0;

  // 伤害数字显示定时器
  Timer? _damageDisplayTimer;

  // 常量
  static const double _staminaRecoveryPerSec = 8.0;
  static const double _qiRecoveryPerSec = 5.0;

  /// 开始战斗
  void startBattle({String enemyType = 'mingjiao_disciple', int enemyLevel = 12}) {
    _phase = ARPGBattlePhase.intro;
    _elapsedTime = 0;
    _currentTimeMs = DateTime.now().millisecondsSinceEpoch;
    _comboStage = 1;
    _isAttacking = false;
    _lastPlayerDamage = null;
    _lastEnemyDamage = null;
    _battleLog.clear();
    _playerStagger = const StaggerState();

    // 初始化敌人AI（旧版，保留兼容性）
    _enemyAI = EnemyAIConfig.create(enemyType, level: enemyLevel);

    // 初始化敌人行为系统（新版）
    _enemyBehavior = _createEnemyBehavior(enemyType);
    if (_enemyBehavior != null) {
      _log('敌人行为系统初始化: ${enemyType}');
    }

    // 重置玩家状态
    _player = CombatEntity.full(
      id: 'player',
      name: '江湖游侠',
      level: 12,
      maxHp: 1000,
      maxStamina: 100,
      maxQi: 80,
      attack: 150,
      defense: 80,
      elementMastery: 45,
    );

    // 根据敌人类型设置敌人属性
    _enemy = _createEnemy(enemyType, enemyLevel);

    // 重置技能冷却
    _playerSkills = _playerSkills.map((s) => s.resetCooldown()).toList();

    _log('战斗开始！');
    notifyListeners();

    // 延迟进入战斗
    Future.delayed(const Duration(milliseconds: 1500), () {
      _phase = ARPGBattlePhase.combat;
      _startGameLoop();
      notifyListeners();
    });
  }

  EnemyBehavior? _createEnemyBehavior(String type) {
    switch (type) {
      case 'boss_tianmo':
        return EnemyBehaviorConfig.tianmoBoss.create();
      case 'shaolin_monk':
        return EnemyBehaviorConfig.shaolinMonk.create();
      case 'wudang_sword':
        return EnemyBehaviorConfig.wudangSword.create();
      case 'mingjiao_disciple':
      default:
        return EnemyBehaviorConfig.mingjiaoDisciple.create();
    }
  }

  EnemyAttackMode _getEnemyAttackMode(String type) {
    switch (type) {
      case 'boss_tianmo':
        return EnemyAttackMode.rush;
      case 'shaolin_monk':
        return EnemyAttackMode.heavy;
      case 'wudang_sword':
        return EnemyAttackMode.area;
      case 'mingjiao_disciple':
      default:
        return EnemyAttackMode.rush;
    }
  }

  CombatEntity _createEnemy(String type, int level) {
    switch (type) {
      case 'boss_tianmo':
        return CombatEntity.full(
          id: 'enemy',
          name: '天魔',
          level: level,
          maxHp: 3000,
          maxStamina: 100,
          maxQi: 100,
          attack: 200,
          defense: 100,
          elementMastery: 60,
        );
      case 'shaolin_monk':
        return CombatEntity.full(
          id: 'enemy',
          name: '少林武僧',
          level: level,
          maxHp: 1500,
          maxStamina: 80,
          maxQi: 60,
          attack: 160,
          defense: 120,
          elementMastery: 20,
        );
      default:
        return CombatEntity.full(
          id: 'enemy',
          name: '明教弟子',
          level: level,
          maxHp: 1200,
          maxStamina: 60,
          maxQi: 40,
          attack: 120,
          defense: 60,
          elementMastery: 30,
        );
    }
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update(0.016); // ~60fps
    });
  }

  void _stopGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _update(double deltaTime) {
    if (_phase != ARPGBattlePhase.combat) return;

    _elapsedTime += deltaTime;
    _currentTimeMs = DateTime.now().millisecondsSinceEpoch;

    // 更新技能冷却
    _playerSkills = _playerSkills.map((s) => s.tickCooldown(deltaTime)).toList();

    // 恢复资源
    _recoverResources(deltaTime);

    // 更新元素状态持续时间
    _updateElementalStatuses(deltaTime);

    // 更新玩家硬直状态
    _playerStagger = _playerStagger.update(_currentTimeMs);

    // 更新敌人行为系统
    _updateEnemyBehavior();

    // 更新敌人AI（旧版，保留）
    _enemyAI?.update(deltaTime, _enemy, _player);

    // 检查战斗结束
    _checkBattleEnd();

    notifyListeners();
  }

  void _updateEnemyBehavior() {
    if (_enemyBehavior == null) return;

    final enemyType = _enemy.name == '天魔'
        ? 'boss_tianmo'
        : (_enemy.name == '少林武僧' ? 'shaolin_monk' : 'mingjiao_disciple');
    final preferredMode = _getEnemyAttackMode(enemyType);

    final event = _enemyBehavior!.update(
      _currentTimeMs,
      _enemy,
      _player,
      preferredMode,
    );

    if (event != null) {
      switch (event.type) {
        case AttackEventType.attackStart:
          _log('${_enemy.name} 准备使用 ${event.action?.name}！');
          break;
        case AttackEventType.attackHit:
          if (event.damage != null) {
            _dealDamageToPlayer(event.damage!);
          }
          break;
        case AttackEventType.attackEnd:
          _log('${_enemy.name} 攻击结束');
          break;
      }
    }
  }

  void _recoverResources(double deltaTime) {
    // 恢复体力（非格挡时）
    if (!_player.isBlocking && _player.currentStamina < _player.maxStamina) {
      _player = _player.copyWith(
        currentStamina: (_player.currentStamina + _staminaRecoveryPerSec * deltaTime)
            .clamp(0, _player.maxStamina).round(),
      );
    }

    // 恢复内力
    if (_player.currentQi < _player.maxQi) {
      _player = _player.copyWith(
        currentQi: (_player.currentQi + _qiRecoveryPerSec * deltaTime)
            .clamp(0, _player.maxQi).round(),
      );
    }
  }

  void _updateElementalStatuses(double deltaTime) {
    // 更新玩家元素状态
    if (_player.elementalStatuses.isNotEmpty) {
      final updatedStatuses = _player.elementalStatuses
          .map((s) => s.copyWith(duration: s.duration - deltaTime))
          .where((s) => s.duration > 0)
          .toList();
      _player = _player.copyWith(elementalStatuses: updatedStatuses);
    }

    // 更新敌人元素状态
    if (_enemy.elementalStatuses.isNotEmpty) {
      final updatedStatuses = _enemy.elementalStatuses
          .map((s) => s.copyWith(duration: s.duration - deltaTime))
          .where((s) => s.duration > 0)
          .toList();
      _enemy = _enemy.copyWith(elementalStatuses: updatedStatuses);
    }
  }

  void _checkBattleEnd() {
    if (_enemy.isDead) {
      _phase = ARPGBattlePhase.victory;
      _stopGameLoop();
      _log('胜利！');
    } else if (_player.isDead) {
      _phase = ARPGBattlePhase.defeat;
      _stopGameLoop();
      _log('败北...');
    }
  }

  // ==================== 玩家操作 ====================

  /// 轻攻击
  void lightAttack() {
    if (_phase != ARPGBattlePhase.combat || _isAttacking) return;
    if (_player.isStunned || _player.isFrozen) return;
    if (_playerStagger.isStaggered) return;

    _isAttacking = true;

    // 计算伤害
    final damage = _combatSystem.calculateAttackDamage(
      attackerAttack: _player.attack,
      damageMultiplier: 0.4,
      baseDamage: 0,
      targetDefense: _enemy.defense,
      isCrit: _randomCrit(),
      elementBonus: _getPlayerElementBonus(),
    );
    final isCrit = _randomCrit();

    // 造成伤害
    _dealDamageToEnemy(damage, isCrit);

    // 消耗精力
    _player = _player.consumeStamina(5);

    // 对敌人造成硬直
    _enemyBehavior?.applyStagger(
      CombatSystem.lightAttackStaggerMs ~/ 10, // 轻攻击产生少量硬直
      _currentTimeMs,
      _combatSystem,
    );

    // 积累剑意
    _player = _player.addSwordIntent(3);

    // 推进连击
    _comboStage = 2;

    _log('${_player.name} 使用轻击！${isCrit ? "暴击！" : ""}');

    Future.delayed(const Duration(milliseconds: 200), () {
      _isAttacking = false;
      notifyListeners();
    });

    notifyListeners();
  }

  /// 重攻击
  void heavyAttack() {
    if (_phase != ARPGBattlePhase.combat || _isAttacking) return;
    if (_player.isStunned || _player.isFrozen) return;
    if (_playerStagger.isStaggered) return;

    _isAttacking = true;

    final damage = _combatSystem.calculateAttackDamage(
      attackerAttack: _player.attack,
      damageMultiplier: 1.0,
      baseDamage: 0,
      targetDefense: _enemy.defense,
      isCrit: _randomCrit(),
      elementBonus: _getPlayerElementBonus(),
    );
    final isCrit = _randomCrit();

    _dealDamageToEnemy(damage, isCrit);

    // 重攻击消耗更多体力
    _player = _player.consumeStamina(12);

    // 对敌人造成较大硬直
    _enemyBehavior?.applyStagger(
      CombatSystem.heavyAttackStaggerMs ~/ 10,
      _currentTimeMs,
      _combatSystem,
    );

    // 大量剑意
    _player = _player.addSwordIntent(8);

    // 重置连击
    _comboStage = 1;

    _log('${_player.name} 使用重击！${isCrit ? "暴击！" : ""}');

    Future.delayed(const Duration(milliseconds: 350), () {
      _isAttacking = false;
      notifyListeners();
    });

    notifyListeners();
  }

  /// 闪避 - 使用新的CombatSystem的无敌帧机制（可叠加）
  void dodge() {
    if (_phase != ARPGBattlePhase.combat) return;

    // 使用CombatSystem的闪避判定
    final dodgeResult = _combatSystem.tryDodge(
      _getPlayerResources(),
      _currentTimeMs,
    );

    if (!dodgeResult.success) {
      _log('闪避失败：体力不足或已在无敌中');
      return;
    }

    // 消耗体力
    _player = _player.consumeStamina(CombatSystem.dodgeStaminaCost);

    // 更新无敌帧
    if (dodgeResult.iFramesExtended) {
      _log('闪避！无敌帧延长${CombatSystem.baseInvincibleDurationMs}ms');
    } else {
      _log('闪避！激活${CombatSystem.baseInvincibleDurationMs}ms无敌帧');
    }

    // 闪避增加少量剑意
    _player = _player.addSwordIntent(2);

    notifyListeners();
  }

  /// 开始格挡（长按）- 使用新的完美格挡机制
  void startBlock() {
    if (_phase != ARPGBattlePhase.combat) return;
    if (_player.currentStamina < CombatSystem.blockStaminaCost) return;

    _player = _player.copyWith(isBlocking: true);
    _log('格挡姿态...');
    notifyListeners();
  }

  /// 结束格挡
  void endBlock() {
    if (!_player.isBlocking) return;

    _player = _player.copyWith(isBlocking: false, isPerfectBlock: false);
    notifyListeners();
  }

  /// 使用技能
  void useSkill(int skillIndex) {
    if (_phase != ARPGBattlePhase.combat) return;
    if (skillIndex >= _playerSkills.length) return;
    if (_playerStagger.isStaggered) return;

    final skill = _playerSkills[skillIndex];

    // 检查冷却和资源
    if (!skill.isReady) return;
    if (_player.currentQi < skill.qiCost) return;
    if (_player.currentStamina < skill.staminaCost) return;
    if (_player.currentSwordIntent < skill.swordIntentCost) return;

    // 消耗资源
    _player = _player.consumeQi(skill.qiCost);
    _player = _player.consumeStamina(skill.staminaCost);

    // 设置冷却
    _playerSkills[skillIndex] = skill.resetCooldown();

    // 计算伤害
    final damage = _combatSystem.calculateAttackDamage(
      attackerAttack: _player.attack,
      damageMultiplier: skill.damageMultiplier,
      baseDamage: skill.baseDamage,
      targetDefense: _enemy.defense,
      isCrit: _randomCrit(),
      elementBonus: _getPlayerElementBonus(),
    );
    final isCrit = _randomCrit();

    // 造成伤害
    _dealDamageToEnemy(damage, isCrit);

    // 附加元素
    if (skill.elementalType != null) {
      final elementStatus = ElementalStatus(
        element: skill.elementalType!,
        stacks: skill.applyElementStacks,
        duration: 5.0,
        damagePerSec: skill.baseDamage * 0.1,
      );
      _enemy = _enemy.addElementalStatus(elementStatus);

      // 检查元素反应
      _checkElementalReaction(skill.elementalType!);
    }

    // 如果技能有无敌效果
    if (skill.isInvincible) {
      final invincibleUntil = _currentTimeMs + 300;
      _player = _player.copyWith(isInvincible: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        _player = _player.copyWith(isInvincible: false);
        notifyListeners();
      });
      (void)invincibleUntil;
    }

    // 剑意积累
    _player = _player.addSwordIntent(skill.type == SkillType.Q ? 20 : 10);

    _log('${_player.name} 使用 ${skill.name}！${isCrit ? "暴击！" : ""}');

    notifyListeners();
  }

  void _dealDamageToEnemy(int damage, bool isCrit) {
    // 伤害已由CombatSystem计算，这里直接应用
    _enemy = _enemy.takeDamage(damage);
    _lastEnemyDamage = DamageInfo(value: damage, isCrit: isCrit);

    // 对敌人产生仇恨
    _enemyBehavior?.generateThreat('player', 50, _currentTimeMs);

    // 显示伤害数字
    _showDamageNumber(_lastEnemyDamage!, true);

    // 消耗敌人身上的元素附着
    for (final status in _enemy.elementalStatuses) {
      if (status.duration > 0) {
        _enemy = _enemy.clearElementalStatus(status.element);
        break;
      }
    }
  }

  /// 使用CombatSystem处理玩家受击（护盾优先消耗）
  void _dealDamageToPlayer(int damage, {bool ignoreDefense = false}) {
    // 无敌帧直接免疫
    if (_player.isInvincible) {
      _lastPlayerDamage = const DamageInfo(value: 0, isDodged: true);
      _showDamageNumber(_lastPlayerDamage!, false);
      _log('闪避成功！');
      return;
    }

    // 格挡判定（使用CombatSystem的完美格挡机制）
    final blockResult = _combatSystem.evaluateBlock(
      resources: _getPlayerResources(),
      incomingDamage: damage,
      currentTimeMs: _currentTimeMs,
      attackerIsStaggered: _enemyBehavior?.staggerState.isStaggered ?? false,
    );

    if (blockResult.success) {
      if (blockResult.isPerfectBlock) {
        // 完美格挡
        _player = _player.copyWith(isPerfectBlock: true);
        _player = _player.addSwordIntent(15);
        _log('完美格挡！反击伤害 ${blockResult.damageReflected}');
        _enemy = _enemy.takeDamage(blockResult.damageReflected);

        // 完美格挡打断敌人攻击
        if (blockResult.brokeAttacker'sStagger) {
          _log('${_enemy.name} 攻击被打断！');
        }

        _lastPlayerDamage = DamageInfo(
          value: 0,
          isBlocked: true,
          isPerfectBlock: true,
        );
      } else {
        // 普通格挡
        _player = _player.consumeStamina(10);
        _player = _player.takeDamage(blockResult.damageReduced);
        _lastPlayerDamage = DamageInfo(
          value: blockResult.damageReduced,
          isBlocked: true,
        );
      }

      _showDamageNumber(_lastPlayerDamage!, false);

      // 清除完美格挡状态
      Future.delayed(const Duration(milliseconds: 200), () {
        _player = _player.copyWith(isPerfectBlock: false);
        notifyListeners();
      });

      notifyListeners();
      return;
    }

    // 无格挡：使用CombatSystem的护盾优先伤害计算
    final dmgResult = _combatSystem.applyDamageToEntity(
      resources: _getPlayerResources(),
      rawDamage: damage,
      ignoreDefense: ignoreDefense,
      defense: _player.defense,
      isFrozen: _player.isFrozen,
    );

    _player = _player.copyWith(
      currentHp: dmgResult.finalHp,
    );

    _lastPlayerDamage = DamageInfo(
      value: dmgResult.hpLost,
      shieldBroken: dmgResult.wasShieldBroken ? dmgResult.shieldConsumed : 0,
    );

    if (dmgResult.wasShieldBroken) {
      _log('护盾被击碎！');
    }

    _showDamageNumber(_lastPlayerDamage!, false);
    notifyListeners();
  }

  StaminaResources _getPlayerResources() {
    return StaminaResources(
      hp: _player.currentHp,
      maxHp: _player.maxHp,
      stamina: _player.currentStamina,
      maxStamina: _player.maxStamina,
      qi: _player.currentQi,
      maxQi: _player.maxQi,
      shield: 0, // CombatEntity没有shield字段，这里简化
      maxShield: 0,
      isInvincible: _player.isInvincible,
      invincibleUntilMs: _player.isInvincible ? _currentTimeMs + 300 : 0,
      isBlocking: _player.isBlocking,
      lastBlockTimeMs: _currentTimeMs,
    );
  }

  int _getPlayerElementBonus() {
    int bonus = 0;
    for (final status in _player.elementalStatuses) {
      bonus += status.stacks * 10;
    }
    return bonus;
  }

  void _checkElementalReaction(ElementType newElement) {
    for (final existingStatus in _enemy.elementalStatuses) {
      final result = ElementalReactionCalculator.calculateReaction(
        ElementalStatus(element: newElement, stacks: 1),
        existingStatus,
      );

      if (result.$1 != null) {
        final extraDamage = result.$2.round();
        if (extraDamage > 0) {
          _enemy = _enemy.takeDamage(extraDamage, ignoreDefense: true);
          _log('触发${result.$3}反应！额外伤害 $extraDamage');
        }
        _enemy = _enemy.clearElementalStatus(existingStatus.element);
        break;
      }
    }
  }

  bool _randomCrit() => _random.nextDouble() < 0.15;

  void _showDamageNumber(DamageInfo info, bool isEnemy) {
    _damageDisplayTimer?.cancel();
    _damageDisplayTimer = Timer(const Duration(milliseconds: 800), () {
      if (isEnemy) {
        _lastEnemyDamage = null;
      } else {
        _lastPlayerDamage = null;
      }
      notifyListeners();
    });
  }

  void _log(String message) {
    _battleLog.insert(0, message);
    if (_battleLog.length > 50) {
      _battleLog.removeLast();
    }
  }

  // ==================== 敌人攻击（由行为系统触发）====================

  /// 敌人攻击玩家（外部调用/旧版兼容）
  void enemyAttack(int damage) {
    if (_phase != ARPGBattlePhase.combat) return;
    _dealDamageToPlayer(damage);
    notifyListeners();
  }

  // ==================== 辅助方法 ====================

  bool get isVictory => _phase == ARPGBattlePhase.victory;
  bool get isDefeat => _phase == ARPGBattlePhase.defeat;

  /// 获取技能冷却百分比
  double getSkillCooldownPercent(int index) {
    if (index >= _playerSkills.length) return 0;
    return _playerSkills[index].cooldownPercent;
  }

  /// 检查能否使用技能
  bool canUseSkill(int index) {
    if (index >= _playerSkills.length) return false;
    final skill = _playerSkills[index];
    return skill.isReady &&
        _player.currentQi >= skill.qiCost &&
        _player.currentStamina >= skill.staminaCost &&
        _player.currentSwordIntent >= skill.swordIntentCost;
  }

  /// 暂停战斗
  void pauseBattle() {
    if (_phase == ARPGBattlePhase.combat) {
      _phase = ARPGBattlePhase.paused;
      _stopGameLoop();
      notifyListeners();
    }
  }

  /// 继续战斗
  void resumeBattle() {
    if (_phase == ARPGBattlePhase.paused) {
      _phase = ARPGBattlePhase.combat;
      _startGameLoop();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopGameLoop();
    _damageDisplayTimer?.cancel();
    _enemyBehavior?.reset();
    super.dispose();
  }
}

// 随机数生成器
final _random = DateTime.now().millisecondsSinceEpoch;
