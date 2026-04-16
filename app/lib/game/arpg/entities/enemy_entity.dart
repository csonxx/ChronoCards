import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../arpg_game.dart';
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
        break;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    // 更新AI
    _updateAI(dt);
    
    // 更新攻击状态
    _updateAttackState(dt);
  }
  
  void _updateAI(double dt) {
    final player = gameRef.player;
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
      position += dirToPlayer * 1.5 * dt * 60;
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
  void takeDamage(int damage, Vector2 attackDirection) {
    if (isDead) return;
    
    // 击退效果
    final knockback = attackDirection * 30;
    position += knockback;
    _facingDirection = attackDirection;
    
    // 应用伤害
    final newHp = (combatData.currentHp - damage).clamp(0, combatData.maxHp);
    combatData = combatData.copyWith(currentHp: newHp);
    
    // 硬直效果（受击后短暂眩晕）
    _aiState = EnemyAIState.stunned;
    _attackTimer = 0.3;
    _isAttacking = false;
    
    if (combatData.currentHp <= 0) {
      _die();
    }
  }
  
  void _die() {
    isDead = true;
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
    _aiState = EnemyAIState.idle;
    _attackTimer = 0;
    _attackCooldown = enemyType == EnemyType.banditLeader ? bossAttackInterval : banditAttackInterval;
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
  }
}
