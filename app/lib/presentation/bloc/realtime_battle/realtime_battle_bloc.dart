import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/battle_constants.dart';
import '../../../core/constants/battle_durations.dart';
import '../../../game/models/battle_phase.dart';
import 'realtime_battle_event.dart';
import 'realtime_battle_state.dart';

/// 实时战斗BLoC - 使用BLoC模式管理战斗状态
/// 替代原有的Provider/ChangeNotifier模式
class RealtimeBattleBloc extends Bloc<RealtimeBattleEvent, RealtimeBattleState> {
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

  RealtimeBattleBloc() : super(RealtimeBattleState.initial()) {
    on<InitBattle>(_onInitBattle);
    on<PlayerAttack>(_onPlayerAttack);
    on<PlayerDodge>(_onPlayerDodge);
    on<EnemyAttackTrigger>(_onEnemyAttackTrigger);
    on<EnemyAttackHit>(_onEnemyAttackHit);
    on<UpdateStamina>(_onUpdateStamina);
    on<UpdateBattleTime>(_onUpdateBattleTime);
    on<RemoveDamageNumber>(_onRemoveDamageNumber);
    on<ClearBattleTip>(_onClearBattleTip);
  }

  void _onInitBattle(InitBattle event, Emitter<RealtimeBattleState> emit) {
    _disposeTimers();
    _damageIdCounter = 0;
    _battleStartTime = DateTime.now();
    _lastStaminaUpdateMs = DateTime.now().millisecondsSinceEpoch;

    emit(RealtimeBattleState.initial());

    // 战斗开始淡入后进入fighting状态
    Future.delayed(BattleDurations.battleFadeIn, () {
      if (!isClosed) {
        add(const UpdateBattleTime());
        emit(state.copyWith(phase: BattlePhase.fighting, battleTip: '战斗开始！', showBattleTip: true));
        _startStaminaRecovery();
        _startEnemyAttackTimer();

        // 隐藏提示
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!isClosed) {
            add(ClearBattleTip());
          }
        });
      }
    });
  }

  void _onPlayerAttack(PlayerAttack event, Emitter<RealtimeBattleState> emit) {
    if (!state.canAttack ||
        state.phase != BattlePhase.fighting ||
        state.player.isDead) return;

    emit(state.copyWith(canAttack: false));

    // 敌人受伤
    final updatedEnemy = state.enemy.takeDamage(state.player.attackDamage);
    final damageNumber = DamageNumberData(
      id: '${_damageIdCounter++}',
      text: '-${state.player.attackDamage}',
      color: const Color(0xFFFFD93D),
      position: _enemyDamagePos,
    );
    emit(state.copyWith(
      enemy: updatedEnemy,
      isEnemyHurt: true,
      damageNumbers: [...state.damageNumbers, damageNumber],
    ));

    // 检查战斗结束
    _checkBattleEnd(emit);

    // 硬直300ms后恢复攻击
    Future.delayed(BattleDurations.attackCooldown, () {
      if (!isClosed && state.phase == BattlePhase.fighting) {
        emit(state.copyWith(canAttack: true, isEnemyHurt: false));
      }
    });

    // 伤害数字消失
    Future.delayed(BattleDurations.damageFloat, () {
      if (!isClosed) {
        add(RemoveDamageNumber(damageNumber.id));
      }
    });
  }

  void _onPlayerDodge(PlayerDodge event, Emitter<RealtimeBattleState> emit) {
    if (state.phase != BattlePhase.fighting ||
        !state.staminaSufficient ||
        state.player.isDead) return;

    emit(state.copyWith(
      stamina: state.stamina - BattleConstants.dodgeStaminaCost,
      isDodging: true,
      battleTip: '闪避成功！',
      showBattleTip: true,
    ));

    // 无敌帧200ms后结束
    Future.delayed(BattleConstants.invincibleDuration, () {
      if (!isClosed) {
        emit(state.copyWith(isDodging: false));
      }
    });

    // 隐藏提示
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!isClosed) {
        add(ClearBattleTip());
      }
    });
  }

  void _onEnemyAttackTrigger(EnemyAttackTrigger event, Emitter<RealtimeBattleState> emit) {
    if (state.phase != BattlePhase.fighting || state.enemy.isDead) return;

    // 攻击前摇
    emit(state.copyWith(isEnemyWindup: true));

    Future.delayed(BattleDurations.enemyAttackWindup, () {
      if (!isClosed) {
        add(EnemyAttackHit());
      }
    });
  }

  void _onEnemyAttackHit(EnemyAttackHit event, Emitter<RealtimeBattleState> emit) {
    if (!isClosed && state.phase != BattlePhase.fighting) return;

    emit(state.copyWith(isEnemyWindup: false));

    if (state.isDodging) {
      final dodgeText = DamageNumberData(
        id: '${_damageIdCounter++}',
        text: '闪避',
        color: const Color(0xFF3B82F6),
        position: _dodgeTextPos,
      );
      emit(state.copyWith(
        battleTip: '闪避成功！',
        showBattleTip: true,
        damageNumbers: [...state.damageNumbers, dodgeText],
      ));

      Future.delayed(BattleDurations.damageFloat, () {
        if (!isClosed) {
          add(RemoveDamageNumber(dodgeText.id));
        }
      });
    } else {
      // 玩家受伤
      final updatedPlayer = state.player.takeDamage(state.enemy.attackDamage);
      final damageNumber = DamageNumberData(
        id: '${_damageIdCounter++}',
        text: '-${state.enemy.attackDamage}',
        color: const Color(0xFFef4444),
        position: _playerDamagePos,
      );
      emit(state.copyWith(
        player: updatedPlayer,
        isPlayerHurt: true,
        damageNumbers: [...state.damageNumbers, damageNumber],
      ));

      _checkBattleEnd(emit);

      Future.delayed(BattleDurations.damageFloat, () {
        if (!isClosed) {
          add(RemoveDamageNumber(damageNumber.id));
        }
      });
    }

    Future.delayed(BattleDurations.hurtFlash, () {
      if (!isClosed) {
        emit(state.copyWith(isPlayerHurt: false));
      }
    });
  }

  void _onUpdateStamina(UpdateStamina event, Emitter<RealtimeBattleState> emit) {
    if (state.phase != BattlePhase.fighting) return;

    final elapsedSec = event.elapsedMs / 1000.0;
    if (elapsedSec <= 0) return;

    final recovered = elapsedSec * BattleConstants.staminaRecoveryPerSec;
    final newStamina = (state.stamina + recovered)
        .clamp(0.0, BattleConstants.maxStamina.toDouble())
        .toInt();

    if (newStamina != state.stamina) {
      emit(state.copyWith(stamina: newStamina));
    }
  }

  void _onUpdateBattleTime(UpdateBattleTime event, Emitter<RealtimeBattleState> emit) {
    if (_battleStartTime != null) {
      final seconds = DateTime.now().difference(_battleStartTime!).inSeconds;
      if (seconds != state.battleTimeSeconds) {
        emit(state.copyWith(battleTimeSeconds: seconds));
      }
    }
  }

  void _onRemoveDamageNumber(RemoveDamageNumber event, Emitter<RealtimeBattleState> emit) {
    final updatedList = state.damageNumbers.where((d) => d.id != event.id).toList();
    emit(state.copyWith(damageNumbers: updatedList));
  }

  void _onClearBattleTip(ClearBattleTip event, Emitter<RealtimeBattleState> emit) {
    emit(state.copyWith(showBattleTip: false));
  }

  // ==================== 内部方法 ====================

  void _startEnemyAttackTimer() {
    _enemyAttackTimer?.cancel();
    _enemyAttackTimer = Timer.periodic(
      BattleDurations.enemyAttackInterval,
      (_) => add(EnemyAttackTrigger()),
    );
  }

  void _startStaminaRecovery() {
    _staminaRecoveryTimer?.cancel();
    _lastStaminaUpdateMs = DateTime.now().millisecondsSinceEpoch;
    _staminaRecoveryTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = nowMs - _lastStaminaUpdateMs;
        _lastStaminaUpdateMs = nowMs;
        add(UpdateStamina(elapsedMs));
      },
    );
  }

  void _checkBattleEnd(Emitter<RealtimeBattleState> emit) {
    if (state.enemy.isDead) {
      _endBattle(BattleResult.victory, emit);
    } else if (state.player.isDead) {
      _endBattle(BattleResult.defeat, emit);
    }
  }

  void _endBattle(BattleResult result, Emitter<RealtimeBattleState> emit) {
    _staminaRecoveryTimer?.cancel();
    _enemyAttackTimer?.cancel();

    String tip;
    if (result == BattleResult.victory) {
      tip = '胜利！';
    } else {
      tip = '战败...';
    }

    emit(state.copyWith(
      phase: BattlePhase.ended,
      result: result,
      battleTip: tip,
      showBattleTip: true,
    ));
  }

  void _disposeTimers() {
    _staminaRecoveryTimer?.cancel();
    _enemyAttackTimer?.cancel();
  }

  @override
  Future<void> close() {
    _disposeTimers();
    return super.close();
  }
}
