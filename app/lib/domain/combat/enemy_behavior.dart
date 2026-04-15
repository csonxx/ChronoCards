import 'dart:math';
import '../../game/models/combat/combat_entity.dart';
import 'combat_system.dart';

/// 敌人攻击模式
enum EnemyAttackMode {
  rush,   // 突进：3连击，低伤害
  heavy,  // 重击：高伤害，低频率
  area,   // 范围：AOE攻击
}

/// 仇恨目标
class AggroTarget {
  final String entityId;
  final int aggroValue; // 仇恨值
  final int lastThreatTimeMs;

  const AggroTarget({
    required this.entityId,
    required this.aggroValue,
    required this.lastThreatTimeMs,
  });

  AggroTarget addThreat(int amount, int currentTimeMs) {
    return AggroTarget(
      entityId: entityId,
      aggroValue: aggroValue + amount,
      lastThreatTimeMs: currentTimeMs,
    );
  }

  AggroTarget decay(int decayRate, int currentTimeMs) {
    // 仇恨每分钟衰减约10%
    final secondsSinceLastThreat = (currentTimeMs - lastThreatTimeMs) / 1000;
    final decayed = (aggroValue * (1 - decayRate * secondsSinceLastThreat / 60)).round();
    return AggroTarget(
      entityId: entityId,
      aggroValue: decayed.clamp(0, 999999),
      lastThreatTimeMs: lastThreatTimeMs,
    );
  }

  AggroTarget copyWith({int? aggroValue, int? lastThreatTimeMs}) {
    return AggroTarget(
      entityId: entityId,
      aggroValue: aggroValue ?? this.aggroValue,
      lastThreatTimeMs: lastThreatTimeMs ?? this.lastThreatTimeMs,
    );
  }
}

/// 仇恨系统
class AggroSystem {
  final Map<String, AggroTarget> _aggroTable = {};
  String? _currentTargetId;
  final int maxAggroPerTarget; // 单目标最大仇恨
  final int aggroDecayRate;    // 衰减速率（每分钟%）

  AggroSystem({
    this.maxAggroPerTarget = 10000,
    this.aggroDecayRate = 10,
  });

  String? get currentTargetId => _currentTargetId;

  /// 增加仇恨
  void addThreat(String attackerId, int amount, int currentTimeMs) {
    if (_aggroTable.containsKey(attackerId)) {
      _aggroTable[attackerId] = _aggroTable[attackerId]!.addThreat(amount, currentTimeMs);
    } else {
      _aggroTable[attackerId] = AggroTarget(
        entityId: attackerId,
        aggroValue: amount,
        lastThreatTimeMs: currentTimeMs,
      );
    }
    _currentTargetId = _getHighestAggroTarget();
  }

  /// 仇恨衰减
  void decayAll(int currentTimeMs) {
    for (final entry in _aggroTable.entries.toList()) {
      _aggroTable[entry.key] = entry.value.decay(aggroDecayRate, currentTimeMs);
    }
  }

  /// 获取仇恨最高的Target
  String? _getHighestAggroTarget() {
    if (_aggroTable.isEmpty) return null;
    String? highestId;
    int highestValue = -1;
    for (final entry in _aggroTable.entries) {
      if (entry.value.aggroValue > highestValue) {
        highestValue = entry.value.aggroValue;
        highestId = entry.key;
      }
    }
    return highestId;
  }

  /// 检查某实体是否是当前仇恨目标
  bool isTarget(String entityId) => _currentTargetId == entityId;

  /// 清除仇恨
  void clear() {
    _aggroTable.clear();
    _currentTargetId = null;
  }

  /// 获取所有仇恨列表（排序）
  List<AggroTarget> get sortedAggroList {
    final list = _aggroTable.values.toList();
    list.sort((a, b) => b.aggroValue.compareTo(a.aggroValue));
    return list;
  }
}

/// 敌人行为状态
enum EnemyBehaviorState {
  idle,
  approaching,
  attacking,
  retreating,
  stunned,
  guarding,
  enraged,
}

/// 单次攻击动作
class AttackAction {
  final String id;
  final String name;
  final EnemyAttackMode mode;
  final int baseDamage;
  final int staggerValue; // 对目标的硬直值
  final int windupMs;     // 前摇时间
  final int activeMs;     // 命中判定时间
  final int recoveryMs;   // 收招硬直
  final int aggroGenerated; // 产生的仇恨值
  final bool isRanged;

  const AttackAction({
    required this.id,
    required this.name,
    required this.mode,
    required this.baseDamage,
    this.staggerValue = 10,
    this.windupMs = 400,
    this.activeMs = 200,
    this.recoveryMs = 300,
    this.aggroGenerated = 50,
    this.isRanged = false,
  });

  int get totalDurationMs => windupMs + activeMs + recoveryMs;
}

/// 敌人行为控制器 - 包含攻击间隔、攻击模式、仇恨系统
class EnemyBehavior {
  final String id;

  // 攻击间隔参数
  static const int baseAttackIntervalMs = 3000;
  final int attackIntervalMs;
  int _nextAttackTimeMs = 0;
  bool _attackInProgress = false;
  int _attackPhaseStartMs = 0; // 当前攻击阶段的开始时间

  // 攻击阶段
  AttackPhase _currentPhase = AttackPhase.none;
  AttackAction? _currentAction;

  // 仇恨系统
  final AggroSystem aggroSystem;

  // 状态
  EnemyBehaviorState _state = EnemyBehaviorState.idle;
  EnemyBehaviorState get state => _state;

  // 硬直状态
  StaggerState _staggerState = const StaggerState();
  StaggerState get staggerState => _staggerState;

  // 仇恨衰减定时器（每10秒衰减一次）
  int _lastAggroDecayMs = 0;

  final Random _random = Random();

  EnemyBehavior({
    required this.id,
    int? attackIntervalMs,
    AggroSystem? aggroSystem,
  })  : attackIntervalMs = attackIntervalMs ?? baseAttackIntervalMs,
        aggroSystem = aggroSystem ?? AggroSystem() {
    _nextAttackTimeMs = DateTime.now().millisecondsSinceEpoch + this.attackIntervalMs;
  }

  /// 预设的攻击动作库
  static List<AttackAction> get rushAttacks => [
    const AttackAction(
      id: 'rush_1',
      name: '突刺',
      mode: EnemyAttackMode.rush,
      baseDamage: 20,
      staggerValue: 5,
      windupMs: 250,
      activeMs: 150,
      recoveryMs: 200,
      aggroGenerated: 30,
    ),
    const AttackAction(
      id: 'rush_2',
      name: '横斩',
      mode: EnemyAttackMode.rush,
      baseDamage: 25,
      staggerValue: 8,
      windupMs: 300,
      activeMs: 150,
      recoveryMs: 250,
      aggroGenerated: 35,
    ),
    const AttackAction(
      id: 'rush_3',
      name: '下劈',
      mode: EnemyAttackMode.rush,
      baseDamage: 35,
      staggerValue: 12,
      windupMs: 350,
      activeMs: 200,
      recoveryMs: 350,
      aggroGenerated: 50,
    ),
  ];

  static List<AttackAction> get heavyAttacks => [
    const AttackAction(
      id: 'heavy_smash',
      name: '重锤',
      mode: EnemyAttackMode.heavy,
      baseDamage: 80,
      staggerValue: 30,
      windupMs: 600,
      activeMs: 300,
      recoveryMs: 600,
      aggroGenerated: 100,
    ),
  ];

  static List<AttackAction> get areaAttacks => [
    const AttackAction(
      id: 'area_slam',
      name: '震地',
      mode: EnemyAttackMode.area,
      baseDamage: 50,
      staggerValue: 20,
      windupMs: 500,
      activeMs: 400,
      recoveryMs: 500,
      aggroGenerated: 80,
      isRanged: false,
    ),
    const AttackAction(
      id: 'area_spin',
      name: '旋风斩',
      mode: EnemyAttackMode.area,
      baseDamage: 40,
      staggerValue: 15,
      windupMs: 400,
      activeMs: 500,
      recoveryMs: 400,
      aggroGenerated: 70,
    ),
  ];

  /// 选择下一个攻击动作（基于模式和随机）
  AttackAction chooseNextAttack(EnemyAttackMode mode) {
    switch (mode) {
      case EnemyAttackMode.rush:
        return rushAttacks[_random.nextInt(rushAttacks.length)];
      case EnemyAttackMode.heavy:
        return heavyAttacks[_random.nextInt(heavyAttacks.length)];
      case EnemyAttackMode.area:
        return areaAttacks[_random.nextInt(areaAttacks.length)];
    }
  }

  /// 更新敌人行为（每帧调用）
  /// 返回：null = 无动作，AttackStart = 开始攻击，AttackHit = 命中帧，AttackEnd = 攻击结束
  AttackEvent? update(
    int currentTimeMs,
    CombatEntity self,
    CombatEntity player,
    EnemyAttackMode preferredMode,
  ) {
    // 更新仇恨衰减
    if (currentTimeMs - _lastAggroDecayMs > 10000) {
      aggroSystem.decayAll(currentTimeMs);
      _lastAggroDecayMs = currentTimeMs;
    }

    // 更新硬直状态
    _staggerState = _staggerState.update(currentTimeMs);
    if (_staggerState.isStaggered) {
      _state = EnemyBehaviorState.stunned;
      return null;
    }

    // 攻击中状态机
    if (_attackInProgress) {
      return _updateAttackProgress(currentTimeMs);
    }

    // 检查是否应该开始攻击
    if (currentTimeMs >= _nextAttackTimeMs) {
      _startAttack(chooseNextAttack(preferredMode), currentTimeMs);
      return AttackEvent(type: AttackEventType.attackStart, action: _currentAction);
    }

    // 目标距离判断（简化为ai自己判断）
    _state = EnemyBehaviorState.idle;
    return null;
  }

  /// 对目标造成仇恨
  void generateThreat(String targetId, int amount, int currentTimeMs) {
    aggroSystem.addThreat(targetId, amount, currentTimeMs);
  }

  AttackEvent? _updateAttackProgress(int currentTimeMs) {
    final elapsed = currentTimeMs - _attackPhaseStartMs;

    if (elapsed < _currentAction!.windupMs) {
      // 前摇阶段
      return null;
    } else if (elapsed < _currentAction!.windupMs + _currentAction!.activeMs) {
      // 命中帧
      return AttackEvent(
        type: AttackEventType.attackHit,
        action: _currentAction,
        damage: _currentAction!.baseDamage,
      );
    } else if (elapsed < _currentAction!.totalDurationMs) {
      // 收招阶段
      return null;
    } else {
      // 攻击结束
      _attackInProgress = false;
      _currentPhase = AttackPhase.none;
      _currentAction = null;
      _nextAttackTimeMs = currentTimeMs + attackIntervalMs;
      _state = EnemyBehaviorState.idle;
      return AttackEvent(type: AttackEventType.attackEnd);
    }
  }

  void _startAttack(AttackAction action, int currentTimeMs) {
    _currentAction = action;
    _attackInProgress = true;
    _attackPhaseStartMs = currentTimeMs;
    _currentPhase = AttackPhase.windup;
    _state = EnemyBehaviorState.attacking;
  }

  /// 对敌人造成硬直
  void applyStagger(int staggerValue, int currentTimeMs, CombatSystem combatSystem) {
    if (staggerValue >= _getEffectiveStaggerThreshold()) {
      _staggerState = _staggerState.applyStagger(currentTimeMs);
      _attackInProgress = false; // 硬直打断攻击
      _currentAction = null;
      _state = EnemyBehaviorState.stunned;
    }
  }

  int _getEffectiveStaggerThreshold() {
    // 狂暴时硬直阈值提高
    if (_state == EnemyBehaviorState.enraged) {
      return 20;
    }
    return 10;
  }

  /// 获取当前攻击的伤害（如果正在攻击中）
  int? get currentAttackDamage {
    if (!_attackInProgress || _currentAction == null) return null;
    return _currentAction!.baseDamage;
  }

  /// 检查是否在攻击的前摇/收招阶段
  bool get isInRecoveryPhase {
    if (!_attackInProgress || _currentAction == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _attackPhaseStartMs;
    return elapsed >= _currentAction!.windupMs + _currentAction!.activeMs;
  }

  void reset() {
    _attackInProgress = false;
    _currentAction = null;
    _currentPhase = AttackPhase.none;
    _state = EnemyBehaviorState.idle;
    _staggerState = const StaggerState();
    aggroSystem.clear();
    _nextAttackTimeMs = DateTime.now().millisecondsSinceEpoch + attackIntervalMs;
  }
}

/// 攻击阶段
enum AttackPhase { none, windup, active, recovery }

/// 攻击事件类型
enum AttackEventType { attackStart, attackHit, attackEnd }

/// 攻击事件
class AttackEvent {
  final AttackEventType type;
  final AttackAction? action;
  final int? damage;

  const AttackEvent({
    required this.type,
    this.action,
    this.damage,
  });
}

/// 敌人行为预设配置
class EnemyBehaviorConfig {
  final String id;
  final String name;
  final EnemyAttackMode attackMode;
  final int attackIntervalMs;
  final int aggroDecayRate;
  final int maxAggroPerTarget;

  const EnemyBehaviorConfig({
    required this.id,
    required this.name,
    this.attackMode = EnemyAttackMode.rush,
    this.attackIntervalMs = 3000,
    this.aggroDecayRate = 10,
    this.maxAggroPerTarget = 10000,
  });

  EnemyBehavior create() {
    return EnemyBehavior(
      id: id,
      attackIntervalMs: attackIntervalMs,
      aggroSystem: AggroSystem(
        aggroDecayRate: aggroDecayRate,
        maxAggroPerTarget: maxAggroPerTarget,
      ),
    );
  }

  static const EnemyBehaviorConfig mingjiaoDisciple = EnemyBehaviorConfig(
    id: 'mingjiao_disciple',
    name: '明教弟子',
    attackMode: EnemyAttackMode.rush,
    attackIntervalMs: 2500,
  );

  static const EnemyBehaviorConfig shaolinMonk = EnemyBehaviorConfig(
    id: 'shaolin_monk',
    name: '少林武僧',
    attackMode: EnemyAttackMode.heavy,
    attackIntervalMs: 4000,
  );

  static const EnemyBehaviorConfig wudangSword = EnemyBehaviorConfig(
    id: 'wudang_sword',
    name: '武当剑客',
    attackMode: EnemyAttackMode.area,
    attackIntervalMs: 3500,
  );

  static const EnemyBehaviorConfig tianmoBoss = EnemyBehaviorConfig(
    id: 'boss_tianmo',
    name: '天魔',
    attackMode: EnemyAttackMode.rush,
    attackIntervalMs: 2000,
    aggroDecayRate: 5,
    maxAggroPerTarget: 15000,
  );
}
