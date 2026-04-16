import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../arpg_game.dart';
import '../../domain/combat/combat_system.dart';
import '../../domain/combat/enemy_behavior.dart';
import '../../domain/combat/stamina_system.dart';

/// 敌人类型
enum EnemyType {
  bandit,       // 山贼杂兵
  banditLeader, // 山贼头目
}

/// 敌人实体
class EnemyEntity extends PositionComponent {
  final ArpgGame gameRef;
  final EnemyType enemyType;
  
  // ============ 属性 ============
  int hp = 300;
  int maxHp = 300;
  int attack = 30;
  int defense = 10;
  
  // ============ 战斗资源 ============
  StaminaResources resources = const StaminaResources(
    hp: 300,
    maxHp: 300,
    stamina: 50,
    maxStamina: 50,
    qi: 30,
    maxQi: 30,
  );
  
  // ============ AI行为系统 ============
  EnemyBehavior? behaviorController;
  
  // ============ 状态 ============
  bool isDead = false;
  bool _isAttacking = false;
  double _attackTimer = 0;
  Vector2 _facingDirection = Vector2(-1, 0);
  String _currentAnimation = 'idle';
  
  // ============ 仇恨目标 ============
  String? currentTargetId;
  
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
        hp = maxHp = 300;
        attack = 30;
        defense = 10;
        resources = const StaminaResources(
          hp: 300,
          maxHp: 300,
          stamina: 50,
          maxStamina: 50,
        );
        behaviorController = EnemyBehavior(
          id: 'bandit_${DateTime.now().millisecondsSinceEpoch}',
          attackIntervalMs: 3000,
        );
        break;
        
      case EnemyType.banditLeader:
        hp = maxHp = 1200;
        attack = 60;
        defense = 20;
        resources = const StaminaResources(
          hp: 1200,
          maxHp: 1200,
          stamina: 80,
          maxStamina: 80,
        );
        behaviorController = EnemyBehavior(
          id: 'boss_${DateTime.now().millisecondsSinceEpoch}',
          attackIntervalMs: 2000,
        );
        break;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    // 更新AI行为
    _updateAI(dt);
    
    // 更新攻击状态
    _updateAttackState(dt);
  }
  
  void _updateAI(double dt) {
    if (behaviorController == null) return;
    
    final player = gameRef.player;
    final distToPlayer = (player.position - position).length;
    
    // AI状态机
    final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
    
    // 生成仇恨
    behaviorController!.generateThreat('player', 10, currentTimeMs);
    
    // 更新行为
    final event = behaviorController!.update(
      currentTimeMs,
      _toCombatEntity(),
      player._toCombatEntity(),
      enemyType == EnemyType.banditLeader 
          ? EnemyAttackMode.rush 
          : EnemyAttackMode.rush,
    );
    
    if (event != null) {
      _handleAIEvent(event, player);
    }
    
    // 简单跟随玩家
    if (distToPlayer > 80) {
      final dirToPlayer = (player.position - position)..normalize();
      _facingDirection = dirToPlayer;
      position += dirToPlayer * 1.5 * dt * 60; // 敌人移动速度
      _currentAnimation = 'walk';
    } else {
      _currentAnimation = 'idle';
    }
  }
  
  void _handleAIEvent(AttackEvent event, PlayerCharacter player) {
    switch (event.type) {
      case AttackEventType.attackStart:
        _isAttacking = true;
        _attackTimer = 0.5;
        _currentAnimation = 'attack';
        break;
        
      case AttackEventType.attackHit:
        if (event.damage != null) {
          player.takeDamage(event.damage!, _facingDirection);
        }
        break;
        
      case AttackEventType.attackEnd:
        _isAttacking = false;
        _currentAnimation = 'idle';
        break;
    }
  }
  
  void _updateAttackState(double dt) {
    if (!_isAttacking) return;
    
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _isAttacking = false;
    }
  }
  
  // ============ 受击 ============
  void takeDamage(int damage, Vector2 attackDirection) {
    if (isDead) return;
    
    // 击退效果
    final knockback = attackDirection * 30;
    position += knockback;
    _facingDirection = attackDirection;
    
    // 应用伤害
    hp = (hp - damage).clamp(0, maxHp);
    
    // 硬直效果
    if (behaviorController != null) {
      behaviorController!.applyStagger(damage ~/ 10, DateTime.now().millisecondsSinceEpoch, CombatSystem());
    }
    
    if (hp <= 0) {
      _die();
    }
  }
  
  void _die() {
    isDead = true;
    _currentAnimation = 'death';
    // 延迟移除
    Future.delayed(const Duration(seconds: 2), () {
      removeFromParent();
      gameRef.enemies.remove(this);
    });
  }
  
  // ============ 重置 ============
  void reset() {
    _initByType();
    isDead = false;
    _isAttacking = false;
    _currentAnimation = 'idle';
    behaviorController?.reset();
  }
  
  // 转换为战斗实体（供AI系统使用）
  dynamic _toCombatEntity() {
    return _SimpleCombatEntity(
      hp: hp,
      maxHp: maxHp,
      position: position,
      isAlive: hp > 0,
    );
  }
  
  @override
  void render(Canvas canvas) {
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
    final hpRatio = hp / maxHp;
    final hpBarWidth = size.x;
    final hpBarHeight = 6.0;
    
    // 血条背景
    final bgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(-hpBarWidth / 2, -size.y / 2 - 15, hpBarWidth, hpBarHeight),
      bgPaint,
    );
    
    // 血条前景
    final hpPaint = Paint()..color = const Color(0xFF44FF44);
    canvas.drawRect(
      Rect.fromLTWH(-hpBarWidth / 2, -size.y / 2 - 15, hpBarWidth * hpRatio, hpBarHeight),
      hpPaint,
    );
    
    // 方向指示器
    final dirPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    final dirOffset = _facingDirection * (size.x / 2 - 5);
    canvas.drawCircle(dirOffset.toOffset(), 5, dirPaint);
  }
}

// 简单战斗实体（用于AI系统）
class _SimpleCombatEntity {
  final int hp;
  final int maxHp;
  final Vector2 position;
  final bool isAlive;
  
  _SimpleCombatEntity({
    required this.hp,
    required this.maxHp,
    required this.position,
    required this.isAlive,
  });
}

import 'dart:ui';
import 'package:flutter/material.dart';
