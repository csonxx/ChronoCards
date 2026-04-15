import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/battle_constants.dart';
import '../../../game/models/battle_entity.dart';
import '../../../game/models/battle_phase.dart';

/// 伤害数字数据结构
class DamageNumberData extends Equatable {
  final String id;
  final String text;
  final Color color;
  final Offset position;

  const DamageNumberData({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
  });

  @override
  List<Object?> get props => [id, text, color, position];
}

/// 实时战斗状态
class RealtimeBattleState extends Equatable {
  final BattleEntity player;
  final BattleEntity enemy;
  final BattlePhase phase;
  final BattleResult? result;
  final int stamina;
  final bool isPlayerHurt;
  final bool isEnemyHurt;
  final bool isDodging;
  final bool isEnemyWindup;
  final bool canAttack;
  final String? battleTip;
  final bool showBattleTip;
  final List<DamageNumberData> damageNumbers;
  final int battleTimeSeconds;

  const RealtimeBattleState({
    required this.player,
    required this.enemy,
    required this.phase,
    required this.stamina,
    required this.isPlayerHurt,
    required this.isEnemyHurt,
    required this.isDodging,
    required this.isEnemyWindup,
    required this.canAttack,
    required this.damageNumbers,
    required this.battleTimeSeconds,
    this.result,
    this.battleTip,
    this.showBattleTip = false,
  });

  /// 初始状态工厂
  factory RealtimeBattleState.initial() {
    return RealtimeBattleState(
      player: BattleEntity.full(
        name: '少侠',
        maxHp: BattleConstants.playerMaxHp,
        attackDamage: BattleConstants.playerAttackDamage,
        level: BattleConstants.playerLevel,
      ),
      enemy: BattleEntity.full(
        name: BattleConstants.enemyName,
        maxHp: BattleConstants.enemyMaxHp,
        attackDamage: BattleConstants.enemyAttackDamage,
      ),
      phase: BattlePhase.starting,
      stamina: BattleConstants.maxStamina,
      isPlayerHurt: false,
      isEnemyHurt: false,
      isDodging: false,
      isEnemyWindup: false,
      canAttack: true,
      damageNumbers: const [],
      battleTimeSeconds: 0,
    );
  }

  /// 体力是否足够闪避
  bool get staminaSufficient => stamina >= BattleConstants.dodgeStaminaCost;

  @override
  RealtimeBattleState copyWith({
    BattleEntity? player,
    BattleEntity? enemy,
    BattlePhase? phase,
    BattleResult? result,
    int? stamina,
    bool? isPlayerHurt,
    bool? isEnemyHurt,
    bool? isDodging,
    bool? isEnemyWindup,
    bool? canAttack,
    String? battleTip,
    bool? showBattleTip,
    List<DamageNumberData>? damageNumbers,
    int? battleTimeSeconds,
    bool clearResult = false,
  }) {
    return RealtimeBattleState(
      player: player ?? this.player,
      enemy: enemy ?? this.enemy,
      phase: phase ?? this.phase,
      result: clearResult ? null : (result ?? this.result),
      stamina: stamina ?? this.stamina,
      isPlayerHurt: isPlayerHurt ?? this.isPlayerHurt,
      isEnemyHurt: isEnemyHurt ?? this.isEnemyHurt,
      isDodging: isDodging ?? this.isDodging,
      isEnemyWindup: isEnemyWindup ?? this.isEnemyWindup,
      canAttack: canAttack ?? this.canAttack,
      battleTip: battleTip ?? this.battleTip,
      showBattleTip: showBattleTip ?? this.showBattleTip,
      damageNumbers: damageNumbers ?? this.damageNumbers,
      battleTimeSeconds: battleTimeSeconds ?? this.battleTimeSeconds,
    );
  }

  @override
  List<Object?> get props => [
        player,
        enemy,
        phase,
        result,
        stamina,
        isPlayerHurt,
        isEnemyHurt,
        isDodging,
        isEnemyWindup,
        canAttack,
        battleTip,
        showBattleTip,
        damageNumbers,
        battleTimeSeconds,
      ];
}
