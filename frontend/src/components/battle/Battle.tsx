// S5: 战斗界面 - 即时ARPG

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { InkProgressBar, ElementIcon } from '../ui';
import type { BattleStats, ElementalStatus, BattleEnemy, Skill } from '../../types';
import './battle.css';

// 模拟敌人数据
const mockEnemy: BattleEnemy = {
  id: 'enemy-1',
  name: '明教弟子',
  level: 12,
  faction: 'mingjiao',
  hp: 1200,
  maxHp: 1200,
  elements: ['fire'],
  skills: [],
  position: { x: 300, y: 100 },
};

// 模拟技能数据
const mockSkills: Skill[] = [
  { id: 's1', name: '烈焰斩', type: 'E', cooldown: 5, currentCooldown: 0, cost: 20 },
  { id: 's2', name: '火云掌', type: 'E', cooldown: 8, currentCooldown: 0, cost: 30 },
  { id: 's3', name: '灼热爆发', type: 'Q', cooldown: 20, currentCooldown: 0, cost: 50 },
];

interface BattleProps {
  enemy?: BattleEnemy;
  onVictory: () => void;
  onDefeat: () => void;
}

export const Battle: React.FC<BattleProps> = ({
  enemy = mockEnemy,
  onVictory,
  onDefeat,
}) => {
  // 玩家战斗状态
  const [playerStats, setPlayerStats] = useState<BattleStats>({
    hp: 1000,
    maxHp: 1000,
    stamina: 100,
    maxStamina: 100,
    qi: 80,
    maxQi: 80,
    swordIntent: 0,
    maxSwordIntent: 100,
    level: 12,
    attack: 150,
    defense: 80,
    elementMastery: 45,
  });

  // 敌人状态
  const [enemyHp, setEnemyHp] = useState(enemy.maxHp);

  // 战斗状态
  const [comboStage, setComboStage] = useState<1 | 2 | 3>(1);
  const [isBlocking, setIsBlocking] = useState(false);
  const [isPerfectBlock, setIsPerfectBlock] = useState(false);
  const [isInvincible, setIsInvincible] = useState(false);
  const [isAttacking, setIsAttacking] = useState(false);
  const [playerElements, setPlayerElements] = useState<ElementalStatus[]>([]);
  const [skills, setSkills] = useState(mockSkills);
  const [showDamageNumber, setShowDamageNumber] = useState<{ value: number; isCrit: boolean } | null>(null);
  const [enemyShowDamage, setEnemyShowDamage] = useState<{ value: number; isCrit: boolean } | null>(null);

  const battleRef = useRef<HTMLDivElement>(null);
  const lastAttackTime = useRef(0);

  // 普通攻击
  const handleAttack = useCallback(() => {
    const now = Date.now();
    if (now - lastAttackTime.current < 300) return;
    lastAttackTime.current = now;

    setIsAttacking(true);
    setTimeout(() => setIsAttacking(false), 200);

    // 伤害计算（基于连击阶段）
    const baseDamage = playerStats.attack;
    const multipliers = [0.4, 0.6, 1.0];
    const damage = Math.floor(baseDamage * multipliers[comboStage - 1]);
    const isCrit = Math.random() < 0.15;
    const finalDamage = isCrit ? Math.floor(damage * 2) : damage;

    // 敌人受伤
    setEnemyHp(prev => Math.max(0, prev - finalDamage));
    setEnemyShowDamage({ value: finalDamage, isCrit });

    // 剑意积累
    setPlayerStats(prev => ({
      ...prev,
      swordIntent: Math.min(prev.maxSwordIntent, prev.swordIntent + 5),
      qi: Math.min(prev.maxQi, prev.qi + 3),
    }));

    // 连击阶段推进
    setComboStage(prev => (prev === 3 ? 1 : (prev + 1) as 1 | 2 | 3));

    // 显示伤害数字
    setTimeout(() => setEnemyShowDamage(null), 800);

    // 检查胜利
    if (enemyHp - finalDamage <= 0) {
      setTimeout(onVictory, 500);
    }
  }, [comboStage, playerStats, enemyHp, onVictory]);

  // 格挡
  const handleBlock = useCallback((start: boolean) => {
    if (start && playerStats.stamina >= 15) {
      setIsBlocking(true);
      // 完美格挡检测
      setTimeout(() => {
        setIsPerfectBlock(true);
        setPlayerStats(prev => ({
          ...prev,
          stamina: prev.stamina - 5, // 完美格挡消耗减半
          swordIntent: Math.min(prev.maxSwordIntent, prev.swordIntent + 15),
        }));
        setTimeout(() => setIsPerfectBlock(false), 150);
      }, 150);
    } else {
      setIsBlocking(false);
    }
  }, [playerStats.stamina]);

  // 闪避
  const handleDodge = useCallback(() => {
    if (playerStats.stamina >= 10) {
      setIsInvincible(true);
      setPlayerStats(prev => ({
        ...prev,
        stamina: prev.stamina - 10,
        swordIntent: Math.min(prev.maxSwordIntent, prev.swordIntent + 5),
      }));
      setTimeout(() => setIsInvincible(false), 400);
    }
  }, [playerStats.stamina]);

  // 技能释放
  const handleSkill = useCallback((index: number) => {
    const skill = skills[index];
    if (!skill || skill.currentCooldown > 0 || playerStats.qi < (skill.cost || 0)) return;

    setSkills(prev => prev.map((s, i) => 
      i === index ? { ...s, currentCooldown: s.cooldown } : s
    ));
    setPlayerStats(prev => ({
      ...prev,
      qi: prev.qi - (skill.cost || 0),
    }));

    // 技能伤害
    const baseDamage = playerStats.attack * (skill.type === 'Q' ? 3 : 1.5);
    const damage = Math.floor(baseDamage);
    const isCrit = Math.random() < 0.2;
    const finalDamage = isCrit ? Math.floor(damage * 2) : damage;

    setEnemyHp(prev => Math.max(0, prev - finalDamage));
    setEnemyShowDamage({ value: finalDamage, isCrit });

    // 添加元素附着
    const newElement: ElementalStatus = {
      element: 'fire',
      stacks: 1,
      duration: 5,
    };
    setPlayerElements(prev => [...prev.slice(-3), newElement]);

    setTimeout(() => setEnemyShowDamage(null), 800);

    if (enemyHp - finalDamage <= 0) {
      setTimeout(onVictory, 500);
    }
  }, [skills, playerStats, enemyHp, onVictory]);

  // 冷却更新
  useEffect(() => {
    const interval = setInterval(() => {
      setSkills(prev => prev.map(skill => ({
        ...skill,
        currentCooldown: Math.max(0, skill.currentCooldown - 0.1),
      })));
    }, 100);
    return () => clearInterval(interval);
  }, []);

  // 体力自动恢复
  useEffect(() => {
    const interval = setInterval(() => {
      setPlayerStats(prev => ({
        ...prev,
        stamina: Math.min(prev.maxStamina, prev.stamina + 2),
      }));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // 内力自动恢复
  useEffect(() => {
    const interval = setInterval(() => {
      setPlayerStats(prev => ({
        ...prev,
        qi: Math.min(prev.maxQi, prev.qi + 3),
      }));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // 键盘输入处理
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      switch (e.key.toLowerCase()) {
        case 'j':
        case ' ':
          handleAttack();
          break;
        case 'k':
          handleBlock(true);
          break;
        case 'l':
          handleDodge();
          break;
        case 'u':
          handleSkill(0);
          break;
        case 'i':
          handleSkill(1);
          break;
        case 'o':
          handleSkill(2);
          break;
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'k') {
        handleBlock(false);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [comboStage, playerStats.stamina, playerStats.hp, skills, handleAttack, handleBlock, handleDodge, handleSkill]);

  // 模拟敌人攻击
  useEffect(() => {
    const interval = setInterval(() => {
      if (Math.random() > 0.7) {
        const damage = 50 + Math.floor(Math.random() * 30);
        
        if (isInvincible) {
          setShowDamageNumber({ value: 0, isCrit: false });
        } else if (isBlocking) {
          const blockedDamage = isPerfectBlock ? 0 : Math.floor(damage * 0.3);
          setShowDamageNumber({ value: blockedDamage, isCrit: false });
          if (!isPerfectBlock) {
            setPlayerStats(prev => ({
              ...prev,
              hp: Math.max(0, prev.hp - blockedDamage),
              stamina: Math.max(0, prev.stamina - 10),
            }));
          }
        } else {
          setShowDamageNumber({ value: damage, isCrit: false });
          setPlayerStats(prev => ({
            ...prev,
            hp: Math.max(0, prev.hp - damage),
          }));
        }

        setTimeout(() => setShowDamageNumber(null), 800);

        if (playerStats.hp - damage <= 0) {
          clearInterval(interval);
          onDefeat();
        }
      }
    }, 2000);

    return () => clearInterval(interval);
  }, [isInvincible, isBlocking, isPerfectBlock, playerStats.hp, onDefeat]);

  // 元素附着消退
  useEffect(() => {
    const interval = setInterval(() => {
      setPlayerElements(prev => 
        prev
          .map(e => ({ ...e, duration: e.duration - 0.1 }))
          .filter(e => e.duration > 0)
      );
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const getSkillCooldownPercent = (skill: Skill) => {
    return (skill.currentCooldown / skill.cooldown) * 100;
  };

  return (
    <div 
      ref={battleRef}
      className={`battle-arena ${isInvincible ? 'battle-arena--invincible' : ''} ${isAttacking ? 'battle-arena--attacking' : ''}`}
    >
      {/* 水墨山水战斗背景 */}
      <div className="battle-background">
        <div className="ink-wave ink-wave--1" />
        <div className="ink-wave ink-wave--2" />
        <div className="ink-wave ink-wave--3" />
      </div>

      {/* 玩家状态区（左上） */}
      <div className="battle-player-status">
        <div className="player-avatar">🧑</div>
        <div className="player-info">
          <div className="player-info__name">江湖游侠</div>
          <div className="player-info__level">Lv.{playerStats.level}</div>
          <InkProgressBar 
            value={playerStats.hp} 
            max={playerStats.maxHp} 
            color="hp" 
            size="md"
            showLabel 
          />
        </div>
        {/* 元素附着 */}
        <div className="player-elements">
          {playerElements.map((e, i) => (
            <div key={i} className="element-status">
              <ElementIcon element={e.element} size="sm" />
              <span className="element-stacks">×{e.stacks}</span>
            </div>
          ))}
        </div>
      </div>

      {/* 敌人区域 */}
      <div className="battle-enemies">
        <div className="enemy-container">
          <div className="enemy-scroll">
            <div className="enemy-rod enemy-rod--top" />
            <div className="enemy-content">
              <div className="enemy-avatar">
                {enemy.faction === 'mingjiao' ? '🔥' : '⚔️'}
              </div>
              <div className="enemy-info">
                <div className="enemy-name">{enemy.name}</div>
                <div className="enemy-level">Lv.{enemy.level}</div>
                <InkProgressBar 
                  value={enemyHp} 
                  max={enemy.maxHp} 
                  color="hp"
                  size="sm"
                  showLabel 
                />
                {/* 敌人元素 */}
                <div className="enemy-elements">
                  {enemy.elements.map((e, i) => (
                    <ElementIcon key={i} element={e} size="sm" />
                  ))}
                </div>
              </div>
            </div>
            <div className="enemy-rod enemy-rod--bottom" />
          </div>
          
          {/* 伤害数字 */}
          {enemyShowDamage && (
            <div className={`damage-number ${enemyShowDamage.isCrit ? 'damage-number--crit' : ''}`}>
              {enemyShowDamage.isCrit ? '💥 ' : ''}{enemyShowDamage.value}
            </div>
          )}
        </div>
      </div>

      {/* 战斗场景区 */}
      <div className="battle-scene">
        <div className={`player-character ${isAttacking ? 'player-character--attack' : ''} ${isInvincible ? 'player-character--invincible' : ''}`}>
          <div className="character-sprite">🧑</div>
          <div className="character-shadow" />
          {isInvincible && <div className="invincible-flash" />}
        </div>

        {/* 玩家受伤显示 */}
        {showDamageNumber && (
          <div className="player-damage">
            {showDamageNumber.value === 0 ? '闪避!' : `-${showDamageNumber.value}`}
          </div>
        )}
      </div>

      {/* 资源条区 */}
      <div className="battle-resources">
        <div className="resource-row">
          <span className="resource-label">体力</span>
          <div className="resource-bar-wrapper">
            <InkProgressBar 
              value={playerStats.stamina} 
              max={playerStats.maxStamina} 
              color="stamina"
              size="sm"
            />
          </div>
          <span className="resource-value">{playerStats.stamina}/{playerStats.maxStamina}</span>
        </div>
        <div className="resource-row">
          <span className="resource-label">内力</span>
          <div className="resource-bar-wrapper">
            <InkProgressBar 
              value={playerStats.qi} 
              max={playerStats.maxQi} 
              color="qi"
              size="sm"
            />
          </div>
          <span className="resource-value">{playerStats.qi}/{playerStats.maxQi}</span>
        </div>
        <div className="resource-row">
          <span className="resource-label">剑意</span>
          <div className="resource-bar-wrapper">
            <InkProgressBar 
              value={playerStats.swordIntent} 
              max={playerStats.maxSwordIntent} 
              color="sword-intent"
              size="sm"
            />
          </div>
          <span className="resource-value">{playerStats.swordIntent}/{playerStats.maxSwordIntent}</span>
        </div>
      </div>

      {/* 连击指示器 */}
      <div className="combo-indicator">
        <div className={`combo-box combo-box--${comboStage}`}>
          <span className="combo-number">{comboStage}</span>
        </div>
      </div>

      {/* 操作按钮区 */}
      <div className="battle-controls">
        {/* 闪避 */}
        <button 
          className={`battle-btn battle-btn--dodge ${isInvincible ? 'battle-btn--active' : ''}`}
          onClick={handleDodge}
          disabled={playerStats.stamina < 10}
        >
          <span className="btn-icon">🏃</span>
          <span className="btn-label">闪避</span>
          <span className="btn-cost">-10</span>
        </button>

        {/* 普通攻击 */}
        <button 
          className={`battle-btn battle-btn--attack ${isAttacking ? 'battle-btn--active' : ''}`}
          onClick={handleAttack}
        >
          <span className="btn-icon">⚔️</span>
          <span className="btn-label">攻击</span>
          <span className="btn-combo">×{comboStage}</span>
        </button>

        {/* 技能1 */}
        <button 
          className={`battle-btn battle-btn--skill ${skills[0].currentCooldown > 0 ? 'battle-btn--cooldown' : ''}`}
          onClick={() => handleSkill(0)}
          disabled={skills[0].currentCooldown > 0 || playerStats.qi < skills[0].cost!}
        >
          <div className="skill-cooldown-ring" style={{ '--progress': `${getSkillCooldownPercent(skills[0])}%` } as React.CSSProperties} />
          <span className="btn-icon">🔥</span>
          <span className="btn-label">{skills[0].name}</span>
          <span className="btn-cost">-{skills[0].cost}</span>
        </button>

        {/* 技能2 */}
        <button 
          className={`battle-btn battle-btn--skill ${skills[1].currentCooldown > 0 ? 'battle-btn--cooldown' : ''}`}
          onClick={() => handleSkill(1)}
          disabled={skills[1].currentCooldown > 0 || playerStats.qi < skills[1].cost!}
        >
          <div className="skill-cooldown-ring" style={{ '--progress': `${getSkillCooldownPercent(skills[1])}%` } as React.CSSProperties} />
          <span className="btn-icon">🔥</span>
          <span className="btn-label">{skills[1].name}</span>
          <span className="btn-cost">-{skills[1].cost}</span>
        </button>

        {/* Q技能/大招 */}
        <button 
          className={`battle-btn battle-btn--ultimate ${skills[2].currentCooldown > 0 ? 'battle-btn--cooldown' : ''} ${playerStats.swordIntent >= 100 ? 'battle-btn--ready' : ''}`}
          onClick={() => handleSkill(2)}
          disabled={skills[2].currentCooldown > 0 || playerStats.qi < skills[2].cost!}
        >
          <div className="skill-cooldown-ring" style={{ '--progress': `${getSkillCooldownPercent(skills[2])}%` } as React.CSSProperties} />
          <span className="btn-icon">💥</span>
          <span className="btn-label">{skills[2].name}</span>
          <span className="btn-cost">-{skills[2].cost}</span>
        </button>

        {/* 格挡 */}
        <button 
          className={`battle-btn battle-btn--block ${isBlocking ? 'battle-btn--active' : ''}`}
          onMouseDown={() => handleBlock(true)}
          onMouseUp={() => handleBlock(false)}
          onMouseLeave={() => handleBlock(false)}
          disabled={playerStats.stamina < 15}
        >
          <span className="btn-icon">🛡️</span>
          <span className="btn-label">格挡</span>
          <span className="btn-cost">-15</span>
        </button>
      </div>

      {/* 操作提示 */}
      <div className="battle-hints">
        <span>J/空格 攻击</span>
        <span>K 长按 格挡</span>
        <span>L 闪避</span>
        <span>U/I/O 技能</span>
        <span>ESC 撤退</span>
      </div>

      {/* 完美格挡特效 */}
      {isPerfectBlock && (
        <div className="perfect-block-effect">
          <span className="perfect-text">完美!</span>
        </div>
      )}
    </div>
  );
};

export default Battle;
