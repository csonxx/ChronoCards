import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/combat/combat_entity.dart';
import '../models/combat/skill.dart';
import '../models/combat/elemental_system.dart';
import '../models/combat/enemy_ai.dart';

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
  final ElementalReactionType? reaction;
  final String? reactionName;

  const DamageInfo({
    required this.value,
    this.isCrit = false,
    this.isBlocked = false,
    this.isPerfectBlock = false,
    this.isDodged = false,
    this.reaction,
    this.reactionName,
  });
}

/// ARPG战斗Provider - 基于Provider/ChangeNotifier架构（非BLoC）
/// 全功能Phase 1: 三资源系统 + 连击 + 技能 + 闪避无敌帧 + 格挡反击 + 复杂AI
class ARPGBattleProvider extends ChangeNotifier {
  // 战斗阶段
  ARPGBattlePhase _phase = ARPGBattlePhase.intro;
  ARPGBattlePhase get phase => _phase;

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

  // 敌人AI
  EnemyAI? _enemyAI;

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
  double _lastUpdateTime = 0;

  // 伤害数字显示定时器
  Timer? _damageDisplayTimer;

  // 常量
  static const double _invincibleDuration = 0.4; // 闪避无敌帧秒数
  static const double _staminaRecoveryPerSec = 8.0;
  static const double _qiRecoveryPerSec = 5.0;

  /// 开始战斗
  void startBattle({String enemyType = 'mingjiao_disciple', int enemyLevel = 12}) {
    _phase = ARPGBattlePhase.intro;
    _elapsedTime = 0;
    _lastUpdateTime = 0;
    _comboStage = 1;
    _isAttacking = false;
    _lastPlayerDamage = null;
    _lastEnemyDamage = null;
    _battleLog.clear();

    // 初始化敌人AI
    _enemyAI = EnemyAIConfig.create(enemyType, level: enemyLevel);

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

    // 更新技能冷却
    _playerSkills = _playerSkills.map((s) => s.tickCooldown(deltaTime)).toList();

    // 恢复资源
    _recoverResources(deltaTime);

    // 更新元素状态持续时间
    _updateElementalStatuses(deltaTime);

    // 更新敌人AI
    _enemyAI?.update(deltaTime, _enemy, _player);

    // 敌人自动攻击
    _processEnemyAttack(deltaTime);

    // 检查战斗结束
    _checkBattleEnd();

    notifyListeners();
  }

  void _recoverResources(double deltaTime) {
    // 恢复体力
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

  void _processEnemyAttack(double deltaTime) {
    // 敌人AI决定攻击（简化版）
    // 实际项目中敌人攻击会通过事件触发
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

    _isAttacking = true;
    
    // 计算伤害
    final baseDamage = _player.attack;
    final multiplier = 0.4; // 轻攻击倍率
    final damage = (baseDamage * multiplier).round();
    final isCrit = _randomCrit();

    // 造成伤害
    _dealDamageToEnemy(damage, isCrit);

    // 消耗精力
    _player = _player.consumeStamina(5);

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

    _isAttacking = true;
    
    final baseDamage = _player.attack;
    final multiplier = 1.0; // 重攻击倍率
    final damage = (baseDamage * multiplier).round();
    final isCrit = _randomCrit();

    _dealDamageToEnemy(damage, isCrit);

    // 重攻击消耗更多体力
    _player = _player.consumeStamina(12);

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

  /// 闪避
  void dodge() {
    if (_phase != ARPGBattlePhase.combat) return;
    if (_player.currentStamina < 15) return;
    if (_player.isInvincible) return;

    _player = _player.consumeStamina(15);
    _player = _player.copyWith(isInvincible: true);

    // 闪避中无敌
    _log('${_player.name} 闪避！');

    Future.delayed(const Duration(milliseconds: (_invincibleDuration * 1000).round()), () {
      _player = _player.copyWith(isInvincible: false);
      notifyListeners();
    });

    // 闪避增加少量剑意
    _player = _player.addSwordIntent(2);

    notifyListeners();
  }

  /// 开始格挡（长按）
  void startBlock() {
    if (_phase != ARPGBattlePhase.combat) return;
    if (_player.currentStamina < 15) return;

    _player = _player.copyWith(isBlocking: true);
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
    final baseDamage = _player.attack;
    final damage = (baseDamage * skill.damageMultiplier + skill.baseDamage).round();
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
      _player = _player.copyWith(isInvincible: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        _player = _player.copyWith(isInvincible: false);
        notifyListeners();
      });
    }

    // 剑意积累
    _player = _player.addSwordIntent(skill.type == SkillType.Q ? 20 : 10);

    _log('${_player.name} 使用 ${skill.name}！${isCrit ? "暴击！" : ""}');

    notifyListeners();
  }

  void _dealDamageToEnemy(int damage, bool isCrit) {
    // 计算元素加成
    int elementalBonus = 0;
    for (final status in _player.elementalStatuses) {
      elementalBonus += status.stacks * 10;
    }

    final finalDamage = damage + elementalBonus;

    // 应用防御
    int actualDamage = (finalDamage - _enemy.defense * 0.3).round();
    actualDamage = actualDamage.clamp(1, finalDamage * 2);

    _enemy = _enemy.takeDamage(actualDamage);
    _lastEnemyDamage = DamageInfo(value: actualDamage, isCrit: isCrit);

    // 显示伤害数字
    _showDamageNumber(_lastEnemyDamage!, true);

    // 检查元素反应
    for (final status in _enemy.elementalStatuses) {
      if (status.duration > 0) {
        // 先清除旧状态
        _enemy = _enemy.clearElementalStatus(status.element);
        break;
      }
    }
  }

  void _dealDamageToPlayer(int damage, {bool ignoreDefense = false}) {
    if (_player.isInvincible) {
      _lastPlayerDamage = const DamageInfo(value: 0, isDodged: true);
      _showDamageNumber(_lastPlayerDamage!, false);
      return;
    }

    int actualDamage = damage;

    if (_player.isBlocking) {
      // 格挡减伤
      actualDamage = (actualDamage * 0.3).round();
      
      // 完美格挡判定
      if (_player.isPerfectBlock || _random.nextDouble() < 0.3) {
        actualDamage = 0;
        _player = _player.copyWith(isPerfectBlock: true);
        _player = _player.addSwordIntent(15);
        _log('完美格挡！');
      } else {
        _player = _player.consumeStamina(10);
      }
    }

    _player = _player.takeDamage(actualDamage);
    _lastPlayerDamage = DamageInfo(
      value: actualDamage,
      isBlocked: _player.isBlocking,
      isPerfectBlock: _player.isPerfectBlock,
    );

    _showDamageNumber(_lastPlayerDamage!, false);

    // 清除完美格挡状态
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_player.isPerfectBlock) {
        _player = _player.copyWith(isPerfectBlock: false);
        notifyListeners();
      }
    });
  }

  void _checkElementalReaction(ElementType newElement) {
    // 检查敌人身上是否有可以反应的元素
    for (final existingStatus in _enemy.elementalStatuses) {
      final result = ElementalReactionCalculator.calculateReaction(
        ElementalStatus(element: newElement, stacks: 1),
        existingStatus,
      );

      if (result.$1 != null) {
        // 触发反应，造成额外伤害
        final extraDamage = result.$2.round();
        if (extraDamage > 0) {
          _enemy = _enemy.takeDamage(extraDamage, ignoreDefense: true);
          _log('触发${result.$3}反应！额外伤害 $extraDamage');
        }

        // 清除被反应的元素
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

  // ==================== 敌人攻击（由AI或定时触发）====================

  /// 敌人攻击玩家（外部调用）
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
    super.dispose();
  }
}

// 随机数生成器
final _random = DateTime.now().millisecondsSinceEpoch;
