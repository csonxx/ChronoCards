import 'package:equatable/equatable.dart';

/// 实时战斗事件
abstract class RealtimeBattleEvent extends Equatable {
  const RealtimeBattleEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化战斗
class InitBattle extends RealtimeBattleEvent {}

/// 玩家攻击
class PlayerAttack extends RealtimeBattleEvent {}

/// 玩家闪避
class PlayerDodge extends RealtimeBattleEvent {}

/// 敌人攻击触发
class EnemyAttackTrigger extends RealtimeBattleEvent {}

/// 敌人攻击命中
class EnemyAttackHit extends RealtimeBattleEvent {}

/// 更新体力（定时器触发）
class UpdateStamina extends RealtimeBattleEvent {
  final int elapsedMs;

  const UpdateStamina(this.elapsedMs);

  @override
  List<Object?> get props => [elapsedMs];
}

/// 更新战斗时间
class UpdateBattleTime extends RealtimeBattleEvent {}

/// 清除伤害数字
class RemoveDamageNumber extends RealtimeBattleEvent {
  final String id;

  const RemoveDamageNumber(this.id);

  @override
  List<Object?> get props => [id];
}

/// 重置战斗提示
class ClearBattleTip extends RealtimeBattleEvent {}
