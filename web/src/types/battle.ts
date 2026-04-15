// ChronoCards 完整战斗系统类型定义 v2.0
// 基于产品文档第九章：完整ARPG战斗系统

// ========== 元素类型 ==========
export type Element = 'fire' | 'water' | 'thunder' | 'ice' | 'wind' | 'poison';

// ========== 三资源系统 ==========
export interface ThreeResources {
  hp: number;
  maxHp: number;
  stamina: number;      // 体力：闪避/格挡消耗
  maxStamina: number;
  qi: number;           // 内力/真气：技能消耗
  maxQi: number;
}

// ========== 武学体系 ==========
export type MartialArtsType = 'inner' | 'outer' | 'light';

export interface SkillEffect {
  type: 'heal' | 'shield' | 'buff' | 'debuff' | 'cc' | 'element-apply' | 'counter';
  value?: number;
  duration?: number;
  element?: Element;
  stacks?: number;
}

export interface MartialArtsSkill {
  id: string;
  name: string;
  type: MartialArtsType;
  subtype: string;
  costType: 'stamina' | 'qi' | 'none';
  cost: number;
  cooldown: number;
  currentCooldown: number;
  damage?: number;
  damageMultiplier?: number;
  element?: Element;
  effect?: SkillEffect;
  description: string;
  animation?: string;
}

// ========== 元素反应系统 ==========
export type ElementReactionType = 'vaporize' | 'melt' | 'freeze' | 'superconduct' | 'overload' | 'spread' | 'dilute' | 'catalyze';

export interface ElementReaction {
  type: ElementReactionType;
  trigger: [Element, Element];
  damage: number;
  effect?: SkillEffect;
  description: string;
}

export interface EnemyElementalStatus {
  element: Element;
  stacks: number;
  duration: number;
  source?: 'player' | 'enemy';
}

// ========== 闪避无敌帧系统 ==========
export type DodgeType = 'side' | 'dash' | 'wall-jump' | 'air-dash' | 'downstrike';

export interface DodgeInfo {
  id: string;
  name: string;
  type: DodgeType;
  invincibleFrames: number;
  distance: number;
  cost: number;
  cooldown: number;
  currentCooldown: number;
  description: string;
}

// ========== 完美格挡/反击系统 ==========
export interface PerfectBlockWindow {
  startMs: number;
  endMs: number;
}

export interface CounterAttack {
  id: string;
  name: string;
  damage: number;
  damageMultiplier: number;
  effect?: SkillEffect;
  animation?: string;
}

// ========== 完整战斗状态 ==========
export interface FullBattleStats extends ThreeResources {
  level: number;
  attack: number;
  defense: number;
  elementMastery: number;
  criticalRate: number;
  criticalDamage: number;
  innerSkills: MartialArtsSkill[];
  outerSkills: MartialArtsSkill[];
  lightSkills: DodgeInfo[];
  playerElements: EnemyElementalStatus[];
  swordIntent: number;
  maxSwordIntent: number;
  perfectBlockAvailable: boolean;
  lastBlockTime: number;
  comboCount: number;
  comboTimer: number;
}

// ========== 敌人完整数据 ==========
export type Faction = 'wudang' | 'shaolin' | 'emei' | 'huashan' | 'kongdong' | 'gaibang' | 'yihua' | 'mingjiao' | 'jinyiwei';

export interface FullBattleEnemy {
  id: string;
  name: string;
  level: number;
  faction: Faction;
  hp: number;
  maxHp: number;
  attack: number;
  defense: number;
  elements: Element[];
  skills: MartialArtsSkill[];
  position: { x: number; y: number };
  behavior?: 'aggressive' | 'defensive' | 'balanced';
  attackInterval: number;
  lastAttackTime: number;
  elementalStatus: EnemyElementalStatus[];
  isBoss?: boolean;
  phases?: number;
}

// ========== 战斗UI状态 ==========
export interface BattleUIState {
  playerStats: FullBattleStats;
  enemies: FullBattleEnemy[];
  inBattle: boolean;
  battleStartTime: number;
  battleDuration: number;
  comboStage: 1 | 2 | 3;
  maxCombo: number;
  currentDodge: DodgeType | null;
  isInvincible: boolean;
  invincibleEndTime: number;
  isBlocking: boolean;
  isPerfectBlock: boolean;
  perfectBlockEndTime: number;
  activeReactions: Array<{ type: ElementReactionType; damage: number; timestamp: number }>;
  damageNumbers: Array<{ id: string; value: number; isCrit: boolean; isPlayer: boolean; x: number; y: number }>;
  activeEffects: Array<{ id: string; type: string; x: number; y: number; duration: number }>;
  battleLog: BattleLogEntry[];
}

export interface BattleLogEntry {
  timestamp: number;
  type: 'damage' | 'heal' | 'block' | 'perfect-block' | 'dodge' | 'skill' | 'reaction' | 'counter';
  message: string;
  value?: number;
  element?: Element;
}

export interface BattleResult {
  victory: boolean;
  duration: number;
  damageDealt: number;
  damageTaken: number;
  maxCombo: number;
  perfectBlocks: number;
  reactionsTriggered: number;
  skillsUsed: number;
}

// ========== 元素反应配置 ==========
export const ELEMENT_REACTIONS: Record<ElementReactionType, ElementReaction> = {
  vaporize: { type: 'vaporize', trigger: ['fire', 'water'], damage: 150, description: '蒸发：火+水，额外火元素伤害' },
  melt: { type: 'melt', trigger: ['ice', 'fire'], damage: 180, description: '融化：冰+火，爆发伤害' },
  freeze: { type: 'freeze', trigger: ['ice', 'water'], damage: 0, effect: { type: 'cc', value: 0, duration: 2 }, description: '冻结：冰+水，目标冻结2秒' },
  superconduct: { type: 'superconduct', trigger: ['thunder', 'ice'], damage: 120, effect: { type: 'debuff', value: 30, duration: 4 }, description: '超导：雷+冰，降低防御' },
  overload: { type: 'overload', trigger: ['thunder', 'fire'], damage: 200, description: '超载：雷+火，高额雷火伤害' },
  spread: { type: 'spread', trigger: ['wind', 'fire'], damage: 80, description: '扩散：风+火，风元素范围伤害' },
  dilute: { type: 'dilute', trigger: ['poison', 'water'], damage: 60, effect: { type: 'debuff', value: 10, duration: 5 }, description: '稀释：毒+水，毒雾扩散' },
  catalyze: { type: 'catalyze', trigger: ['poison', 'thunder'], damage: 100, effect: { type: 'debuff', value: 20, duration: 3 }, description: '催化：毒+雷，毒性强化' },
};

export const PERFECT_BLOCK_WINDOW: PerfectBlockWindow = { startMs: 50, endMs: 200 };

export const COUNTER_ATTACKS: CounterAttack[] = [
  { id: 'counter-1', name: '顺势一击', damage: 0, damageMultiplier: 1.2 },
  { id: 'counter-2', name: '借力打力', damage: 0, damageMultiplier: 1.5, effect: { type: 'cc', value: 0, duration: 0.5 } },
];
