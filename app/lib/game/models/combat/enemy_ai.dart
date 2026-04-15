import 'dart:math';
import 'combat_entity.dart';
import 'skill.dart';
import 'elemental_system.dart';

/// 敌人AI行为状态
enum EnemyAIState {
  idle,           // 待机
  approaching,    // 接近玩家
  attacking,      // 攻击中
  retreating,     // 撤退
  stunned,        // 眩晕
  defensive,      // 防御姿态
  enraged,        // 狂暴化
}

/// 敌人攻击模式
enum EnemyAttackPattern {
  rush,           // rush攻击：快速连击
  heavy,          // 重击：低频高伤
  balanced,       // 平衡：中等频率和伤害
  projectile,     // 远程：投射物攻击
  combo,          // 组合：混合多种攻击
}

/// 敌人AI控制器 - 复杂行为模式（非站桩）
class EnemyAI {
  final String id;
  final String name;
  final int level;
  final EnemyAttackPattern attackPattern;
  final List<Skill> skills;
  
  // AI参数
  final double aggression;      // 攻击性 (0-1)
  final double reactiveness;    // 反应速度 (0-1)
  final double defensiveness;   // 防御倾向 (0-1)
  
  // 状态机
  EnemyAIState _currentState = EnemyAIState.idle;
  EnemyAIState get currentState => _currentState;
  
  // 内部状态
  int _comboCount = 0;
  double _stateTimer = 0;
  double _attackCooldown = 0;
  bool _isEnraged = false;
  double _enrageThreshold; // 血量阈值触发狂暴
  
  // 位置相关
  double _distanceToPlayer = 200; // 初始距离
  double get distanceToPlayer => _distanceToPlayer;
  
  // 攻击队列
  List<Skill> _attackQueue = [];
  
  // 随机数生成器
  final Random _random = Random();
  
  EnemyAI({
    required this.id,
    required this.name,
    this.level = 1,
    this.attackPattern = EnemyAttackPattern.balanced,
    this.skills = const [],
    this.aggression = 0.5,
    this.reactiveness = 0.5,
    this.defensiveness = 0.3,
    this.enrageThreshold = 0.3,
  }) {
    _initSkills();
  }
  
  void _initSkills() {
    // 根据攻击模式初始化技能
  }

  /// 更新AI状态
  void update(double deltaTime, CombatEntity self, CombatEntity player) {
    _stateTimer += deltaTime;
    _attackCooldown = (_attackCooldown - deltaTime).clamp(0, 10);
    
    // 更新与玩家距离（模拟）
    _distanceToPlayer = _calculateDistance(self, player);
    
    // 检查狂暴状态
    if (!_isEnraged && self.hpPercent <= enrageThreshold) {
      _triggerEnrage();
    }
    
    // 状态机更新
    switch (_currentState) {
      case EnemyAIState.idle:
        _updateIdle(deltaTime, self, player);
        break;
      case EnemyAIState.approaching:
        _updateApproaching(deltaTime, self, player);
        break;
      case EnemyAIState.attacking:
        _updateAttacking(deltaTime, self, player);
        break;
      case EnemyAIState.retreating:
        _updateRetreating(deltaTime, self, player);
        break;
      case EnemyAIState.stunned:
        _updateStunned(deltaTime, self);
        break;
      case EnemyAIState.defensive:
        _updateDefensive(deltaTime, self, player);
        break;
      case EnemyAIState.enraged:
        _updateEnraged(deltaTime, self, player);
        break;
    }
  }

  /// 待机状态更新
  void _updateIdle(double deltaTime, CombatEntity self, CombatEntity player) {
    if (self.isStunned) {
      _currentState = EnemyAIState.stunned;
      _stateTimer = 0;
      return;
    }
    
    // 检测到玩家，评估是否接近
    if (_distanceToPlayer > 150) {
      // 概率决定是否接近
      if (_random.nextDouble() < aggression) {
        _currentState = EnemyAIState.approaching;
        _stateTimer = 0;
      }
    } else if (_distanceToPlayer < 100) {
      // 太近了，可能撤退或攻击
      if (_random.nextDouble() < defensiveness) {
        _currentState = EnemyAIState.retreating;
      } else {
        _startAttackPattern();
      }
    } else {
      // 中距离，直接进入攻击
      _startAttackPattern();
    }
  }

  /// 接近状态更新
  void _updateApproaching(double deltaTime, CombatEntity self, CombatEntity player) {
    // 检查是否到达攻击距离
    if (_distanceToPlayer <= 100) {
      _currentState = EnemyAIState.attacking;
      _stateTimer = 0;
      _startAttackPattern();
      return;
    }
    
    // 检查是否需要停止接近
    if (_shouldDodge(player)) {
      _currentState = EnemyAIState.retreating;
      _stateTimer = 0;
    }
  }

  /// 攻击状态更新
  void _updateAttacking(double deltaTime, CombatEntity self, CombatEntity player) {
    if (_attackQueue.isEmpty) {
      // 攻击完成，判断下一步
      _decideNextState(self, player);
      return;
    }
    
    // 执行攻击队列
    if (_attackCooldown <= 0) {
      final skill = _attackQueue.removeAt(0);
      _attackCooldown = _calculateAttackCooldown(skill);
    }
  }

  /// 撤退状态更新
  void _updateRetreating(double deltaTime, CombatEntity self, CombatEntity player) {
    if (_distanceToPlayer > 200) {
      // 撤退完成，恢复idle
      _currentState = EnemyAIState.idle;
      _stateTimer = 0;
      return;
    }
    
    // 低血量时更倾向于保持距离
    if (self.isLowHp && _random.nextDouble() < 0.3) {
      _currentState = EnemyAIState.defensive;
      _stateTimer = 0;
    }
  }

  /// 眩晕状态更新
  void _updateStunned(double deltaTime, CombatEntity self) {
    if (_stateTimer >= 1.5) { // 眩晕持续1.5秒
      _currentState = EnemyAIState.idle;
      _stateTimer = 0;
    }
  }

  /// 防御状态更新
  void _updateDefensive(double deltaTime, CombatEntity self, CombatEntity player) {
    // 防御姿态：等待时机反击
    if (_stateTimer >= 2.0) {
      // 恢复攻击
      if (_distanceToPlayer <= 120) {
        _startAttackPattern();
      } else {
        _currentState = EnemyAIState.approaching;
      }
      _stateTimer = 0;
    }
    
    // 检测玩家攻击，准备格挡
    if (_shouldBlock(player) && self.canBlock) {
      // 完美格挡判定
      _attemptPerfectBlock();
    }
  }

  /// 狂暴状态更新
  void _updateEnraged(double deltaTime, CombatEntity self, CombatEntity player) {
    // 狂暴状态：攻击性大幅提升
    _aggression = (_aggression + 0.3).clamp(0, 1);
    _attackCooldown = (_attackCooldown * 0.7).clamp(0, 10);
    
    // 更积极地接近
    if (_distanceToPlayer > 80) {
      _currentState = EnemyAIState.approaching;
    } else {
      _startAttackPattern();
    }
  }

  /// 检测是否需要闪避
  bool _shouldDodge(CombatEntity player) {
    // 检测玩家是否有攻击前摇
    if (player.isAttacking && _random.nextDouble() < reactiveness) {
      return true;
    }
    return false;
  }

  /// 检测是否需要格挡
  bool _shouldBlock(CombatEntity player) {
    if (player.isAttacking && _random.nextDouble() < defensiveness * 1.5) {
      return true;
    }
    return false;
  }

  /// 尝试完美格挡
  void _attemptPerfectBlock() {
    // 完美格挡成功率基于反应速度
    if (_random.nextDouble() < reactiveness * 0.5) {
      // 触发完美格挡
    }
  }

  /// 开始攻击模式
  void _startAttackPattern() {
    _currentState = EnemyAIState.attacking;
    _stateTimer = 0;
    _comboCount = 0;
    
    switch (attackPattern) {
      case EnemyAttackPattern.rush:
        _attackQueue = List.generate(4, (_) => _getLightAttack());
        break;
      case EnemyAttackPattern.heavy:
        _attackQueue = [_getHeavyAttack()];
        break;
      case EnemyAttackPattern.balanced:
        _attackQueue = [_getLightAttack(), _getLightAttack(), _getHeavyAttack()];
        break;
      case EnemyAttackPattern.projectile:
        _attackQueue = [_getProjectileAttack()];
        break;
      case EnemyAttackPattern.combo:
        _attackQueue = _generateComboAttack();
        break;
    }
  }

  List<Skill> _generateComboAttack() {
    final attacks = <Skill>[];
    int count = 2 + _random.nextInt(3);
    
    for (int i = 0; i < count; i++) {
      if (_random.nextDouble() < 0.7) {
        attacks.add(_getLightAttack());
      } else {
        attacks.add(_getHeavyAttack());
      }
    }
    
    return attacks;
  }

  Skill _getLightAttack() => const Skill(
    id: 'enemy_light',
    name: '突刺',
    type: SkillType.lightAttack,
    baseDamage: 25,
    cooldown: 0.5,
  );

  Skill _getHeavyAttack() => const Skill(
    id: 'enemy_heavy',
    name: '重击',
    type: SkillType.heavyAttack,
    baseDamage: 60,
    cooldown: 1.2,
  );

  Skill _getProjectileAttack() => const Skill(
    id: 'enemy_projectile',
    name: '暗器',
    type: SkillType.E,
    baseDamage: 40,
    cooldown: 2.0,
    isRanged: true,
  );

  double _calculateAttackCooldown(Skill skill) {
    double cooldown = skill.cooldown;
    if (_isEnraged) {
      cooldown *= 0.7;
    }
    return cooldown.clamp(0.3, 3.0);
  }

  double _calculateDistance(CombatEntity self, CombatEntity player) {
    // 简化的距离计算
    return _distanceToPlayer;
  }

  void _decideNextState(CombatEntity self, CombatEntity player) {
    _currentState = EnemyAIState.idle;
    _stateTimer = 0;
    
    // 血量低时更倾向于撤退
    if (self.isLowHp) {
      if (_random.nextDouble() < 0.5) {
        _currentState = EnemyAIState.retreating;
      } else if (_random.nextDouble() < defensiveness) {
        _currentState = EnemyAIState.defensive;
      }
    }
  }

  void _triggerEnrage() {
    _isEnraged = true;
    _currentState = EnemyAIState.enraged;
    _stateTimer = 0;
  }

  /// 获取AI决策信息（用于调试/显示）
  Map<String, dynamic> getAIState() {
    return {
      'state': _currentState.name,
      'isEnraged': _isEnraged,
      'comboCount': _comboCount,
      'attackQueueLength': _attackQueue.length,
      'distanceToPlayer': _distanceToPlayer,
    };
  }
}

/// 预设敌人AI配置
class EnemyAIConfig {
  static EnemyAI create(String enemyType, {int level = 1}) {
    switch (enemyType) {
      case 'mingjiao_disciple':
        return EnemyAI(
          id: 'mingjiao_disciple',
          name: '明教弟子',
          level: level,
          attackPattern: EnemyAttackPattern.rush,
          aggression: 0.7,
          reactiveness: 0.5,
          defensiveness: 0.2,
        );
      case 'shaolin_monk':
        return EnemyAI(
          id: 'shaolin_monk',
          name: '少林武僧',
          level: level,
          attackPattern: EnemyAttackPattern.balanced,
          aggression: 0.5,
          reactiveness: 0.6,
          defensiveness: 0.5,
        );
      case 'emei_nun':
        return EnemyAI(
          id: 'emei_nun',
          name: '峨眉师姐',
          level: level,
          attackPattern: EnemyAttackPattern.projectile,
          aggression: 0.4,
          reactiveness: 0.7,
          defensiveness: 0.4,
        );
      case 'boss_tian魔':
        return EnemyAI(
          id: 'boss_tianmo',
          name: '天魔',
          level: level,
          attackPattern: EnemyAttackPattern.combo,
          aggression: 0.9,
          reactiveness: 0.8,
          defensiveness: 0.3,
          enrageThreshold: 0.5,
        );
      default:
        return EnemyAI(
          id: 'bandit',
          name: '山贼',
          level: level,
          attackPattern: EnemyAttackPattern.balanced,
          aggression: 0.5,
          reactiveness: 0.4,
          defensiveness: 0.3,
        );
    }
  }
}
