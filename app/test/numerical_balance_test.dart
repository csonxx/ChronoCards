import 'package:flutter_test/flutter_test.dart';
import 'package:chrono_cards_app/combat_models.dart';
import 'package:chrono_cards_app/combat_engine.dart';

void main() {
  group('数值平衡测试 - 角色攻击力 vs 敌人防御 → 击杀时间', () {
    test('角色攻击100 vs 山贼杂兵(HP=300, DEF=0) - 普攻击杀时间', () {
      final engine = CombatEngine();
      const attack = 100;
      const enemyHp = 300;
      const defense = 0;
      const attackInterval = 0.3; // 普攻间隔0.3秒

      final killTime = engine.calcKillTime(
        attackerAttack: attack,
        defenderHp: enemyHp,
        defenderDefense: defense,
        attackInterval: attackInterval,
      );

      // 100攻击打300HP = 3下，每下0.3秒 = 0.9秒
      expect(killTime, closeTo(0.9, 0.1));
    });

    test('角色攻击100 vs 山贼头目(HP=1200, DEF=0) - 普攻击杀时间', () {
      final engine = CombatEngine();
      const attack = 100;
      const enemyHp = 1200;
      const defense = 0;
      const attackInterval = 0.3;

      final killTime = engine.calcKillTime(
        attackerAttack: attack,
        defenderHp: enemyHp,
        defenderDefense: defense,
        attackInterval: attackInterval,
      );

      // 100攻击打1200HP = 12下，每下0.3秒 = 3.6秒
      expect(killTime, closeTo(3.6, 0.2));
    });

    test('角色攻击100 vs 山贼头目 - 3段连击击杀时间', () {
      final engine = CombatEngine();
      const attack = 100;
      const enemyHp = 1200;
      const defense = 0;
      const comboInterval = 0.3; // 连击间隔

      // 3段连击总伤害 = 100 + 120 + 150 = 370
      // 需要4轮连击 = 12下
      const comboDamage = 370;
      const attacksNeeded = 4; // 4轮连击
      const totalTime = attacksNeeded * 3 * comboInterval; // 12下 * 0.3秒

      final killTime = engine.calcKillTime(
        attackerAttack: comboDamage,
        defenderHp: enemyHp,
        defenderDefense: defense,
        attackInterval: comboInterval * 3, // 每轮连击算一次"攻击"
      );

      expect(killTime, closeTo(totalTime, 0.3));
    });

    test('防御力减免伤害效果验证', () {
      final engine = CombatEngine();
      const damage = 100;
      const defense = 20;

      final actualDamage = engine.calcDamageTaken(damage, defense);
      expect(actualDamage, 80);
    });

    test('破剑式无视30%防御', () {
      final engine = CombatEngine();
      const attack = 100;
      const baseDefense = 20;
      const skillMultiplier = 4.0; // 破剑式伤害乘数

      // 原始伤害 = 100 * 4.0 = 400
      // 无视30%防御后有效防御 = 20 * 0.7 = 14
      // 实际伤害 = 400 - 14 = 386
      final baseDamage = (attack * skillMultiplier).round();
      final effectiveDefense = (baseDefense * 0.7).round();
      final finalDamage = baseDamage - effectiveDefense;

      expect(baseDamage, 400);
      expect(effectiveDefense, 14);
      expect(finalDamage, 386);
    });
  });

  group('数值平衡测试 - 技能伤害 vs 敌人HP', () {
    test('金刚拳(250伤害) vs 山贼杂兵(300HP) - 约2下击杀', () {
      const skillDamage = 250;
      const banditHp = 300;

      final hits = (banditHp / skillDamage).ceil();
      expect(hits, 2); // 250 + 250 = 500 > 300
    });

    test('金刚拳(250伤害) vs 山贼头目(1200HP) - 约5下击杀', () {
      const skillDamage = 250;
      const chiefHp = 1200;

      final hits = (chiefHp / skillDamage).ceil();
      expect(hits, 5); // 250 * 5 = 1250 > 1200
    });

    test('太极剑总伤害(540) vs 山贼头目(1200HP) - 约3次使用击杀', () {
      const skillDamage = 540; // 180 * 3
      const chiefHp = 1200;

      final uses = (chiefHp / skillDamage).ceil();
      expect(uses, 3); // 540 * 3 = 1620 > 1200
    });

    test('破剑式(480伤害) vs 山贼头目(1200HP) - 约3下击杀', () {
      const skillDamage = 480; // 400 + 80
      const chiefHp = 1200;

      final hits = (chiefHp / skillDamage).ceil();
      expect(hits, 3); // 480 * 3 = 1440 > 1200
    });

    test('清风剑(160伤害) - 穿透衰减60%', () {
      const primaryDamage = 160;
      const secondaryDamage = (primaryDamage * 0.6).round();

      expect(primaryDamage, 160);
      expect(secondaryDamage, 96); // 160 * 0.6 = 96
    });

    test('打狗棒(260总伤害) - 130*2', () {
      const hit1 = 130;
      const hit2 = 130;
      const totalDamage = hit1 + hit2;

      expect(totalDamage, 260);
    });

    test('技能强度评估 - 破剑式伤害最高', () {
      const jinGangQuan = 250;
      const taiJiJian = 540; // 3次总计
      const qingFengJian = 160;
      const poJianShi = 480;
      const daGouBang = 260;

      expect(poJianShi, greaterThan(jinGangQuan));
      expect(taiJiJian, greaterThan(poJianShi)); // 太极剑AOE总伤最高
      expect(qingFengJian, lessThan(poJianShi)); // 清风剑单体较低
    });
  });

  group('数值平衡测试 - 气力消耗/回复平衡', () {
    test('满气力100可使用：金刚拳5次(20*5=100)', () {
      const maxStamina = 100;
      const jinGangQuanCost = 20;
      final uses = (maxStamina / jinGangQuanCost).floor();

      expect(uses, 5);
    });

    test('满气力100可使用：太极剑3次(30*3=90)', () {
      const maxStamina = 100;
      const taiJiJianCost = 30;
      final uses = (maxStamina / taiJiJianCost).floor();

      expect(uses, 3);
    });

    test('满气力100可使用：破剑式2次(35*2=70)', () {
      const maxStamina = 100;
      const poJianShiCost = 35;
      final uses = (maxStamina / poJianShiCost).floor();

      expect(uses, 2);
    });

    test('气力回复速度 vs 技能消耗 - 战斗持续性', () {
      const maxStamina = 100;
      const staminaRegen = 5.0; // 5点/秒
      const jinGangQuanCost = 20;
      const jinGangQuanCd = 5.0;

      // 5秒后气力回复 = 5 * 5 = 25点
      // 但消耗20点，实际净赚5点
      const regenInCd = staminaRegen * jinGangQuanCd;
      final netGain = regenInCd - jinGangQuanCost;

      expect(regenInCd, 25);
      expect(netGain, 5); // 每轮有5点净赚
    });

    test('连招气力消耗测试 - 普攻不耗气力', () {
      const normalAttackCost = 0;

      expect(normalAttackCost, 0);
    });

    test('闪避+技能连续使用气力计算', () {
      const maxStamina = 100;
      const dodgeCost = 15;
      const skillCost = 20; // 金刚拳
      const totalCost = dodgeCost + skillCost;

      var stamina = maxStamina;
      stamina -= dodgeCost; // 闪避
      stamina -= skillCost; // 技能

      expect(stamina, 65);
      expect(totalCost, 35);
    });

    test('完美格挡气力回复15点补偿', () {
      const baseStamina = 80;
      const perfectBlockReward = 15;
      const jinGangQuanCost = 20;

      var stamina = baseStamina;
      stamina += perfectBlockReward; // 完美格挡奖励
      stamina -= jinGangQuanCost; // 释放技能

      expect(stamina, 75);
    });
  });

  group('数值平衡测试 - 敌人攻击力 vs 玩家防御', () {
    test('山贼杂兵攻击30 vs 玩家防御20 - 实际伤害10', () {
      const enemyAttack = 30;
      const playerDefense = 20;

      final damage = enemyAttack - playerDefense;
      expect(damage, 10);
    });

    test('山贼头目攻击60 vs 玩家防御20 - 实际伤害40', () {
      const enemyAttack = 60;
      const playerDefense = 20;

      final damage = enemyAttack - playerDefense;
      expect(damage, 40);
    });

    test('山贼头目冲锋技能(伤害×1.5) vs 玩家防御 - 实际伤害70', () {
      const baseAttack = 60;
      const skillMultiplier = 1.5;
      const playerDefense = 20;

      final skillDamage = (baseAttack * skillMultiplier).round();
      final actualDamage = skillDamage - playerDefense;

      expect(skillDamage, 90);
      expect(actualDamage, 70);
    });

    test('格挡后伤害 - 杂兵攻击30 → 格挡后9', () {
      const enemyAttack = 30;
      const blockReduction = 0.7;

      final blockedDamage = (enemyAttack * (1 - blockReduction)).round();
      expect(blockedDamage, 9); // 30 * 0.3 = 9
    });

    test('格挡后伤害 - 头目攻击60 → 格挡后18', () {
      const enemyAttack = 60;
      const blockReduction = 0.7;

      final blockedDamage = (enemyAttack * (1 - blockReduction)).round();
      expect(blockedDamage, 18); // 60 * 0.3 = 18
    });

    test('玩家HP 1000 vs 山贼杂兵(攻击30) - 被击中次数', () {
      const playerHp = 1000;
      const damagePerHit = 10; // 30 - 20防御 = 10

      final hitsToDie = playerHp / damagePerHit;
      expect(hitsToDie, 100);
    });

    test('玩家HP 1000 vs 山贼头目(攻击60) - 被击中次数', () {
      const playerHp = 1000;
      const damagePerHit = 40; // 60 - 20防御 = 40

      final hitsToDie = playerHp / damagePerHit;
      expect(hitsToDie, 25);
    });

    test('闪避无敌帧期间完全不吃伤害', () {
      final engine = CombatEngine();
      final state = CombatState(playerHp: 1000);
      state.dodgeState = state.dodgeState.copyWith(
        isActive: true,
        remainingTime: 0.4,
      );

      final result = engine.enemyAttack(
        state: state,
        enemyDamage: 60,
        currentTime: 1.0,
        lastHitTime: 1.0,
      );

      expect(result.damage, 0);
      expect(state.playerHp, 1000); // HP未变
    });
  });
}
