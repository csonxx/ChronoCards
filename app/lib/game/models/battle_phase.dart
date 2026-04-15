import 'package:equatable/equatable.dart';

/// 战斗状态枚举 - 使用 Equatable 支持值比较
enum BattlePhase with EquatableMixin {
  /// 战斗开始中（淡入动画）
  starting,

  /// 战斗中
  fighting,

  /// 战斗结束
  ended,
  ;

  @override
  List<Object?> get props => [name];
}

/// 战斗结果枚举
enum BattleResult with EquatableMixin {
  /// 胜利
  victory,

  /// 战败
  defeat,
  ;

  @override
  List<Object?> get props => [name];
}
