import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/battle_constants.dart';
import '../../core/constants/battle_durations.dart';
import '../models/battle_entity.dart';
import '../models/battle_phase.dart';
import 'battle_state.dart';

/// 战斗控制器 - 核心游戏逻辑
/// 使用 ChangeNotifier 模式管理战斗状态
class BattleController extends ChangeNotifier {
  BattleState _state = BattleState.initial();
  BattleState get state => _state;

  // 内部计时器
  Timer? _staminaRecoveryTimer;
  Timer? _enemyAttackTimer;
  DateTime? _battleStartTime;
  int _lastStaminaUpdateMs = 0;

  // 伤害数字ID计数器
  int _damageIdCounter = 0;

  // 伤害数字位置
  static const Offset _playerDamagePos = Offset(200, 200);
  static const Offset _enemyDamagePos = Offset(900, 300);
  static const Offset _dodgeTextPos = Offset(500, 300);

  /// 初始化战斗（重新开始）
  void initBattle() {
    _disposeTimers();
    _state = BattleState.initial();
    _damageIdCounter = 0;
    _battleStartTime = DateTime.now();
    _lastStaminaUpdateMs = 0;
    notifyListeners();

    // 战斗开始淡入后进入fighting状态
    Future.delayed(BattleDurations.battleFadeIn, () {
      if (!mounted) return;
      _setPhase(BattlePhase.fighting);
      _showTip('战斗开始！');
      _startStaminaRecovery();
      _startEnemyAttackTimer();
    });
  }

  // ==================== 战斗操作 ====================

  /// 玩家攻击
  void attack() {
    if (!_state.canAttack ||
        _state.phase != BattlePhase.fighting ||
        _state.player.isDead) return;

    _setState(_state.copyWith(canAttack: false));

    // 敌人受伤
    _enemyTakeDamage(_state.player.attackDamage);
    _triggerEnemyHurt();
    _addDamageNumber(
        '-${_state.player.attackDamage}', const Color(0xFFFFD93D), _enemyDamagePos);
    _checkBattleEnd();

    // 硬直300ms后恢复攻击
    Future.delayed(BattleDurations.attackCooldown, () {
      if (!mounted) return;
      if (_state.phase == BattlePhase.fighting) {
        _setState(_state.copyWith(canAttack: true));
      }
    });
  }

  /// 玩家闪避
  void dodge() {
    if (_state.phase != BattlePhase.fighting ||
        !_state.staminaSufficient ||
        _state.player.isDead) return;

    _setState(_state.copyWith(
      stamina: _state.stamina - BattleConstants.dodgeStaminaCost,
      isDodging: true,
    ));

    // 无敌帧200ms后结束
    Future.delayed(BattleConstants.invincibleDuration, () {
      if (!mounted) return;
      _setState(_state.copyWith(isDodging: false));
    });
  }

  // ==================== 敌人AI ====================

  void _startEnemyAttackTimer() {
    _enemyAttackTimer?.cancel();
    _enemyAttackTimer = Timer.periodic(
      BattleDurations.enemyAttackInterval,
      (_) => _triggerEnemyAttack(),
    );
  }

  void _triggerEnemyAttack() {
    if (_state.phase != BattlePhase.fighting || _state.enemy.isDead) return;

    // 攻击前摇：0.3秒
    _setState(_state.copyWith(isEnemyWindup: true));

    Future.delayed(BattleDurations.enemyAttackWindup, () {
      if (!mounted) return;
      _setState(_state.copyWith(isEnemyWindup: false));

      if (_state.phase != BattlePhase.fighting) return;

      // 检查无敌帧
      if (_state.isDodging) {
        _showTip('闪避成功！');
        _addDamageNumber('闪避', const Color(0xFF3B82F6), _dodgeTextPos);
      } else {
        // 玩家受伤
        _playerTakeDamage(_state.enemy.attackDamage);
        _triggerPlayerHurt();
        _addDamageNumber(
            '-${_state.enemy.attackDamage}', const Color(0xFFef4444), _playerDamagePos);
        _checkBattleEnd();
      }
    });
  }

  // ==================== 体力恢复 ====================

  void _startStaminaRecovery() {
    _staminaRecoveryTimer?.cancel();
    _lastStaminaUpdateMs = DateTime.now().millisecondsSinceEpoch;
    _staminaRecoveryTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateStamina(),
    );
  }

  void _updateStamina() {
    if (_state.phase != BattlePhase.fighting) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = (nowMs - _lastStaminaUpdateMs) / 1000.0;
    _lastStaminaUpdateMs = nowMs;

    if (elapsedSec <= 0) return;

    final recovered = elapsedSec * BattleConstants.staminaRecoveryPerSec;
    final newStamina = (_state.stamina + recovered)
        .clamp(0.0, BattleConstants.maxStamina.toDouble())
        .toInt();

    if (newStamina != _state.stamina) {
      _setState(_state.copyWith(stamina: newStamina));
    }

    // 更新战斗时间
    if (_battleStartTime != null) {
      final seconds = DateTime.now().difference(_battleStartTime!).inSeconds;
      if (seconds != _state.battleTimeSeconds) {
        _setState(_state.copyWith(battleTimeSeconds: seconds));
      }
    }
  }

  // ==================== 辅助方法 ====================

  void _playerTakeDamage(int damage) {
    final updated = _state.player.copyWith();
    updated.takeDamage(damage);
    _setState(_state.copyWith(player: updated));
  }

  void _enemyTakeDamage(int damage) {
    final updated = _state.enemy.copyWith();
    updated.takeDamage(damage);
    _setState(_state.copyWith(enemy: updated));
  }

  void _triggerPlayerHurt() {
    _setState(_state.copyWith(isPlayerHurt: true));
    Future.delayed(BattleDurations.hurtFlash, () {
      if (!mounted) return;
      _setState(_state.copyWith(isPlayerHurt: false));
    });
  }

  void _triggerEnemyHurt() {
    _setState(_state.copyWith(isEnemyHurt: true));
    Future.delayed(BattleDurations.hitFlash, () {
      if (!mounted) return;
      _setState(_state.copyWith(isEnemyHurt: false));
    });
  }

  void _showTip(String text) {
    _setState(_state.copyWith(battleTip: text, showBattleTip: true));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _setState(_state.copyWith(showBattleTip: false));
    });
  }

  void _addDamageNumber(String text, Color color, Offset position) {
    final id = '${_damageIdCounter++}';
    final newList = List<DamageNumberData>.from(_state.damageNumbers)
      ..add(DamageNumberData(
        id: id,
        text: text,
        color: color,
        position: position,
      ));
    _setState(_state.copyWith(damageNumbers: newList));

    Future.delayed(BattleDurations.damageFloat, () {
      if (!mounted) return;
      final updatedList = _state.damageNumbers.where((d) => d.id != id).toList();
      _setState(_state.copyWith(damageNumbers: updatedList));
    });
  }

  void _checkBattleEnd() {
    if (_state.enemy.isDead) {
      _endBattle(BattleResult.victory);
    } else if (_state.player.isDead) {
      _endBattle(BattleResult.defeat);
    }
  }

  void _endBattle(BattleResult result) {
    _setPhase(BattlePhase.ended);
    _setState(_state.copyWith(result: result));
    _staminaRecoveryTimer?.cancel();
    _enemyAttackTimer?.cancel();

    if (result == BattleResult.victory) {
      _showTip('胜利！');
    } else {
      _showTip('战败...');
    }
  }

  void _setPhase(BattlePhase phase) {
    _setState(_state.copyWith(phase: phase));
  }

  void _setState(BattleState newState) {
    _state = newState;
    notifyListeners();
  }

  void _disposeTimers() {
    _staminaRecoveryTimer?.cancel();
    _enemyAttackTimer?.cancel();
  }

  @override
  void dispose() {
    _disposeTimers();
    super.dispose();
  }
}
