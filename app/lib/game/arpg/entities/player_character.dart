import 'dart:ui';
import 'enemy_entity.dart';
import 'enemy_entity.dart';
import '../arpg_game.dart' show ArpgGame;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/floating_damage_text.dart';
import '../../../domain/combat/combat_system.dart';
import '../../../domain/combat/stamina_system.dart';
import '../../../game/models/combat/combat_entity.dart';

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
  // PRD指定的技能CD
  static const List<double> skillMaxCooldowns = [5, 8, 6, 10, 7];
  // PRD指定的气力消耗
  static const List<int> skillQiCosts = [20, 30, 25, 35, 25];
  
  // ============ 闪避/格挡 ============
  bool _isDodging = false;
  double _dodgeTimer = 0;
  static const double dodgeDuration = 0.4; // 0.4秒无敌帧
  static const double dodgeCooldown = 1.2;
  static const int dodgeQiCost = 15;
  static const double dodgeDistance = 100.0; // 3米(游戏单位100)
  
  double _dodgeCooldownTimer = 0;
  
  bool _isBlocking = false;
  
  // ============ 无敌帧 ============
  bool _hasIFrames = false;
  double _iFrameTimer = 0;
  
  /// 无敌帧状态（供EnemyBehavior检查）
  bool get isInIFrames => _hasIFrames;
  
  // ============ 动画状态 ============
  String _currentAnimation = 'idle';
  double _animationTimer = 0;
  
  // ============ 普攻伤害配置（PRD: 100 → 120 → 150） ============
  static const List<int> comboDamages = [100, 120, 150];
  static const List<double> comboDamageMultipliers = [1.0, 1.2, 1.5];
  // 第3击击退距离
  static const double combo3Knockback = 50.0; // 0.5米
  
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
    
    // 更新闪避状态
    if (_isDodging) {
      _dodgeTimer -= dt;
      if (_dodgeTimer <= 0) {
        _isDodging = false;
        _currentAnimation = 'idle';
      }
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
  
  // ============ 普攻 - J键 ============
  /// 3段连击：100 → 120 → 150 伤害
  /// 每次攻击后0.6秒内必须接下一击，否则重置
  /// 第3击有0.5米击退
  void performAttack(AttackType type) {
    if (_isAttacking || _isDodging) return;
    
    // 检查连击窗口（最多3连击）
    if (_comboTimer > 0 && _comboCount >= 3) {
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
    final hitEnemies = _applyDamageToEnemies(finalDamage, comboIndex == 2); // 第3击有击退
    
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
  
  List<EnemyEntity> _applyDamageToEnemies(int damage, bool hasKnockback) {
    final hitEnemies = <EnemyEntity>[];
    
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < 100) { // 攻击范围2米(100游戏单位)
        // 传递击退方向，第3击有额外击退
        final knockbackForce = hasKnockback ? combo3Knockback : 0.0;
        enemy.takeDamage(damage, _facingDirection, knockbackForce: knockbackForce);
        
        // 显示伤害数字
        _showDamageNumber(enemy.position, damage);
        
        hitEnemies.add(enemy);
      }
    }
    return hitEnemies;
  }
  
  void _showDamageNumber(Vector2 pos, int damage) {
    final dmgText = FloatingDamageText(
      position: pos.clone()..add(Vector2(0, -30)),
      baseColor: const Color(0xFFFFCC00),
      damage: damage.toDouble(),
    );
    gameRef.add(dmgText);
  }
  
  // ============ 技能 - K/L/U/I/O键 ============
  /// K: 金刚拳 - 伤害250, CD5秒, 气力20, 霸体+击倒
  /// L: 太极剑 - 伤害540(180×3), CD8秒, 气力30, AOE定身
  /// U: 清风剑 - 伤害160, CD6秒, 气力25, 穿透
  /// I: 破剑式 - 伤害480, CD10秒, 气力35, 无视防御
  /// O: 打狗棒 - 伤害260(130×2), CD7秒, 气力25, 减速
  
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
    
    switch (skillIndex) {
      case 0: // K: 金刚拳 - 伤害250, 霸体+击倒
        _skillJingangPunch();
        break;
      case 1: // L: 太极剑 - 伤害540(180×3), AOE定身
        _skillTaijiSword();
        break;
      case 2: // U: 清风剑 - 伤害160, 穿透
        _skillQingfengSword();
        break;
      case 3: // I: 破剑式 - 伤害480, 无视防御
        _skillPoJian();
        break;
      case 4: // O: 打狗棒 - 伤害260(130×2), 减速
        _skillDaGou();
        break;
    }
  }
  
  // K: 金刚拳 - 伤害250, 霸体+击倒
  void _skillJingangPunch() {
    const damage = 250;
    const range = 150.0;
    
    // 霸体激活（不被打断）
    _hasIFrames = true;
    _iFrameTimer = 0.5;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    resources = resources.activateInvincible(500, nowMs);
    
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < range) {
        // 击倒效果（较大击退）
        enemy.takeDamage(damage, _facingDirection, knockbackForce: 80.0, isKnockdown: true);
        _showDamageNumber(enemy.position, damage);
      }
    }
  }
  
  // L: 太极剑 - 伤害540(180×3), CD8秒, 气力30, AOE定身
  void _skillTaijiSword() {
    const totalDamage = 540; // 180×3
    const range = 200.0;
    
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < range) {
        // 3段伤害
        for (int i = 0; i < 3; i++) {
          Future.delayed(Duration(milliseconds: 100 * i), () {
            if (!enemy.isDead) {
              enemy.takeDamage(180, _facingDirection, knockbackForce: 0, isStunned: true);
              _showDamageNumber(enemy.position, 180);
            }
          });
        }
      }
    }
  }
  
  // U: 清风剑 - 伤害160, CD6秒, 气力25, 穿透
  void _skillQingfengSword() {
    const damage = 160;
    const range = 300.0;
    
    // 穿透：可以命中多个敌人
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < range) {
        enemy.takeDamage(damage, _facingDirection, knockbackForce: 0);
        _showDamageNumber(enemy.position, damage);
      }
    }
  }
  
  // I: 破剑式 - 伤害480, CD10秒, 气力35, 无视防御
  void _skillPoJian() {
    const damage = 480;
    const range = 150.0;
    
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < range) {
        // 无视防御：直接扣血
        enemy.takePiercingDamage(damage, _facingDirection);
        _showDamageNumber(enemy.position, damage);
      }
    }
  }
  
  // O: 打狗棒 - 伤害260(130×2), CD7秒, 气力25, 减速
  void _skillDaGou() {
    const damagePerHit = 130;
    const range = 180.0;
    const slowDuration = 2.0;
    const slowAmount = 0.4; // 40%减速
    
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead) continue;
      final dist = (enemy.position - position).length;
      if (dist < range) {
        // 2段伤害
        for (int i = 0; i < 2; i++) {
          Future.delayed(Duration(milliseconds: 150 * i), () {
            if (!enemy.isDead) {
              enemy.takeDamage(damagePerHit, _facingDirection, knockbackForce: 0);
              enemy.applySlow(slowAmount, slowDuration);
              _showDamageNumber(enemy.position, damagePerHit);
            }
          });
        }
      }
    }
  }
  
  // ============ 闪避 - 空格键 ============
  /// 0.4秒无敌帧, 位移3米, CD1.2秒, 气力15
  void tryDodge() {
    if (_isDodging) return;
    if (_dodgeCooldownTimer > 0) return;
    if (resources.stamina < dodgeQiCost) return;
    
    // 消耗气力
    resources = resources.consumeStamina(dodgeQiCost);
    
    // 开始闪避
    _isDodging = true;
    _dodgeTimer = dodgeDuration;
    _dodgeCooldownTimer = dodgeCooldown;
    
    // 激活无敌帧
    _hasIFrames = true;
    _iFrameTimer = dodgeDuration;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    resources = resources.activateInvincible((dodgeDuration * 1000).round(), nowMs);
    
    // 闪避位移（3米=100游戏单位）
    final dodgeDir = _facingDirection.clone()..normalize();
    position += dodgeDir * dodgeDistance;
    
    _currentAnimation = 'dodge';
  }
  
  // ============ 格挡 - SHIFT按住 ============
  /// 减免70%伤害, 完美格挡(0.1秒内)完全免伤+反击
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
  void takeDamage(int damage, Vector2 attackDirection, {double knockbackForce = 0, bool isKnockdown = false, bool isStunned = false}) {
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
          // 反击恢复气力
          resources = resources.restoreStamina(15);
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
  
  // 转换为CombatEntity（供EnemyBehavior使用）
  CombatEntity _toCombatEntity() {
    return CombatEntity(
      id: 'player',
      name: '玩家',
      level: 1,
      maxHp: resources.maxHp,
      currentHp: resources.hp,
      maxStamina: resources.maxStamina,
      currentStamina: resources.stamina,
      maxQi: resources.maxQi,
      currentQi: resources.qi,
      attack: 100,
      defense: 20,
    );
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
    
    // 绘制血条
    final hpRatio = resources.hp / resources.maxHp;
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
    
    // 气力条
    final qiRatio = resources.qi / resources.maxQi;
    final qiPaint = Paint()..color = const Color(0xFF4488FF);
    canvas.drawRect(
      Rect.fromLTWH(-hpBarWidth / 2, -size.y / 2 - 8, hpBarWidth * qiRatio, hpBarHeight - 2),
      qiPaint,
    );
    
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
