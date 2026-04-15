import 'dart:async';
import 'package:equatable/equatable.dart';

/// 战斗资源系统：体力、内力、真气、HP
/// 管理所有战斗相关资源的数值和恢复逻辑
class StaminaResources extends Equatable {
  // HP
  final int hp;
  final int maxHp;

  // 体力（闪避/格挡消耗）
  final int stamina;
  final int maxStamina;

  // 内力/真气（技能消耗）
  final int qi;
  final int maxQi;

  // 护盾值（内功提供）
  final int shield;
  final int maxShield;

  // 无敌帧状态
  final bool isInvincible;
  final int invincibleUntilMs; // timestamp

  // 格挡状态
  final bool isBlocking;
  final int perfectBlockWindowMs; // 完美格挡窗口(ms)
  final int lastBlockTimeMs;

  const StaminaResources({
    this.hp = 100,
    this.maxHp = 100,
    this.stamina = 100,
    this.maxStamina = 100,
    this.qi = 50,
    this.maxQi = 50,
    this.shield = 0,
    this.maxShield = 0,
    this.isInvincible = false,
    this.invincibleUntilMs = 0,
    this.isBlocking = false,
    this.perfectBlockWindowMs = 200,
    this.lastBlockTimeMs = 0,
  });

  // ============ 基础属性 ============

  double get hpPercent => maxHp > 0 ? hp / maxHp : 0;
  double get staminaPercent => maxStamina > 0 ? stamina / maxStamina : 0;
  double get qiPercent => maxQi > 0 ? qi / maxQi : 0;
  double get shieldPercent => maxShield > 0 ? shield / maxShield : 0;

  bool get isAlive => hp > 0;
  bool get isFullStamina => stamina >= maxStamina;
  bool get isFullQi => qi >= maxQi;

  // ============ 消耗 ============

  /// 消耗体力（闪避/格挡）
  StaminaResources consumeStamina(int amount) {
    return copyWith(stamina: (stamina - amount).clamp(0, maxStamina));
  }

  /// 消耗内力（技能释放）
  StaminaResources consumeQi(int amount) {
    return copyWith(qi: (qi - amount).clamp(0, maxQi));
  }

  /// 消耗HP
  StaminaResources consumeHp(int amount) {
    final afterShield = amount > shield ? amount - shield : 0;
    final newShield = amount > shield ? 0 : shield - amount;
    final newHp = (hp - afterShield).clamp(0, maxHp);
    return copyWith(
      hp: newHp,
      shield: newShield,
      isAlive: newHp > 0,
    );
  }

  /// 消耗护盾
  StaminaResources consumeShield(int amount) {
    return copyWith(shield: (shield - amount).clamp(0, maxShield));
  }

  // ============ 恢复 ============

  /// 自然恢复体力（每秒）
  StaminaResources restoreStamina(int amount) {
    return copyWith(stamina: (stamina + amount).clamp(0, maxStamina));
  }

  /// 恢复内力（攻击/受击时）
  StaminaResources restoreQi(int amount) {
    return copyWith(qi: (qi + amount).clamp(0, maxQi));
  }

  /// 恢复HP
  StaminaResources restoreHp(int amount) {
    return copyWith(hp: (hp + amount).clamp(0, maxHp));
  }

  /// 获得护盾
  StaminaResources addShield(int amount) {
    final newShield = (shield + amount).clamp(0, maxShield > 0 ? maxShield : amount);
    return copyWith(shield: newShield, maxShield: maxShield > 0 ? maxShield : newShield);
  }

  // ============ 闪避/格挡状态 ============

  /// 激活闪避无敌帧
  StaminaResources activateInvincible(int durationMs, int currentTimeMs) {
    return copyWith(
      isInvincible: true,
      invincibleUntilMs: currentTimeMs + durationMs,
    );
  }

  /// 清除无敌帧（时间到或被打破）
  StaminaResources deactivateInvincible() {
    return copyWith(isInvincible: false);
  }

  /// 开始格挡
  StaminaResources startBlock(int currentTimeMs) {
    return copyWith(isBlocking: true, lastBlockTimeMs: currentTimeMs);
  }

  /// 结束格挡
  StaminaResources endBlock() {
    return copyWith(isBlocking: false);
  }

  /// 判断是否在完美格挡窗口内
  bool isInPerfectBlockWindow(int currentTimeMs) {
    if (!isBlocking) return false;
    return (currentTimeMs - lastBlockTimeMs).abs() <= perfectBlockWindowMs;
  }

  // ============ 资源增减 ============

  /// 设置最大值（升级/装备）
  StaminaResources setMaxHp(int value) => copyWith(maxHp: value);
  StaminaResources setMaxStamina(int value) => copyWith(maxStamina: value);
  StaminaResources setMaxQi(int value) => copyWith(maxQi: value);
  StaminaResources setMaxShield(int value) => copyWith(maxShield: value);

  // ============ copyWith ============

  StaminaResources copyWith({
    int? hp,
    int? maxHp,
    int? stamina,
    int? maxStamina,
    int? qi,
    int? maxQi,
    int? shield,
    int? maxShield,
    bool? isInvincible,
    int? invincibleUntilMs,
    bool? isBlocking,
    int? perfectBlockWindowMs,
    int? lastBlockTimeMs,
  }) {
    return StaminaResources(
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      stamina: stamina ?? this.stamina,
      maxStamina: maxStamina ?? this.maxStamina,
      qi: qi ?? this.qi,
      maxQi: maxQi ?? this.maxQi,
      shield: shield ?? this.shield,
      maxShield: maxShield ?? this.maxShield,
      isInvincible: isInvincible ?? this.isInvincible,
      invincibleUntilMs: invincibleUntilMs ?? this.invincibleUntilMs,
      isBlocking: isBlocking ?? this.isBlocking,
      perfectBlockWindowMs: perfectBlockWindowMs ?? this.perfectBlockWindowMs,
      lastBlockTimeMs: lastBlockTimeMs ?? this.lastBlockTimeMs,
    );
  }

  @override
  List<Object?> get props => [
        hp, maxHp,
        stamina, maxStamina,
        qi, maxQi,
        shield, maxShield,
        isInvincible, invincibleUntilMs,
        isBlocking, perfectBlockWindowMs, lastBlockTimeMs,
      ];
}

/// 战斗资源系统 - 管理资源的自然恢复和定时更新
class StaminaSystem {
  StaminaResources _resources;

  // 恢复速率
  final int staminaRecoveryPerSec;
  final int qiOnHit;       // 攻击命中恢复内力
  final int qiOnDamaged;  // 受击恢复内力

  // 恢复定时器
  Timer? _recoveryTimer;
  final int _tickIntervalMs;

  StaminaSystem({
    StaminaResources? initial,
    this.staminaRecoveryPerSec = 10,
    this.qiOnHit = 5,
    this.qiOnDamaged = 3,
    int tickIntervalMs = 100,
  })  : _resources = initial ?? const StaminaResources(),
        _tickIntervalMs = tickIntervalMs;

  StaminaResources get resources => _resources;

  /// 启动自然恢复
  void startRecovery() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(
      Duration(milliseconds: _tickIntervalMs),
      (_) => _tick(),
    );
  }

  /// 停止恢复
  void stopRecovery() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  void _tick() {
    // 体力每秒自然恢复 (每tick = _tickIntervalMs ms)
    final ticksPerSec = 1000 ~/ _tickIntervalMs;
    if (ticksPerSec > 0) {
      final staminaPerTick = staminaRecoveryPerSec ~/ ticksPerSec;
      if (staminaPerTick > 0) {
        _resources = _resources.restoreStamina(staminaPerTick);
      }
    }
  }

  /// 攻击命中 → 恢复内力
  void onAttackHit(int damage) {
    _resources = _resources.restoreQi(qiOnHit);
  }

  /// 受击 → 恢复内力
  void onDamaged(int damage) {
    _resources = _resources.restoreQi(qiOnDamaged);
  }

  /// 更新资源
  void updateResources(StaminaResources resources) {
    _resources = resources;
  }

  /// 重置
  void reset({StaminaResources? initial}) {
    _resources = initial ?? const StaminaResources();
  }

  void dispose() {
    stopRecovery();
  }
}
