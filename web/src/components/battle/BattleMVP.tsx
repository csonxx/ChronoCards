// S5: 战斗界面 MVP - 即时战斗验证版
// 数值确认：无敌帧200ms，敌人攻击间隔3秒，伤害50

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { InkProgressBar } from '../ui';
import './battle_mvp.css';

interface BattleMVPProps {
  playerHp?: number;
  playerMaxHp?: number;
  playerLevel?: number;
  enemyHp?: number;
  enemyMaxHp?: number;
  enemyName?: string;
  enemyLevel?: number;
  onVictory: () => void;
  onDefeat: () => void;
}

export const BattleMVP: React.FC<BattleMVPProps> = ({
  playerHp = 1000,
  playerMaxHp = 1000,
  playerLevel = 12,
  enemyHp: initialEnemyHp = 500,
  enemyMaxHp = 500,
  enemyName = '明教弟子',
  enemyLevel = 12,
  onVictory,
  onDefeat,
}) => {
  // 玩家状态
  const [hp, setHp] = useState(playerHp);
  const [maxHp] = useState(playerMaxHp);
  const [stamina, setStamina] = useState(100);
  const maxStamina = 100;

  // 敌人状态
  const [enemyCurrentHp, setEnemyCurrentHp] = useState(initialEnemyHp);
  const [enemyMax] = useState(enemyMaxHp);

  // 战斗状态
  const [isInvincible, setIsInvincible] = useState(false);
  const [isAttacking, setIsAttacking] = useState(false);
  const [isStaggered, setIsStaggered] = useState(false);
  const [playerDamage, setPlayerDamage] = useState<number | null>(null);
  const [enemyDamage, setEnemyDamage] = useState<number | null>(null);
  const [battlePhase, setBattlePhase] = useState<'intro' | 'battle' | 'victory' | 'defeat'>('intro');

  const lastAttackTime = useRef(0);
  const lastDodgeTime = useRef(0);
  const enemyAttackTimer = useRef<ReturnType<typeof setInterval> | null>(null);

  // === 攻击（固定50伤，300ms硬直）===
  const handleAttack = useCallback(() => {
    if (isStaggered || battlePhase !== 'battle') return;

    const now = Date.now();
    if (now - lastAttackTime.current < 300) return; // 攻击硬直300ms
    lastAttackTime.current = now;

    setIsAttacking(true);
    setIsStaggered(true);

    // 固定伤害50
    const damage = 50;
    setEnemyCurrentHp(prev => Math.max(0, prev - damage));
    setEnemyDamage(damage);

    setTimeout(() => {
      setIsAttacking(false);
      setIsStaggered(false);
    }, 300);

    setTimeout(() => setEnemyDamage(null), 800);
  }, [isStaggered, battlePhase]);

  // === 闪避（消耗15体力，200ms无敌帧）===
  const handleDodge = useCallback(() => {
    if (stamina < 15 || battlePhase !== 'battle') return;

    const now = Date.now();
    if (now - lastDodgeTime.current < 200) return; // 无敌帧200ms防连按
    lastDodgeTime.current = now;

    setStamina(prev => prev - 15);
    setIsInvincible(true);

    setTimeout(() => setIsInvincible(false), 200);
  }, [stamina, battlePhase]);

  // === 敌人攻击（每3秒一次，伤害50）===
  useEffect(() => {
    if (battlePhase !== 'battle') return;

    enemyAttackTimer.current = setInterval(() => {
      if (isInvincible) {
        // 无敌帧中，闪避成功
        setPlayerDamage(0);
      } else {
        // 固定伤害50
        const damage = 50;
        setHp(prev => Math.max(0, prev - damage));
        setPlayerDamage(damage);
      }

      setTimeout(() => setPlayerDamage(null), 800);
    }, 3000);

    return () => {
      if (enemyAttackTimer.current) clearInterval(enemyAttackTimer.current);
    };
  }, [battlePhase, isInvincible]);

  // === 体力恢复（每秒+8）===
  useEffect(() => {
    if (battlePhase !== 'battle') return;

    const interval = setInterval(() => {
      setStamina(prev => Math.min(maxStamina, prev + 8));
    }, 1000);

    return () => clearInterval(interval);
  }, [battlePhase]);

  // === 战斗开始 ===
  useEffect(() => {
    const timer = setTimeout(() => {
      setBattlePhase('battle');
    // 切换到战斗BGM
    const battleMusic = new Audio('/assets/audio/battle_bgm.mp3');
    battleMusic.loop = true;
    battleMusic.volume = 0.4;
    battleMusic.play().catch(() => {});
    }, 800);
    return () => clearTimeout(timer);
  }, []);

  // === 胜负判定 ===
  useEffect(() => {
    if (battlePhase !== 'battle') return;

    if (enemyCurrentHp <= 0) {
      setBattlePhase('victory');
      playVictorySound();
      if (enemyAttackTimer.current) clearInterval(enemyAttackTimer.current);
      setTimeout(onVictory, 1500);
    } else if (hp <= 0) {
      setBattlePhase('defeat');
      if (enemyAttackTimer.current) clearInterval(enemyAttackTimer.current);
      setTimeout(onDefeat, 1500);
    }
  }, [enemyCurrentHp, hp, battlePhase, onVictory, onDefeat]);

  const canDodge = stamina >= 15 && battlePhase === 'battle';
  const canAttack = !isStaggered && battlePhase === 'battle';

  // 攻击音效
  const playAttackSound = () => {
    const sfx = new Audio('/assets/audio/attack.mp3');
    sfx.volume = 0.5;
    sfx.play().catch(() => {});
  };
  const playDodgeSound = () => {
    const sfx = new Audio('/assets/audio/card_draw.mp3');
    sfx.volume = 0.4;
    sfx.play().catch(() => {});
  };
  const playVictorySound = () => {
    const sfx = new Audio('/assets/audio/quest_complete.mp3');
    sfx.volume = 0.5;
    sfx.play().catch(() => {});
  };

  return (
    <div style={{
      backgroundImage: `linear-gradient(to bottom, rgba(0,0,0,0.7) 0%, rgba(20,10,5,0.85) 100%), url("/assets/scenes/battle_bg_1.png")`,
      backgroundSize: "cover, cover",
      backgroundPosition: "center, center",
      minHeight: "100vh",
    }} className={`battle-mvp ${battlePhase === 'intro' ? 'battle-mvp--intro' : ''} ${isInvincible ? 'battle-mvp--invincible' : ''} ${battlePhase === 'defeat' ? 'battle-mvp--defeat' : ''}`}>

      {/* 战斗开始提示 */}
      {battlePhase === 'intro' && (
        <div className="battle-mvp__intro-text">战斗开始！</div>
      )}

      {/* 玩家状态区（左上） */}
      <div className="battle-mvp__player-status">
        <img src="/assets/characters/shen_moyuan_1.png" alt="玩家" className="battle-mvp__avatar" style={{width:64,height:64,borderRadius:8,border:"2px solid gold"}} />
        <div className="battle-mvp__player-info">
          <div className="battle-mvp__player-name">江湖游侠</div>
          <div className="battle-mvp__player-level">Lv.{playerLevel}</div>
          <InkProgressBar value={hp} max={maxHp} color="hp" size="md" showLabel />
        </div>
      </div>

      {/* 敌人区域（头顶血条） */}
      <div className="battle-mvp__enemy">
        <div className="battle-mvp__enemy-name">{enemyName}</div>
        <div className="battle-mvp__enemy-hp-bar">
          <div className="battle-mvp__enemy-hp-fill" style={{ width: `${(enemyCurrentHp / enemyMax) * 100}%` }} />
        </div>
        <div className="battle-mvp__enemy-hp-text">{enemyCurrentHp} / {enemyMax}</div>

        {/* 敌人伤害飘字 */}
        {enemyDamage !== null && (
          <div className={`battle-mvp__damage-number ${enemyDamage === 0 ? 'battle-mvp__damage-number--dodge' : ''}`}>
            {enemyDamage === 0 ? '闪避!' : `-${enemyDamage}`}
          </div>
        )}
      </div>

      {/* 战斗场景（玩家角色） */}
      <div className="battle-mvp__scene">
        <div className={`battle-mvp__player-char ${isAttacking ? 'battle-mvp__player-char--attack' : ''} ${isInvincible ? 'battle-mvp__player-char--invincible' : ''}`}>
          <div className="battle-mvp__char-sprite">🧑</div>
          <div className="battle-mvp__char-shadow" />
          {isInvincible && <div className="battle-mvp__invincible-ring" />}
        </div>

        {/* 玩家受伤飘字 */}
        {playerDamage !== null && (
          <div className={`battle-mvp__player-damage ${playerDamage === 0 ? 'battle-mvp__player-damage--dodge' : ''}`}>
            {playerDamage === 0 ? '闪避!' : `-${playerDamage}`}
          </div>
        )}
      </div>

      {/* 体力条（中下部） */}
      <div className="battle-mvp__stamina-bar">
        <span className="battle-mvp__stamina-label">体力</span>
        <div className="battle-mvp__stamina-track">
          <div className="battle-mvp__stamina-fill" style={{ width: `${(stamina / maxStamina) * 100}%` }} />
        </div>
        <span className="battle-mvp__stamina-value">{stamina} / {maxStamina}</span>
      </div>

      {/* 操作按钮 */}
      <div className="battle-mvp__controls">
        <button
          className={`battle-mvp__btn battle-mvp__btn--attack ${!canAttack ? 'battle-mvp__btn--disabled' : ''}`}
          onClick={handleAttack}
          disabled={!canAttack}
        >
          <span className="battle-mvp__btn-icon">⚔️</span>
          <span className="battle-mvp__btn-label">攻击</span>
        </button>

        <button
          className={`battle-mvp__btn battle-mvp__btn--dodge ${!canDodge ? 'battle-mvp__btn--disabled' : ''}`}
          onClick={handleDodge}
          disabled={!canDodge}
        >
          <span className="battle-mvp__btn-icon">🏃</span>
          <span className="battle-mvp__btn-label">闪避</span>
          <span className="battle-mvp__btn-cost">-15</span>
        </button>
      </div>

      {/* 胜利界面 */}
      {battlePhase === 'victory' && (
        <div className="battle-mvp__result battle-mvp__result--victory">
          <div className="battle-mvp__result-title">胜利！</div>
          <div className="battle-mvp__result-hp">剩余HP：{hp} / {maxHp}</div>
        </div>
      )}

      {/* 战败界面 */}
      {battlePhase === 'defeat' && (
        <div className="battle-mvp__result battle-mvp__result--defeat">
          <div className="battle-mvp__result-title">战败...</div>
        </div>
      )}
    </div>
  );
};

export default BattleMVP;
