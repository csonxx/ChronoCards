// ChronoCards 完整战斗系统 - ARPG v2.0
// 基于产品文档第九章：完整ARPG战斗系统
// 包含：三资源系统、武学体系、元素反应、闪避无敌帧、完美格挡/反击

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { InkProgressBar, ElementIcon } from '../ui';
import {
  type FullBattleStats,
  type FullBattleEnemy,
  type BattleUIState,
  type DodgeType,
  type ElementReactionType,
  type EnemyElementalStatus,
  type BattleResult,
  type BattleLogEntry,
  ELEMENT_REACTIONS,
  PERFECT_BLOCK_WINDOW,
  COUNTER_ATTACKS,
} from '../../types/battle';
import './battle.css';

const createMockSkills = () => ({
  inner: [
    { id: 'inner-1', name: '护体真气', type: 'inner' as const, subtype: 'qigong', costType: 'qi' as const, cost: 15, cooldown: 10, currentCooldown: 0, damage: 0, effect: { type: 'shield' as const, value: 200, duration: 5 }, description: '生成护盾吸收伤害' },
    { id: 'inner-2', name: '回元心法', type: 'inner' as const, subtype: 'qigong', costType: 'qi' as const, cost: 25, cooldown: 15, currentCooldown: 0, damage: 0, effect: { type: 'heal' as const, value: 150 }, description: '恢复生命值' },
    { id: 'inner-3', name: '寒冰诀', type: 'inner' as const, subtype: 'qigong', costType: 'qi' as const, cost: 30, cooldown: 12, currentCooldown: 0, element: 'ice' as const, effect: { type: 'element-apply' as const, element: 'ice' as const, stacks: 1 }, description: '附着冰元素' },
  ],
  outer: [
    { id: 'outer-1', name: '烈焰斩', type: 'outer' as const, subtype: 'sword', costType: 'qi' as const, cost: 20, cooldown: 5, currentCooldown: 0, damage: 150, damageMultiplier: 1.5, element: 'fire' as const, description: '火元素外功' },
    { id: 'outer-2', name: '破风剑', type: 'outer' as const, subtype: 'sword', costType: 'qi' as const, cost: 25, cooldown: 7, currentCooldown: 0, damage: 180, damageMultiplier: 1.8, element: 'wind' as const, description: '风元素外功' },
    { id: 'outer-3', name: '雷霆一击', type: 'outer' as const, subtype: 'sword', costType: 'qi' as const, cost: 40, cooldown: 15, currentCooldown: 0, damage: 300, damageMultiplier: 3, element: 'thunder' as const, description: '雷元素大招' },
    { id: 'outer-4', name: '毒砂掌', type: 'outer' as const, subtype: 'palm', costType: 'qi' as const, cost: 20, cooldown: 6, currentCooldown: 0, damage: 120, damageMultiplier: 1.2, element: 'poison' as const, description: '毒元素外功' },
  ],
  light: [
    { id: 'light-1', name: '横移闪避', type: 'side' as DodgeType, invincibleFrames: 400, distance: 80, cost: 10, cooldown: 0.8, currentCooldown: 0, description: '侧向闪避，无敌帧' },
    { id: 'light-2', name: '突进冲刺', type: 'dash' as DodgeType, invincibleFrames: 200, distance: 150, cost: 15, cooldown: 1.2, currentCooldown: 0, description: '快速接近目标' },
    { id: 'light-3', name: '蹬墙跳', type: 'wall-jump' as DodgeType, invincibleFrames: 500, distance: 120, cost: 12, cooldown: 2, currentCooldown: 0, description: '借力墙壁，变向位移' },
    { id: 'light-4', name: '凌空下击', type: 'downstrike' as DodgeType, invincibleFrames: 300, distance: 100, cost: 20, cooldown: 3, currentCooldown: 0, description: '空中蓄力下砸，高伤害' },
  ],
});

const mockEnemy: FullBattleEnemy = {
  id: 'enemy-1',
  name: '明教火焰使',
  level: 15,
  faction: 'mingjiao',
  hp: 2000,
  maxHp: 2000,
  attack: 120,
  defense: 60,
  elements: ['fire'],
  skills: [],
  position: { x: 300, y: 100 },
  behavior: 'aggressive',
  attackInterval: 2000,
  lastAttackTime: 0,
  elementalStatus: [],
};

const initialPlayerStats: FullBattleStats = {
  hp: 1500, maxHp: 1500, stamina: 100, maxStamina: 100, qi: 100, maxQi: 100,
  level: 15, attack: 180, defense: 80, elementMastery: 50, criticalRate: 0.15, criticalDamage: 2.0,
  innerSkills: [], outerSkills: [], lightSkills: [], playerElements: [],
  swordIntent: 0, maxSwordIntent: 100, perfectBlockAvailable: false, lastBlockTime: 0, comboCount: 0, comboTimer: 0,
};

interface BattleProps {
  enemy?: FullBattleEnemy;
  onVictory: (result: BattleResult) => void;
  onDefeat: () => void;
}

let effectCounter = 0;

export const Battle: React.FC<BattleProps> = ({ enemy = mockEnemy, onVictory, onDefeat }) => {
  const skills = createMockSkills();
  const [playerStats, setPlayerStats] = useState<FullBattleStats>({ ...initialPlayerStats, innerSkills: skills.inner, outerSkills: skills.outer, lightSkills: skills.light });
  const [enemyHp, setEnemyHp] = useState(enemy.maxHp);
  const [enemyElementalStatus, setEnemyElementalStatus] = useState<EnemyElementalStatus[]>([]);
  const [isAttacking, setIsAttacking] = useState(false);

  const [battleState, setBattleState] = useState<BattleUIState>({
    playerStats, enemies: [{ ...enemy }], inBattle: true, battleStartTime: Date.now(), battleDuration: 0,
    comboStage: 1, maxCombo: 0, currentDodge: null, isInvincible: false, invincibleEndTime: 0,
    isBlocking: false, isPerfectBlock: false, perfectBlockEndTime: 0,
    activeReactions: [], damageNumbers: [], activeEffects: [], battleLog: [],
  });

  const [innerCooldowns, setInnerCooldowns] = useState<number[]>(skills.inner.map(() => 0));
  const [outerCooldowns, setOuterCooldowns] = useState<number[]>(skills.outer.map(() => 0));
  const [lightCooldowns, setLightCooldowns] = useState<number[]>(skills.light.map(() => 0));

  const lastAttackTime = useRef(0);
  const battleStartTime = useRef(Date.now());
  const statsRef = useRef(playerStats);
  const enemyHpRef = useRef(enemyHp);
  const comboCountRef = useRef(0);
  const maxComboRef = useRef(0);
  const battleStateRef = useRef(battleState);
  statsRef.current = playerStats;
  enemyHpRef.current = enemyHp;
  battleStateRef.current = battleState;

  const addBattleLog = useCallback((type: BattleLogEntry['type'], message: string, value?: number) => {
    setBattleState(prev => ({ ...prev, battleLog: [...prev.battleLog.slice(-50), { timestamp: Date.now(), type, message, value }] }));
  }, []);

  const showDamageNumber = useCallback((value: number, isCrit: boolean, isPlayer: boolean) => {
    const id = `dmg-${Date.now()}-${Math.random()}`;
    setBattleState(prev => ({ ...prev, damageNumbers: [...prev.damageNumbers, { id, value, isCrit, isPlayer, x: 300, y: 100 }] }));
    setTimeout(() => { setBattleState(prev => ({ ...prev, damageNumbers: prev.damageNumbers.filter(d => d.id !== id) })); }, 800);
  }, []);

  const showEffect = useCallback((type: string, x: number, y: number) => {
    const id = `effect-${++effectCounter}`;
    setBattleState(prev => ({ ...prev, activeEffects: [...prev.activeEffects, { id, type, x, y, duration: 600 }] }));
    setTimeout(() => { setBattleState(prev => ({ ...prev, activeEffects: prev.activeEffects.filter(e => e.id !== id) })); }, 600);
  }, []);

  const checkElementReactions = useCallback((playerElement: any, enemyElements: EnemyElementalStatus[]) => {
    if (!playerElement || enemyElements.length === 0) return null;
    for (const [reactionType, reaction] of Object.entries(ELEMENT_REACTIONS)) {
      const [elem1, elem2] = reaction.trigger;
      const enemyHasElement = enemyElements.some(e => e.element === elem1 || e.element === elem2);
      const playerHasElement = playerElement === elem1 || playerElement === elem2;
      if (enemyHasElement && playerHasElement) {
        setEnemyElementalStatus(prev => prev.filter(e => e.element !== elem1 && e.element !== elem2));
        addBattleLog('reaction', reaction.description, reaction.damage);
        setBattleState(prev => ({ ...prev, activeReactions: [...prev.activeReactions.slice(-5), { type: reactionType as ElementReactionType, damage: reaction.damage, timestamp: Date.now() }] }));
        return { damage: reaction.damage };
      }
    }
    return null;
  }, [addBattleLog]);

  const handleAttack = useCallback(() => {
    const now = Date.now();
    if (now - lastAttackTime.current < 300) return;
    lastAttackTime.current = now;
    setIsAttacking(true);
    setTimeout(() => setIsAttacking(false), 200);
    const stats = statsRef.current;
    const multipliers = [0.4, 0.6, 1.0];
    const comboStage = battleStateRef.current.comboStage;
    const damage = Math.floor(stats.attack * multipliers[comboStage - 1]);
    const isCrit = Math.random() < stats.criticalRate;
    const finalDamage = isCrit ? Math.floor(damage * stats.criticalDamage) : damage;
    const actualDamage = Math.max(1, finalDamage - enemy.defense);
    setEnemyHp(prev => Math.max(0, prev - actualDamage));
    showDamageNumber(actualDamage, isCrit, false);
    setPlayerStats(prev => ({ ...prev, swordIntent: Math.min(prev.maxSwordIntent, prev.swordIntent + 5), qi: Math.min(prev.maxQi, prev.qi + 3), comboCount: prev.comboCount + 1, comboTimer: 3 }));
    comboCountRef.current += 1;
    maxComboRef.current = Math.max(maxComboRef.current, comboCountRef.current);
    const newComboStage = comboStage === 3 ? 1 : (comboStage + 1) as 1 | 2 | 3;
    setBattleState(prev => ({ ...prev, comboStage: newComboStage, maxCombo: maxComboRef.current }));
    addBattleLog('damage', `普攻第${comboStage}段`, actualDamage);
    if (enemyHpRef.current - actualDamage <= 0) {
      const result: BattleResult = { victory: true, duration: Date.now() - battleStartTime.current, damageDealt: actualDamage, damageTaken: 0, maxCombo: maxComboRef.current, perfectBlocks: 0, reactionsTriggered: battleStateRef.current.activeReactions.length, skillsUsed: 0 };
      setTimeout(() => onVictory(result), 500);
    }
  }, [showDamageNumber, addBattleLog, onVictory]);

  const handleBlock = useCallback((start: boolean) => {
    if (start && playerStats.stamina >= 15) {
      const blockTime = Date.now();
      setBattleState(prev => ({ ...prev, isBlocking: true, lastBlockTime: blockTime }));
      setPlayerStats(prev => ({ ...prev, stamina: prev.stamina - 15, perfectBlockAvailable: true, lastBlockTime: blockTime }));
      setTimeout(() => { setPlayerStats(prev => ({ ...prev, perfectBlockAvailable: false })); }, PERFECT_BLOCK_WINDOW.endMs);
    } else {
      setBattleState(prev => ({ ...prev, isBlocking: false, isPerfectBlock: false }));
    }
  }, [playerStats.stamina]);

  const handleDodge = useCallback((dodgeType: DodgeType, index: number) => {
    const dodge = skills.light[index];
    if (!dodge || lightCooldowns[index] > 0 || playerStats.stamina < dodge.cost) return;
    setPlayerStats(prev => ({ ...prev, stamina: prev.stamina - dodge.cost, swordIntent: Math.min(prev.maxSwordIntent, prev.swordIntent + 3) }));
    setLightCooldowns(prev => { const nc = [...prev]; nc[index] = dodge.cooldown; return nc; });
    setBattleState(prev => ({ ...prev, currentDodge: dodgeType, isInvincible: true, invincibleEndTime: Date.now() + dodge.invincibleFrames }));
    showEffect(`dodge-${dodgeType}`, 200, 200);
    addBattleLog('dodge', `使用${dodge.name}，无敌帧${dodge.invincibleFrames}ms`);
    setTimeout(() => { setBattleState(prev => ({ ...prev, isInvincible: false, currentDodge: null })); }, dodge.invincibleFrames);
  }, [playerStats.stamina, lightCooldowns, skills.light, showEffect, addBattleLog]);

  const handleInnerSkill = useCallback((index: number) => {
    const skill = skills.inner[index];
    if (!skill || innerCooldowns[index] > 0 || playerStats.qi < skill.cost) return;
    setPlayerStats(prev => ({ ...prev, qi: prev.qi - skill.cost }));
    setInnerCooldowns(prev => { const nc = [...prev]; nc[index] = skill.cooldown; return nc; });
    if (skill.effect) {
      switch (skill.effect.type) {
        case 'heal': setPlayerStats(prev => ({ ...prev, hp: Math.min(prev.maxHp, prev.hp + skill.effect!.value!) })); addBattleLog('heal', `使用${skill.name}，恢复${skill.effect.value}生命`); break;
        case 'shield': setPlayerStats(prev => ({ ...prev, defense: prev.defense + skill.effect!.value! })); addBattleLog('skill', `使用${skill.name}，护盾+${skill.effect.value}`); setTimeout(() => { setPlayerStats(prev => ({ ...prev, defense: prev.defense - skill.effect!.value! })); }, (skill.effect.duration || 5) * 1000); break;
        case 'element-apply': setBattleState(prev => ({ ...prev, playerStats: { ...prev.playerStats, playerElements: [...prev.playerStats.playerElements.slice(-3), { element: skill.effect!.element!, stacks: skill.effect!.stacks || 1, duration: 8, source: 'player' }] } })); addBattleLog('skill', `使用${skill.name}，附着${skill.effect.element}元素`); break;
      }
    }
    showEffect(`inner-${skill.subtype}`, 200, 200);
  }, [skills.inner, innerCooldowns, playerStats.qi, showEffect, addBattleLog]);

  const handleOuterSkill = useCallback((index: number) => {
    const skill = skills.outer[index];
    if (!skill || outerCooldowns[index] > 0 || playerStats.qi < skill.cost) return;
    setPlayerStats(prev => ({ ...prev, qi: prev.qi - skill.cost, swordIntent: Math.min(prev.maxSwordIntent, prev.swordIntent + 10) }));
    setOuterCooldowns(prev => { const nc = [...prev]; nc[index] = skill.cooldown; return nc; });
    const baseDamage = skill.damage || (playerStats.attack * (skill.damageMultiplier || 1));
    const isCrit = Math.random() < playerStats.criticalRate;
    const finalDamage = isCrit ? Math.floor(baseDamage * playerStats.criticalDamage) : baseDamage;
    const actualDamage = Math.max(1, finalDamage - enemy.defense);
    setEnemyHp(prev => Math.max(0, prev - actualDamage));
    showDamageNumber(actualDamage, isCrit, false);
    showEffect(`outer-${skill.subtype}-${skill.element || 'default'}`, 300, 100);
    if (skill.element) {
      const newStatus: EnemyElementalStatus = { element: skill.element, stacks: 1, duration: 5, source: 'player' };
      setEnemyElementalStatus(prev => [...prev.slice(-3), newStatus]);
      const reactionResult = checkElementReactions(skill.element, enemyElementalStatus);
      if (reactionResult) { setEnemyHp(prev => Math.max(0, prev - reactionResult.damage)); showDamageNumber(reactionResult.damage, false, false); }
    }
    addBattleLog('skill', `使用${skill.name}，伤害${actualDamage}`, actualDamage);
    if (enemyHpRef.current - actualDamage <= 0) {
      const result: BattleResult = { victory: true, duration: Date.now() - battleStartTime.current, damageDealt: actualDamage, damageTaken: 0, maxCombo: maxComboRef.current, perfectBlocks: 0, reactionsTriggered: battleStateRef.current.activeReactions.length, skillsUsed: 1 };
      setTimeout(() => onVictory(result), 500);
    }
  }, [skills.outer, outerCooldowns, playerStats, enemy, enemyElementalStatus, showDamageNumber, showEffect, checkElementReactions, addBattleLog, onVictory]);

  const handleCounterAttack = useCallback(() => {
    if (!playerStats.perfectBlockAvailable) return;
    const counter = COUNTER_ATTACKS[0];
    const damage = Math.floor(playerStats.attack * counter.damageMultiplier);
    const actualDamage = Math.max(1, damage - enemy.defense);
    setEnemyHp(prev => Math.max(0, prev - actualDamage));
    showDamageNumber(actualDamage, false, false);
    showEffect('counter-attack', 300, 100);
    setPlayerStats(prev => ({ ...prev, perfectBlockAvailable: false }));
    addBattleLog('counter', `完美反击！伤害${actualDamage}`, actualDamage);
    if (enemyHpRef.current - actualDamage <= 0) {
      const result: BattleResult = { victory: true, duration: Date.now() - battleStartTime.current, damageDealt: actualDamage, damageTaken: 0, maxCombo: maxComboRef.current, perfectBlocks: 1, reactionsTriggered: 0, skillsUsed: 0 };
      setTimeout(() => onVictory(result), 500);
    }
  }, [playerStats.perfectBlockAvailable, playerStats.attack, enemy, showDamageNumber, showEffect, addBattleLog, onVictory]);

  useEffect(() => {
    const interval = setInterval(() => {
      const delta = 0.1;
      setInnerCooldowns(prev => prev.map(c => Math.max(0, c - delta)));
      setOuterCooldowns(prev => prev.map(c => Math.max(0, c - delta)));
      setLightCooldowns(prev => prev.map(c => Math.max(0, c - delta)));
    }, 100);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setPlayerStats(prev => {
        const newComboTimer = prev.comboTimer - 0.1;
        return { ...prev, stamina: Math.min(prev.maxStamina, prev.stamina + 3), qi: Math.min(prev.maxQi, prev.qi + 2), comboTimer: Math.max(0, newComboTimer), comboCount: newComboTimer <= 0 ? 0 : prev.comboCount };
      });
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setEnemyElementalStatus(prev => prev.map(e => ({ ...e, duration: e.duration - 0.1 })).filter(e => e.duration > 0));
      setBattleState(prev => ({ ...prev, playerStats: { ...prev.playerStats, playerElements: prev.playerStats.playerElements.map(e => ({ ...e, duration: e.duration - 0.1 })).filter(e => e.duration > 0) } }));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      const now = Date.now();
      if (now - enemy.lastAttackTime < enemy.attackInterval) return;
      const damage = enemy.attack + Math.floor(Math.random() * 30);
      const currentBattleState = battleStateRef.current;
      const currentStats = statsRef.current;
      if (currentBattleState.isInvincible) { showDamageNumber(0, false, true); addBattleLog('dodge', '闪避成功！'); }
      else if (currentBattleState.isBlocking) {
        const timeSinceBlock = now - currentBattleState.lastBlockTime;
        if (timeSinceBlock >= PERFECT_BLOCK_WINDOW.startMs && timeSinceBlock <= PERFECT_BLOCK_WINDOW.endMs) {
          setBattleState(prev => ({ ...prev, isPerfectBlock: true })); showDamageNumber(0, false, true); addBattleLog('perfect-block', '完美格挡！');
          setTimeout(() => setBattleState(prev => ({ ...prev, isPerfectBlock: false })), 300);
        } else { const blockedDamage = Math.floor(damage * 0.3); setPlayerStats(prev => ({ ...prev, hp: Math.max(0, prev.hp - blockedDamage), stamina: Math.max(0, prev.stamina - 10) })); showDamageNumber(blockedDamage, false, true); addBattleLog('block', `格挡成功，伤害${blockedDamage}`); }
      } else { setPlayerStats(prev => ({ ...prev, hp: Math.max(0, prev.hp - damage), qi: Math.min(prev.maxQi, prev.qi + 5) })); showDamageNumber(damage, false, true); addBattleLog('damage', `受到攻击，伤害${damage}`, damage); }
      setBattleState(prev => ({ ...prev, enemies: prev.enemies.map(e => ({ ...e, lastAttackTime: now })) }));
      if (currentStats.hp - damage <= 0) { clearInterval(interval); onDefeat(); }
    }, 100);
    return () => clearInterval(interval);
  }, [enemy, showDamageNumber, addBattleLog, onDefeat]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!battleState.inBattle) return;
      switch (e.key.toLowerCase()) {
        case 'j': case ' ': handleAttack(); break;
        case 'k': handleBlock(true); break;
        case 'l': handleDodge('side', 0); break;
        case ';': handleDodge('dash', 1); break;
        case '\'': handleDodge('wall-jump', 2); break;
        case 'u': handleInnerSkill(0); break;
        case 'i': handleInnerSkill(1); break;
        case 'o': handleInnerSkill(2); break;
        case 'z': handleOuterSkill(0); break;
        case 'x': handleOuterSkill(1); break;
        case 'c': handleOuterSkill(2); break;
        case 'v': handleOuterSkill(3); break;
        case 'q': handleCounterAttack(); break;
      }
    };
    const handleKeyUp = (e: KeyboardEvent) => { if (e.key.toLowerCase() === 'k') handleBlock(false); };
    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    return () => { window.removeEventListener('keydown', handleKeyDown); window.removeEventListener('keyup', handleKeyUp); };
  }, [battleState.inBattle, handleAttack, handleBlock, handleDodge, handleInnerSkill, handleOuterSkill, handleCounterAttack]);

  const getCooldownPercent = (cd: number, max: number) => (cd / max) * 100;
  const getElementIcon = (element: string) => { const icons: Record<string, string> = { fire: '🔥', water: '💧', wind: '🌪️', thunder: '⚡', ice: '❄️', poison: '☠️' }; return icons[element] || '💫'; };

  return (
    <div className={`battle-arena ${battleState.isInvincible ? 'battle-arena--invincible' : ''} ${isAttacking ? 'battle-arena--attacking' : ''}`}>
      <div className="battle-background"><div className="ink-wave ink-wave--1" /><div className="ink-wave ink-wave--2" /><div className="ink-wave ink-wave--3" /></div>
      <div className="battle-player-status">
        <div className="player-avatar" />
        <div className="player-info"><div className="player-info__name">江湖游侠</div><div className="player-info__level">Lv.{playerStats.level}</div><InkProgressBar value={playerStats.hp} max={playerStats.maxHp} color="hp" size="md" showLabel /></div>
        <div className="player-elements">{playerStats.playerElements.map((e, i) => (<div key={i} className="element-status"><ElementIcon element={e.element} size="sm" /><span className="element-stacks">×{e.stacks}</span></div>))}</div>
      </div>
      <div className="battle-enemies">
        <div className="enemy-container">
          <div className="enemy-scroll">
            <div className="enemy-rod enemy-rod--top" />
            <div className="enemy-content">
              <div className="enemy-avatar">🔥</div>
              <div className="enemy-info">
                <div className="enemy-name">{enemy.name}</div><div className="enemy-level">Lv.{enemy.level}</div>
                <InkProgressBar value={enemyHp} max={enemy.maxHp} color="hp" size="sm" showLabel />
                <div className="enemy-elements">{enemy.elements.map((e, i) => <ElementIcon key={i} element={e} size="sm" />)}</div>
                <div className="enemy-elemental-status">{enemyElementalStatus.map((e, i) => (<div key={i} className="element-timer"><ElementIcon element={e.element} size="sm" /><span className="element-duration">{e.duration.toFixed(1)}s</span></div>))}</div>
              </div>
            </div>
            <div className="enemy-rod enemy-rod--bottom" />
          </div>
          {battleState.damageNumbers.filter(d => !d.isPlayer).map(dmg => (<div key={dmg.id} className={`damage-number ${dmg.isCrit ? 'damage-number--crit' : ''}`}>{dmg.isCrit ? '💥 ' : ''}{dmg.value}</div>))}
        </div>
      </div>
      <div className="battle-scene">
        <div className={`player-character ${isAttacking ? 'player-character--attack' : ''} ${battleState.isInvincible ? 'player-character--invincible' : ''}`}>
          <div className="character-sprite">🧑</div><div className="character-shadow" />
          {battleState.isInvincible && <div className="invincible-flash" />}
        </div>
        {battleState.damageNumbers.filter(d => d.isPlayer).map(dmg => (<div key={dmg.id} className="player-damage">{dmg.value === 0 ? '闪避!' : `-${dmg.value}`}</div>))}
        <div className="battle-effect-layer">{battleState.activeEffects.map(effect => (<div key={effect.id} className={`effect-${effect.type}`} style={{ left: effect.x - 60, top: effect.y - 60 }} />))}</div>
      </div>
      <div className="battle-resources">
        <div className="resource-row"><span className="resource-label">生命</span><div className="resource-bar-wrapper"><InkProgressBar value={playerStats.hp} max={playerStats.maxHp} color="hp" size="sm" /></div><span className="resource-value">{playerStats.hp}/{playerStats.maxHp}</span></div>
        <div className="resource-row"><span className="resource-label">体力</span><div className="resource-bar-wrapper"><InkProgressBar value={playerStats.stamina} max={playerStats.maxStamina} color="stamina" size="sm" /></div><span className="resource-value">{playerStats.stamina}/{playerStats.maxStamina}</span></div>
        <div className="resource-row"><span className="resource-label">内力</span><div className="resource-bar-wrapper"><InkProgressBar value={playerStats.qi} max={playerStats.maxQi} color="qi" size="sm" /></div><span className="resource-value">{playerStats.qi}/{playerStats.maxQi}</span></div>
        <div className="resource-row"><span className="resource-label">剑意</span><div className="resource-bar-wrapper"><InkProgressBar value={playerStats.swordIntent} max={playerStats.maxSwordIntent} color="sword-intent" size="sm" /></div><span className="resource-value">{playerStats.swordIntent}/{playerStats.maxSwordIntent}</span></div>
      </div>
      <div className="combo-indicator">
        <div className={`combo-box combo-box--${battleState.comboStage}`}><span className="combo-number">{battleState.comboStage}</span></div>
        {battleState.comboCount > 1 && <div className="combo-count">连击×{battleState.comboCount}</div>}
      </div>
      {battleState.isPerfectBlock && <div className="perfect-block-effect"><span className="perfect-text">完美!</span></div>}
      {battleState.activeReactions.length > 0 && (<div className="reaction-display">{battleState.activeReactions.slice(-3).map((r, i) => (<div key={i} className={`reaction-badge reaction-badge--${r.type}`}>{ELEMENT_REACTIONS[r.type]?.description?.split('：')[0] || r.type}</div>))}</div>)}
      <div className="battle-controls battle-controls--light"><div className="control-group-label">轻功</div>{skills.light.map((dodge, i) => (<button key={dodge.id} className={`battle-btn battle-btn--dodge battle-btn--light battle-btn--${dodge.type} ${lightCooldowns[i] > 0 ? 'battle-btn--cooldown' : ''}`} onClick={() => handleDodge(dodge.type, i)} disabled={lightCooldowns[i] > 0 || playerStats.stamina < dodge.cost} title={dodge.description}><div className="skill-cooldown-ring" style={{ '--progress': `${getCooldownPercent(lightCooldowns[i], dodge.cooldown)}%` } as React.CSSProperties} /><span className="btn-icon">{i === 0 ? '🏃' : i === 1 ? '⚡' : i === 2 ? '🧗' : '⬇️'}</span><span className="btn-label">{dodge.name}</span><span className="btn-cost">-{dodge.cost}</span></button>))}</div>
      <div className="battle-controls battle-controls--attack"><button className={`battle-btn battle-btn--attack ${isAttacking ? 'battle-btn--active' : ''}`} onClick={handleAttack}><span className="btn-icon">⚔️</span><span className="btn-label">攻击</span><span className="btn-combo">×{battleState.comboStage}</span></button></div>
      <div className="battle-controls battle-controls--inner"><div className="control-group-label">内功</div>{skills.inner.map((skill, i) => (<button key={skill.id} className={`battle-btn battle-btn--inner ${innerCooldowns[i] > 0 ? 'battle-btn--cooldown' : ''}`} onClick={() => handleInnerSkill(i)} disabled={innerCooldowns[i] > 0 || playerStats.qi < skill.cost} title={skill.description}><div className="skill-cooldown-ring" style={{ '--progress': `${getCooldownPercent(innerCooldowns[i], skill.cooldown)}%` } as React.CSSProperties} /><span className="btn-icon">🛡️</span><span className="btn-label">{skill.name}</span><span className="btn-cost">-{skill.cost}</span></button>))}</div>
      <div className="battle-controls battle-controls--outer"><div className="control-group-label">外功</div>{skills.outer.map((skill, i) => (<button key={skill.id} className={`battle-btn battle-btn--skill ${outerCooldowns[i] > 0 ? 'battle-btn--cooldown' : ''}`} onClick={() => handleOuterSkill(i)} disabled={outerCooldowns[i] > 0 || playerStats.qi < skill.cost} title={skill.description}><div className="skill-cooldown-ring" style={{ '--progress': `${getCooldownPercent(outerCooldowns[i], skill.cooldown)}%` } as React.CSSProperties} /><span className="btn-icon">{getElementIcon(skill.element || '')}</span><span className="btn-label">{skill.name}</span><span className="btn-cost">-{skill.cost}</span></button>))}</div>
      <div className="battle-controls battle-controls--block">
        <button className={`battle-btn battle-btn--block ${battleState.isBlocking ? 'battle-btn--active' : ''}`} onMouseDown={() => handleBlock(true)} onMouseUp={() => handleBlock(false)} onMouseLeave={() => handleBlock(false)} disabled={playerStats.stamina < 15}><span className="btn-icon">🛡️</span><span className="btn-label">格挡</span><span className="btn-cost">-15</span></button>
        {playerStats.perfectBlockAvailable && <button className="battle-btn battle-btn--counter" onClick={handleCounterAttack}><span className="btn-icon">⚡</span><span className="btn-label">反击</span></button>}
      </div>
      <div className="battle-hints"><span>J/空格 攻击</span><span>K 长按 格挡</span><span>L/;/' 闪避</span><span>U/I/O 内功</span><span>Z/X/C/V 外功</span><span>Q 反击</span></div>
    </div>
  );
};

export default Battle;
