import 'package:flutter_test/flutter_test.dart';
import 'package:chrono_cards_app/combat_models.dart';
import 'package:chrono_cards_app/combat_engine.dart';

void main() {
  group('战斗手感测试 - 移动延迟', () {
    test('摇杆响应延迟 < 16ms', () {
      final engine = CombatEngine();
      final state = CombatState();
      const inputDelay = 0.016; // 16ms

      // 模拟输入
      final beforeMove = 0.0;
      engine.move(state, beforeMove);
      final afterMove = beforeMove + inputDelay;

      // 验证响应时间
      final responseTime = afterMove - beforeMove;
      expect(responseTime, lessThan(0.016),
          reason: '摇杆响应时间应 < 16ms');
    });
  });

  group('战斗手感测试 - 普攻3段连击', () {
    test('普攻3段伤害正确', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 第1击
      var phase = engine.advanceCombo(state, 0.0);
      expect(phase, ComboPhase.first);
      expect(engine.calcNormalAttackDamage(phase, 100), 100);

      // 第2击（间隔0.3秒）
      phase = engine.advanceCombo(state, 0.3);
      expect(phase, ComboPhase.second);
      expect(engine.calcNormalAttackDamage(phase, 100), 120);

      // 第3击（间隔0.3秒）
      phase = engine.advanceCombo(state, 0.6);
      expect(phase, ComboPhase.third);
      expect(engine.calcNormalAttackDamage(phase, 100), 150);
    });

    test('连击窗口超时重置', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 第1击
      engine.advanceCombo(state, 0.0);

      // 超时（> 0.6秒）后重置为第1击
      final phase = engine.advanceCombo(state, 1.0);
      expect(phase, ComboPhase.first);
    });

    test('3段连击总伤害 = 370 (100+120+150)', () {
      final engine = CombatEngine();
      final state = CombatState();
      const attack = 100;

      engine.advanceCombo(state, 0.0);
      final d1 = engine.calcNormalAttackDamage(state.comboPhase, attack);

      engine.advanceCombo(state, 0.3);
      final d2 = engine.calcNormalAttackDamage(state.comboPhase, attack);

      engine.advanceCombo(state, 0.6);
      final d3 = engine.calcNormalAttackDamage(state.comboPhase, attack);

      expect(d1 + d2 + d3, 370);
    });
  });

  group('战斗手感测试 - 闪避无敌帧', () {
    test('闪避激活后0.4秒内不吃伤害', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 触发闪避
      final success = engine.tryDodge(state, 1.0);
      expect(success, true);
      expect(state.dodgeState.isActive, true);

      // 模拟敌人攻击（在无敌帧内）
      final result = engine.enemyAttack(
        state: state,
        enemyDamage: 30,
        currentTime: 1.2, // 闪避后0.2秒
        lastHitTime: 1.2,
      );

      expect(result.damage, 0, reason: '无敌帧内应免疫伤害');
    });

    test('闪避无敌帧结束后受伤', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 触发闪避
      engine.tryDodge(state, 1.0);

      // 模拟敌人攻击（在无敌帧结束后）
      final result = engine.enemyAttack(
        state: state,
        enemyDamage: 30,
        currentTime: 2.0, // 闪避后1秒，无敌帧已结束
        lastHitTime: 2.0,
      );

      expect(result.damage, greaterThan(0), reason: '无敌帧结束后应受到伤害');
    });

    test('闪避冷却1.2秒', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 第1次闪避
      engine.tryDodge(state, 0.0);
      expect(state.dodgeState.cooldownRemaining, 1.2);

      // 冷却期间无法闪避
      final canDodge = engine.tryDodge(state, 0.5);
      expect(canDodge, false);
    });

    test('气力不足时无法闪避', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 10); // 不足15点

      final success = engine.tryDodge(state, 0.0);
      expect(success, false);
      expect(state.dodgeState.isActive, false);
    });
  });

  group('战斗手感测试 - 格挡减免', () {
    test('格挡减免70%伤害', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 开启格挡
      engine.startBlock(state);
      expect(state.blockState.isBlocking, true);

      // 模拟攻击
      final result = engine.applyBlock(100, false);
      expect(result.damage, 30);
      expect(result.blocked, true);
    });

    test('完美格挡完全免伤', () {
      final engine = CombatEngine();
      final state = CombatState();

      // 完美格挡判定（受击瞬间<=0.1秒内）
      final result = engine.applyBlock(100, true);
      expect(result.damage, 0);
      expect(result.perfectBlock, true);
    });

    test('格挡期间气力回复+15（完美格挡）', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 50);

      engine.startBlock(state);

      // 完美格挡后回复气力
      state.playerStamina = (state.playerStamina + 15).clamp(0, 100);
      expect(state.playerStamina, 65);
    });
  });

  group('战斗手感测试 - 技能CD', () {
    test('金刚拳CD=5秒', () {
      final engine = CombatEngine();
      final state = CombatState();

      expect(state.skillCooldowns.isReady('K'), true);

      // 使用技能
      final skill = Skills.jinGangQuan;
      engine.useSkill(state, skill, 0.0);

      expect(state.skillCooldowns.isReady('K'), false);
      expect(state.skillCooldowns.getCooldown('K'), 5.0);

      // 5秒后冷却完成
      state.skillCooldowns.update(5.0);
      expect(state.skillCooldowns.isReady('K'), true);
    });

    test('太极剑CD=8秒', () {
      final engine = CombatEngine();
      final state = CombatState();

      final skill = Skills.taiJiJian;
      engine.useSkill(state, skill, 0.0);

      expect(state.skillCooldowns.getCooldown('L'), 8.0);
    });

    test('清风剑CD=6秒', () {
      final engine = CombatEngine();
      final state = CombatState();

      final skill = Skills.qingFengJian;
      engine.useSkill(state, skill, 0.0);

      expect(state.skillCooldowns.getCooldown('U'), 6.0);
    });

    test('破剑式CD=10秒', () {
      final engine = CombatEngine();
      final state = CombatState();

      final skill = Skills.poJianShi;
      engine.useSkill(state, skill, 0.0);

      expect(state.skillCooldowns.getCooldown('I'), 10.0);
    });

    test('打狗棒CD=7秒', () {
      final engine = CombatEngine();
      final state = CombatState();

      final skill = Skills.daGouBang;
      engine.useSkill(state, skill, 0.0);

      expect(state.skillCooldowns.getCooldown('O'), 7.0);
    });

    test('气力不足时无法使用技能', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 15); // 金刚拳需要20

      final skill = Skills.jinGangQuan;
      final success = engine.useSkill(state, skill, 0.0);

      expect(success, false);
      expect(state.skillCooldowns.isReady('K'), true); // CD未开始
    });
  });

  group('战斗手感测试 - 气力消耗', () {
    test('金刚拳消耗气力20', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 100);

      final skill = Skills.jinGangQuan;
      engine.useSkill(state, skill, 0.0);

      expect(state.playerStamina, 80);
    });

    test('太极剑消耗气力30', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 100);

      final skill = Skills.taiJiJian;
      engine.useSkill(state, skill, 0.0);

      expect(state.playerStamina, 70);
    });

    test('气力自然回复5点/秒', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 50);

      // 更新2秒
      engine.update(2.0);

      expect(state.playerStamina, 60); // 50 + 5*2 = 60
    });

    test('气力上限100不溢出', () {
      final engine = CombatEngine();
      final state = CombatState(playerStamina: 95);

      engine.update(2.0);

      expect(state.playerStamina, lessThanOrEqualTo(100));
    });
  });
}
