import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../arpg_game.dart';
import '../components/floating_damage_text.dart';
import '../../../domain/combat/combat_system.dart';
import '../../../game/models/combat/combat_entity.dart';

/// 敌人类型
enum EnemyType {
  bandit,       // 山贼杂兵
  banditLeader, // 山贼头目
}

/// 敌人AI状态
enum EnemyAIState {
  idle,
  approaching,
  attacking,
  stunned,
  slow, // 减速状态
}

/// 敌人实体
class EnemyEntity extends PositionComponent {
  final ArpgGame gameRef;
  final EnemyType enemyType;
  
  // ============ 战斗实体数据 ============
  late CombatEntity combatData;
  
  // ============ 状态 ============
  bool isDead = false;
  EnemyAIState _aiState = EnemyAIState.idle;
  bool _isAttacking = false;
  double _attackTimer = 0;
  double _attackCooldown = 0;
  Vector2 _facingDirection = Vector2(-1, 0);
  
  // ============ 减速状态 ============
  double _slowAmount = 0;
  double _slowTimer = 0;
  double _baseMoveSpeed = 1.5;
  
  // ============ 死亡动画 ============
  double _deathTimer = 0;
  static const double deathDuration = 1.5; // 死亡动画持续1.5秒
  bool _isDying = false;
  
  // ============ 击退动画 ============
  Vector2 _knockbackVelocity = Vector2.zero();
  static const double knockbackFriction = 0.9;
  
  // ============ 攻击配置 ============
  static const double banditAttackInterval = 2.0; // 秒
  static const double bossAttackInterval = 1.5; // 秒
  
  EnemyEntity({
    required this.gameRef,
    required this.enemyType,
    Vector2? position,
  }) : super(
    position: position ?? Vector2.zero(),
    size: Vector2(64, 64),
    anchor: Anchor.center,
  ) {
    _initByType();
  }
  
  void _initByType() {
    switch (enemyType) {
      case EnemyType.bandit:
        combatData = CombatEntity(
          id: 'bandit_${DateTime.now().millisecondsSinceEpoch}',
          name: '山贼杂兵',
          level: 1,
          maxHp: 300,
          currentHp: 300,
          maxStamina: 50,
          currentStamina: 50,
          maxQi: 30,
          currentQi: 30,
          attack: 30,
          defense: 10,
        );
        _attackCooldown = banditAttackInterval;
        _baseMoveSpeed = 1.5;
        break;
        
      case EnemyType.banditLeader:
        combatData = CombatEntity(
          id: 'boss_${DateTime.now().millisecondsSinceEpoch}',
          name: '山贼头目',
          level: 5,
          maxHp: 1200,
          currentHp: 1200,
          maxStamina: 80,
          currentStamina: 80,
          maxQi: 60,
          currentQi: 60,
          attack: 60,
          defense: 20,
        );
        _attackCooldown = bossAttackInterval;
        _baseMoveSpeed = 2.0;
        break;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    // 死亡动画中
    if (_isDying) {
      _updateDeathAnimation(dt);
      return;
    }
    
    // 更新减速状态
    _updateSlow(dt);
    
    // 更新击退
    _updateKnockback(dt);
    
    // 更新AI
    _updateAI(dt);
    
    // 更新攻击状态
    _updateAttackState(dt);
  }
  
  void _updateKnockback(double dt) {
    if (_knockbackVelocity.length < 1) return;
    
    position += _knockbackVelocity * dt;
    _knockbackVelocity *= knockbackFriction;
    
    if (_knockbackVelocity.length < 1) {
      _knockbackVelocity = Vector2.zero();
    }
  }
  
  void _updateSlow(double dt) {
    if (_slowTimer > 0) {
      _slowTimer -= dt;
      if (_slowTimer <= 0) {
        _slowAmount = 0;
        _aiState = EnemyAIState.idle;
      }
    }
  }
  
  void _updateDeathAnimation(double dt) {
    _deathTimer += dt;
    
    if (_deathTimer >= deathDuration) {
      // 动画结束，移除
      removeFromParent();
      gameRef.enemies.remove(this);
    }
  }
  
  void _updateAI(double dt) {
    final player = gameRef.player;
    if (player.isInIFrames) {
      // 玩家无敌时不追击
      _aiState = EnemyAIState.idle;
      return;
    }
    
    final distToPlayer = (player.position - position).length;
    
    // 眩晕状态
    if (_aiState == EnemyAIState.stunned) {
      _attackTimer -= dt;
      if (_attackTimer <= 0) {
        _aiState = EnemyAIState.idle;
      }
      return;
    }
    
    // 攻击冷却
    _attackCooldown -= dt;
    
    // 攻击逻辑
    if (distToPlayer < 80 && _attackCooldown <= 0) {
      _startAttack(player);
    } else if (distToPlayer > 100 && !_isAttacking) {
      // 跟随玩家
      _aiState = EnemyAIState.approaching;
      final dirToPlayer = (player.position - position)..normalize();
      _facingDirection = dirToPlayer;
      
      // 考虑减速
      final moveSpeed = _slowAmount > 0 
          ? _baseMoveSpeed * (1 - _slowAmount)
          : _baseMoveSpeed;
      position += dirToPlayer * moveSpeed * dt * 60;
    } else {
      _aiState = EnemyAIState.idle;
    }
  }
  
  void _startAttack(PlayerCharacter player) {
    _isAttacking = true;
    _attackTimer = 0.5; // 攻击前摇
    _aiState = EnemyAIState.attacking;
    
    // 头目使用冲锋技能
    if (enemyType == EnemyType.banditLeader) {
      _attackCooldown = bossAttackInterval;
    } else {
      _attackCooldown = banditAttackInterval;
    }
  }
  
  void _updateAttackState(double dt) {
    if (!_isAttacking) return;
    
    _attackTimer -= dt;
    
    // 在0.3秒时造成伤害（命中帧）
    if (_attackTimer > 0.2 && _attackTimer <= 0.35) {
      final damage = enemyType == EnemyType.banditLeader ? 60 : 30;
      final player = gameRef.player;
      // 检查玩家无敌帧
      if (!player.isInIFrames) {
        player.takeDamage(damage, _facingDirection);
      }
    }
    
    if (_attackTimer <= 0) {
      _isAttacking = false;
      _aiState = EnemyAIState.idle;
    }
  }
  
  // ============ 受击 ============
  /// 普通受击
  void takeDamage(int damage, Vector2 attackDirection, [double knockbackForce = 0, bool isKnockdown = false, bool isStunned = false]) {
    if (isDead || _isDying) return;
    
    // 应用防御减伤
    int actualDamage = (damage - combatData.defense * 0.5).round().clamp(1, damage);
    
    // 击退效果
    if (knockbackForce > 0) {
      final knockDir = attackDirection.clone()..normalize();
      _knockbackVelocity = knockDir * knockbackForce * 10;
      
      // 击倒效果：更大的击退
      if (isKnockdown) {
        _knockbackVelocity *= 1.5;
        _aiState = EnemyAIState.stunned;
        _attackTimer = 0.8; // 击倒眩晕时间
      }
    }
    
    _facingDirection = attackDirection;
    
    // 应用伤害
    final newHp = (combatData.currentHp - actualDamage).clamp(0, combatData.maxHp);
    combatData = combatData.copyWith(currentHp: newHp);
    
    // 显示伤害数字
    _showDamageNumber(actualDamage);
    
    // 硬直效果（受击后短暂眩晕）- 除非已经有更长的眩晕状态
    if (!isKnockdown && !isStunned && _attackTimer <= 0) {
      _aiState = EnemyAIState.stunned;
      _attackTimer = 0.3;
      _isAttacking = false;
    }
    
    // 定身效果（太极剑AOE）
    if (isStunned) {
      _aiState = EnemyAIState.stunned;
      _attackTimer = 0.6; // 定身时间
      _isAttacking = false;
    }
    
    if (combatData.currentHp <= 0) {
      _die();
    }
  }
  
  /// 穿透伤害（无视防御）
  void takePiercingDamage(int damage, Vector2 attackDirection) {
    if (isDead || _isDying) return;
    
    // 穿透：不计算防御
    final newHp = (combatData.currentHp - damage).clamp(0, combatData.maxHp);
    combatData = combatData.copyWith(currentHp: newHp);
    
    // 击退
    final knockDir = attackDirection.clone()..normalize();
    _knockbackVelocity = knockDir * 50;
    _facingDirection = attackDirection;
    
    // 显示伤害数字
    _showDamageNumber(damage, isPiercing: true);
    
    // 眩晕
    _aiState = EnemyAIState.stunned;
    _attackTimer = 0.3;
    _isAttacking = false;
    
    if (combatData.currentHp <= 0) {
      _die();
    }
  }
  
  /// 应用减速效果
  void applySlow(double amount, double duration) {
    _slowAmount = amount;
    _slowTimer = duration;
    _aiState = EnemyAIState.slow;
  }
  
  void _showDamageNumber(int damage, {bool isPiercing = false}) {
    final dmgText = FloatingDamageText(
      position: position.clone()..add(Vector2(0, -30)),
      damage: damage,
    );
    gameRef.add(dmgText);
  }
  
  void _die() {
    isDead = true;
    _isDying = true;
    _deathTimer = 0;
    _knockbackVelocity = Vector2.zero();
    
    // 播放死亡动画期间不处理其他逻辑
    // Future.delayed在update结束后会被调用
  }
  
  // ============ 重置 ============
  void reset() {
    _initByType();
    isDead = false;
    _isDying = false;
    _deathTimer = 0;
    _isAttacking = false;
    _aiState = EnemyAIState.idle;
    _attackTimer = 0;
    _attackCooldown = enemyType == EnemyType.banditLeader ? bossAttackInterval : banditAttackInterval;
    _slowAmount = 0;
    _slowTimer = 0;
    _knockbackVelocity = Vector2.zero();
  }
  
  @override
  void render(Canvas canvas) {
    // 死亡动画：淡出效果
    if (_isDying) {
      final alpha = ((1 - _deathTimer / deathDuration) * 255).clamp(0, 255).toInt();
      final deathPaint = Paint()..color = Color.fromARGB(alpha, 100, 100, 100);
      
      // 淡出的身体
      canvas.drawCircle(Offset.zero, size.x / 2, deathPaint);
      
      // 显示"死亡"文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: '💀',
          style: TextStyle(fontSize: 24, color: Color.fromARGB(alpha, 255, 255, 255)),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      return;
    }
    
    if (isDead) return;
    
    final paint = Paint();
    
    // 根据敌人类型着色
    switch (enemyType) {
      case EnemyType.bandit:
        paint.color = const Color(0xFF8B4513);
        break;
      case EnemyType.banditLeader:
        paint.color = const Color(0xFFDC143C);
        break;
    }
    
    // 绘制身体
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
    
    // 绘制血条
    final hpRatio = combatData.currentHp / combatData.maxHp;
    final hpBarWidth = size.x;
    final hpBarHeight = 6.0;
    
    // 血条背景
    final bgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(-hpBarWidth / 2, -size.y / 2 - 15, hpBarWidth, hpBarHeight),
      bgPaint,
    );
    
    // 血条前景
    final hpColor = hpRatio > 0.5 
        ? const Color(0xFF44FF44) 
        : hpRatio > 0.25 
            ? const Color(0xFFFFFF44) 
            : const Color(0xFFFF4444);
    final hpPaint = Paint()..color = hpColor;
    canvas.drawRect(
      Rect.fromLTWH(-hpBarWidth / 2, -size.y / 2 - 15, hpBarWidth * hpRatio, hpBarHeight),
      hpPaint,
    );
    
    // 方向指示器
    final dirPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    final dirOffset = _facingDirection * (size.x / 2 - 5);
    canvas.drawCircle(Offset(dirOffset.x, dirOffset.y), 5, dirPaint);
    
    // 眩晕状态
    if (_aiState == EnemyAIState.stunned) {
      final stunPaint = Paint()
        ..color = const Color(0x88FFFF00)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, size.x / 2 + 5, stunPaint);
    }
    
    // 减速状态
    if (_slowAmount > 0 && _slowTimer > 0) {
      final slowPaint = Paint()
        ..color = const Color(0x664488FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset.zero, size.x / 2 + 8, slowPaint);
    }
  }
}

/// ARPG技能数据
/// 基于PRD定义的5个门派技能

class SkillData {
  final String name;
  final String description;
  final int damage;
  final double cooldownSec;
  final int qiCost;
  final double range;
  final bool isAoe;
  final String animationName;
  
  const SkillData({
    required this.name,
    required this.description,
    required this.damage,
    required this.cooldownSec,
    required this.qiCost,
    required this.range,
    this.isAoe = false,
    required this.animationName,
  });
  
  // 5个技能配置（基于PRD）
  static const List<SkillData> skills = [
    // K - 少林·金刚拳
    SkillData(
      name: '金刚拳',
      description: '向前冲刺1.5米，施展金刚拳，造成250伤害，最后一击击倒敌人',
      damage: 250,
      cooldownSec: 5,
      qiCost: 20,
      range: 150,
      isAoe: false,
      animationName: 'skill_kung_fu',
    ),
    // L - 武当·太极剑
    SkillData(
      name: '太极剑',
      description: '原地舞剑，形成太极剑气圈，半径2.5米，伤害180×3次',
      damage: 180,
      cooldownSec: 8,
      qiCost: 30,
      range: 200,
      isAoe: true,
      animationName: 'skill_taichi',
    ),
    // U - 峨眉·清风剑
    SkillData(
      name: '清风剑',
      description: '发射一道剑气，直线飞行8米，伤害160，穿透后衰减60%',
      damage: 160,
      cooldownSec: 6,
      qiCost: 25,
      range: 300,
      isAoe: false,
      animationName: 'skill_qingfeng',
    ),
    // I - 华山·破剑式
    SkillData(
      name: '破剑式',
      description: '跃起下刺，伤害400，无视30%防御，落地冲击波额外80伤害',
      damage: 400,
      cooldownSec: 10,
      qiCost: 35,
      range: 150,
      isAoe: false,
      animationName: 'skill_pojian',
    ),
    // O - 丐帮·打狗棒
    SkillData(
      name: '打狗棒',
      description: '棒扫180°，半径2米，伤害130×2次，被击中敌人减速40%持续2秒',
      damage: 130,
      cooldownSec: 7,
      qiCost: 25,
      range: 180,
      isAoe: true,
      animationName: 'skill_dagou',
    ),
  ];
  
  // 普攻连击数据
  static const List<int> comboDamages = [100, 120, 150];
  static const List<double> comboMultipliers = [1.0, 1.2, 1.5];
  
  // 角色基础属性（基于PRD）
  static const int baseHp = 1000;
  static const int baseAttack = 100;
  static const int baseDefense = 20;
  static const int baseQi = 100;
  static const double baseMoveSpeed = 3.5; // m/s
}
