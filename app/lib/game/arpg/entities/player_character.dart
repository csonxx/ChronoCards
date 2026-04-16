import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../arpg_game.dart';
import '../../domain/combat/combat_system.dart';
import '../../domain/combat/stamina_system.dart';

/// 攻击类型
enum AttackType {
  light,  // 普攻
  heavy,  // 重击
  skill,  // 技能
}

/// 玩家角色组件
/// 整合现有combat_system/stamina_system的ARPG角色
class PlayerCharacter extends PositionComponent {
  final ArpgGame gameRef;
  
  // ============ 战斗资源 ============
  StaminaResources resources = const StaminaResources(
    hp: 1000,
    maxHp: 1000,
    stamina: 100,
    maxStamina: 100,
    qi: 100,
    maxQi: 100,
  );
  
  // ============ 战斗系统引用 ============
  final CombatSystem combatSystem = CombatSystem();
  StaminaSystem? staminaSystem;
  
  // ============ 移动参数 ============
  static const double moveSpeed = 3.5; // m/s
  Vector2 _moveDirection = Vector2.zero();
  Vector2 _facingDirection = Vector2(1, 0); // 默认朝右
  
  // ============ 攻击状态 ============
  int _comboCount = 0;
  double _comboTimer = 0;
  static const double comboWindowSec = 0.6;
  bool _isAttacking = false;
  double _attackTimer = 0;
  
  // ============ 技能CD ============
  final List<double> skillCooldowns = [0, 0, 0, 0, 0]; // 5个技能CD（秒）
  static const List<double> skillMaxCooldowns = [5, 8, 6, 10, 7];
  static const List<int> skillQiCosts = [20, 30, 25, 35, 25];
  
  // ============ 闪避/格挡 ============
  bool _isDodging = false;
  double _dodgeTimer = 0;
  static const double dodgeDuration = 0.4;
  static const double dodgeCooldown = 1.2;
  double _dodgeCooldownTimer = 0;
  
  bool _isBlocking = false;
  
  // ============ 无敌帧 ============
  bool _hasIFrames = false;
  double _iFrameTimer = 0;
  
  // ============ 动画状态 ============
  String _currentAnimation = 'idle';
  double _animationTimer = 0;
  
  // ============ 普攻伤害配置 ============
  static const List<int> comboDamages = [100, 120, 150];
  static const List<double> comboDamageMultipliers = [1.0, 1.2, 1.5];
  
  PlayerCharacter({required this.gameRef}) {
    position = Vector2(100, 100);
    size = Vector2(64, 64);
    anchor = Anchor.center;
    
    // 初始化气力恢复系统
    staminaSystem = StaminaSystem(
      initial: resources,
      staminaRecoveryPerSec: 10,
      qiOnHit: 5,
      qiOnDamaged: 3,
    );
  }
  
  // ============ 移动控制 ============
  void setMoveDirection(Vector2 dir) {
    _moveDirection = dir;
    if (dir.length > 0.1) {
      _facingDirection = dir.clone()..normalize();
      if (!_isAttacking) {
        _currentAnimation = 'walk';
      }
    } else {
      if (!_isAttacking) {
        _currentAnimation = 'idle';
      }
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新移动
    _updateMovement(dt);
    
    // 更新战斗状态
    _updateCombatState(dt);
    
    // 更新技能CD
    _updateSkillCooldowns(dt);
    
    // 更新气力恢复
    _updateStaminaRecovery(dt);
    
    // 更新无敌帧
    _updateIFrames(dt);
    
    // 更新连击计时
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _comboCount = 0;
      }
    }
    
    // 更新闪避冷却
    if (_dodgeCooldownTimer > 0) {
      _dodgeCooldownTimer -= dt;
    }
    
    // 更新动画
    _updateAnimation(dt);
  }
  
  void _updateMovement(double dt) {
    if (_isDodging || _isAttacking) return;
    
    final displacement = _moveDirection * moveSpeed * dt;
    position += displacement;
  }
  
  void _updateCombatState(double dt) {
    if (!_isAttacking) return;
    
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _isAttacking = false;
      _currentAnimation = 'idle';
    }
  }
  
  void _updateSkillCooldowns(double dt) {
    for (int i = 0; i < skillCooldowns.length; i++) {
      if (skillCooldowns[i] > 0) {
        skillCooldowns[i] = (skillCooldowns[i] - dt).clamp(0, double.infinity);
      }
    }
  }
  
  void _updateStaminaRecovery(double dt) {
    // 气力每秒恢复5点（基础值）
    final qiPerSec = 5.0;
    resources = resources.restoreQi((qiPerSec * dt).round());
  }
  
  void _updateIFrames(double dt) {
    if (!_hasIFrames) return;
    _iFrameTimer -= dt;
    if (_iFrameTimer <= 0) {
      _hasIFrames = false;
      resources = resources.deactivateInvincible();
    }
  }
  
  void _updateAnimation(double dt) {
    _animationTimer += dt;
  }
  
  // ============ 普攻 ============
  void performAttack(AttackType type) {
    if (_isAttacking || _isDodging) return;
    
    // 检查连击窗口
    if (_comboTimer > 0 && _comboCount >= 3) {
      // 连击已满，等待重置
      return;
    }
    
    // 执行当前段攻击
    final comboIndex = _comboCount % 3;
    final damage = comboDamages[comboIndex];
    final multiplier = comboDamageMultipliers[comboIndex];
    
    // 计算最终伤害
    final finalDamage = combatSystem.calculateAttackDamage(
      attackerAttack: 100, // 基础攻击
      damageMultiplier: multiplier,
      baseDamage: damage,
      targetDefense: 20,
      isCrit: false,
      elementBonus: 0,
    );
    
    // 应用伤害到目标
    _applyDamageToEnemies(finalDamage);
    
    // 播放攻击动画
    _playAttackAnimation(comboIndex);
    
    // 设置攻击冷却
    _isAttacking = true;
    _attackTimer = 0.3; // 普攻持续0.3秒
    _comboTimer = comboWindowSec;
    _comboCount++;
    
    // 命中恢复气力
    resources = resources.restoreQi(5);
  }
  
  void _playAttackAnimation(int comboIndex) {
    switch (comboIndex) {
      case 0:
        _currentAnimation = 'attack1';
        break;
      case 1:
        _currentAnimation = 'attack2';
        break;
      case 2:
        _currentAnimation = 'attack3';
        _comboCount = 0; // 第3击后重置连击
        break;
    }
    _animationTimer = 0;
  }
  
  void _applyDamageToEnemies(int damage) {
    // 对所有在攻击范围内的敌人造成伤害
    for (final enemy in gameRef.enemies) {
      final dist = (enemy.position - position).length;
      if (dist < 100) { // 攻击范围2米
        enemy.takeDamage(damage, _facingDirection);
      }
    }
  }
  
  // ============ 技能 ============
  void useSkill(int skillIndex) {
    if (skillIndex < 0 || skillIndex >= 5) return;
    if (skillCooldowns[skillIndex] > 0) return; // 还在冷却
    if (resources.qi < skillQiCosts[skillIndex]) return; // 气力不足
    if (_isDodging) return;
    
    // 消耗气力
    resources = resources.consumeQi(skillQiCosts[skillIndex]);
    
    // 开始技能CD
    skillCooldowns[skillIndex] = skillMaxCooldowns[skillIndex];
    
    // 触发技能效果
    _executeSkill(skillIndex);
  }
  
  void _executeSkill(int skillIndex) {
    _isAttacking = true;
    _currentAnimation = 'skill$skillIndex';
    _attackTimer = 0.5; // 技能持续时间
    
    // 计算技能伤害
    int damage;
    double range;
    bool isAoe = false;
    
    switch (skillIndex) {
      case 0: // 金刚拳
        damage = 250;
        range = 150;
        break;
      case 1: // 太极剑
        damage = 180;
        range = 200;
        isAoe = true;
        break;
      case 2: // 清风剑
        damage = 160;
        range = 300;
        break;
      case 3: // 破剑式
        damage = 400;
        range = 150;
        break;
      case 4: // 打狗棒
        damage = 130;
        range = 180;
        isAoe = true;
        break;
      default:
        damage = 100;
        range = 100;
    }
    
    // 应用伤害
    if (isAoe) {
      _applyAoeDamage(damage, range);
    } else {
      _applySingleTargetDamage(damage, range);
    }
  }
  
  void _applySingleTargetDamage(int damage, double range) {
    // 找到最近的敌人
    EnemyEntity? nearest;
    double nearestDist = double.infinity;
    
    for (final enemy in gameRef.enemies) {
      final dist = (enemy.position - position).length;
      if (dist < range && dist < nearestDist) {
        nearest = enemy;
        nearestDist = dist;
      }
    }
    
    if (nearest != null) {
      nearest.takeDamage(damage, _facingDirection);
    }
  }
  
  void _applyAoeDamage(int damage, double range) {
    for (final enemy in gameRef.enemies) {
      final dist = (enemy.position - position).length;
      if (dist < range) {
        enemy.takeDamage(damage, _facingDirection);
      }
    }
  }
  
  // ============ 闪避 ============
  void tryDodge() {
    if (_isDodging) return;
    if (_dodgeCooldownTimer > 0) return;
    if (resources.stamina < 15) return;
    
    // 消耗气力
    resources = resources.consumeStamina(15);
    
    // 开始闪避
    _isDodging = true;
    _dodgeTimer = dodgeDuration;
    _dodgeCooldownTimer = dodgeCooldown;
    
    // 激活无敌帧
    _hasIFrames = true;
    _iFrameTimer = dodgeDuration;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    resources = resources.activateInvincible((dodgeDuration * 1000).round(), nowMs);
    
    // 闪避位移
    final dodgeDir = _facingDirection.clone()..normalize();
    position += dodgeDir * 100; // 闪避3米
    
    _currentAnimation = 'dodge';
  }
  
  // ============ 格挡 ============
  void startBlock() {
    if (_isDodging) return;
    _isBlocking = true;
    resources = resources.startBlock(DateTime.now().millisecondsSinceEpoch);
  }
  
  void endBlock() {
    if (!_isBlocking) return;
    _isBlocking = false;
    resources = resources.endBlock();
  }
  
  // ============ 受击 ============
  void takeDamage(int damage, Vector2 attackDirection) {
    if (_hasIFrames) return; // 无敌帧保护
    
    int finalDamage = damage;
    
    // 格挡判定
    if (_isBlocking) {
      final blockResult = combatSystem.evaluateBlock(
        resources: resources,
        incomingDamage: damage,
        currentTimeMs: DateTime.now().millisecondsSinceEpoch,
        attackerIsStaggered: false,
      );
      
      if (blockResult.success) {
        if (blockResult.isPerfectBlock) {
          // 完美格挡：完全免伤
          finalDamage = 0;
          resources = resources.restoreStamina(15); // 反击恢复气力
        } else {
          // 普通格挡：70%减伤
          finalDamage = blockResult.damageReduced;
        }
      }
    }
    
    // 应用伤害
    if (finalDamage > 0) {
      resources = resources.consumeHp(finalDamage);
      
      // 受击时恢复少量气力
      resources = resources.restoreQi(3);
      
      // 检查死亡
      if (!resources.isAlive) {
        gameRef.triggerGameOver();
      }
    }
  }
  
  // ============ 重置 ============
  void reset() {
    resources = const StaminaResources(
      hp: 1000,
      maxHp: 1000,
      stamina: 100,
      maxStamina: 100,
      qi: 100,
      maxQi: 100,
    );
    _comboCount = 0;
    _comboTimer = 0;
    _isAttacking = false;
    _isDodging = false;
    _isBlocking = false;
    _hasIFrames = false;
    skillCooldowns.fillRange(0, 5, 0);
    position = Vector2(100, 100);
    _currentAnimation = 'idle';
  }
  
  @override
  void render(Canvas canvas) {
    // 渲染角色（后续替换为sprite动画）
    final paint = Paint();
    
    if (_hasIFrames) {
      // 无敌帧闪烁效果
      paint.color = (_animationTimer * 10).floor() % 2 == 0 
          ? const Color(0xFFFFFFF) 
          : const Color(0x88FFFFFF);
    }
    
    // 基础圆形表示角色
    paint.color = const Color(0xFF4A90D9);
    canvas.drawCircle(Offset.zero, size.x / 2, paint);
    
    // 方向指示器
    final dirPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    
    final dirOffset = _facingDirection * (size.x / 2 - 5);
    canvas.drawCircle(dirOffset.toOffset(), 5, dirPaint);
    
    // 显示当前动画状态（调试用）
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$_currentAnimation\nHP:${resources.hp}/${resources.maxHp}\nQi:${resources.qi}/${resources.maxQi}',
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-30, -50));
  }
}

// 导入
