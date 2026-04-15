/// 战斗状态枚举
enum BattlePhase {
  /// 战斗开始中（淡入动画）
  starting,
  
  /// 战斗中
  fighting,
  
  /// 战斗结束
  ended,
}

/// 战斗结果
enum BattleResult {
  /// 胜利
  victory,
  
  /// 战败
  defeat,
}