// 卡牌效果联动逻辑
// 处理玩家选择选项后的实际效果

import type { SavedPlayer, SavedProgress } from './save-system';
import type { CardRewards } from '../types/api-schema';
import { saveManager } from './save-system';

export interface CardEffectResult {
  hpChange: number;
  mpChange: number;
  expChange: number;
  skillGained?: string;
  reputationChanges: Record<string, number>;
  narrativeText: string;
  sceneChange?: 'battle' | 'world' | 'dialog';
  battleConfig?: BattleConfig;
}

export interface BattleConfig {
  enemyId: string;
  enemyName: string;
  enemyLevel: number;
  enemyHp: number;
  enemyElement?: string;
}

export interface CardOptionEffect {
  consequence: string;   // 自然语言描述效果
  rewards: CardRewards;   // 实际奖励数据
  sceneChange?: 'battle' | 'world' | 'dialog';
  battleConfig?: BattleConfig;
}

// 发牌员类型 → 对应卡牌类型（影响叙事）
const DEALER_CARD_TYPE_MAP: Record<string, string> = {
  teahouse: 'side_story',
  billboard: 'main_story',
  inn: 'emotion',
  merchant: 'economy',
  enemy: 'side_story',
  encounter: 'side_story',
};

// 选项效果预定义表（实际内容由 AI Narrative 填充，这里做兜底）
const OPTION_EFFECT_PRESETS: Record<string, CardOptionEffect> = {
  // === 通用正面选项 ===
  accept_good: {
    consequence: '你欣然接受，获得了意外之喜。',
    rewards: { exp: 30, hp_up: 20 },
    sceneChange: 'world',
  },
  accept_neutral: {
    consequence: '你接受了提议，事情朝着意料之中发展。',
    rewards: { exp: 15 },
    sceneChange: 'world',
  },
  refuse_polite: {
    consequence: '你婉言谢绝，对方并未动怒。',
    rewards: { exp: 10 },
    sceneChange: 'world',
  },
  inquire: {
    consequence: '你追问详情，对方透露了更多信息。',
    rewards: { exp: 20 },
    sceneChange: 'dialog',
  },

  // === 战斗相关选项 ===
  fight_direct: {
    consequence: '你拔剑相向，战斗爆发！',
    rewards: {},
    sceneChange: 'battle',
    battleConfig: { enemyId: 'enemy_temp', enemyName: '不明身份的敌人', enemyLevel: 10, enemyHp: 800 },
  },
  interrogate: {
    consequence: '你将其制服审问，获得情报。',
    rewards: { exp: 40, skill_id: 'intel_skill' },
    sceneChange: 'world',
  },
  intimidate: {
    consequence: '你威逼利诱，对方交代了一切。',
    rewards: { exp: 25, reputation: { mingjiao: -5 } },
    sceneChange: 'world',
  },

  // === 社交/声望选项 ===
  help_npc: {
    consequence: '你出手相助，对方感激涕零。',
    rewards: { exp: 35, reputation: { zhengpai: 10 } },
    sceneChange: 'world',
  },
  ignore: {
    consequence: '你选择冷眼旁观，事情自行消散。',
    rewards: { exp: 5 },
    sceneChange: 'world',
  },

  // === 成长/技能选项 ===
  train_hard: {
    consequence: '你勤学苦练，功力精进。',
    rewards: { exp: 50, hp_up: 30, mp_up: 15 },
    sceneChange: 'world',
  },
  learn_skill: {
    consequence: '你领悟了一招新式！',
    rewards: { exp: 20, skill_id: 'new_technique' },
    sceneChange: 'world',
  },
};

// 根据选项文本关键词匹配效果
function matchEffectByKeywords(optionText: string): CardOptionEffect | null {
  const text = optionText.toLowerCase();

  if (text.match(/欣然接受|接受|同意|答应/)) {
    if (text.match(/帮助|相助|出手/)) return OPTION_EFFECT_PRESETS.help_npc;
    return OPTION_EFFECT_PRESETS.accept_good;
  }
  if (text.match(/婉言谢绝|婉拒|拒绝|算了/)) return OPTION_EFFECT_PRESETS.refuse_polite;
  if (text.match(/追问|详细问|询问/)) return OPTION_EFFECT_PRESETS.inquire;
  if (text.match(/拔剑|战斗|打|开打/)) return OPTION_EFFECT_PRESETS.fight_direct;
  if (text.match(/审问|逼问|质问/)) return OPTION_EFFECT_PRESETS.interrogate;
  if (text.match(/威逼|威胁|利诱/)) return OPTION_EFFECT_PRESETS.intimidate;
  if (text.match(/勤学|苦练|修炼|训练/)) return OPTION_EFFECT_PRESETS.train_hard;
  if (text.match(/学习|领悟|学会/)) return OPTION_EFFECT_PRESETS.learn_skill;
  if (text.match(/帮助|相助|出手/)) return OPTION_EFFECT_PRESETS.help_npc;
  if (text.match(/无视|不管|走开/)) return OPTION_EFFECT_PRESETS.ignore;

  return null;
}

// 对话后处理选项效果
export function applyCardOptionEffect(
  optionText: string,
  cardRewards?: CardRewards,
  dealerType?: string
): CardEffectResult {
  const result: CardEffectResult = {
    hpChange: cardRewards?.hp_up || 0,
    mpChange: cardRewards?.mp_up || 0,
    expChange: cardRewards?.exp || 0,
    skillGained: cardRewards?.skill_id,
    reputationChanges: {},
    narrativeText: '',
  };

  // 1. 优先用预设效果（关键词匹配）
  const preset = matchEffectByKeywords(optionText);

  if (preset) {
    result.hpChange += preset.rewards.hp_up || 0;
    result.mpChange += preset.rewards.mp_up || 0;
    result.expChange += preset.rewards.exp || 0;
    result.skillGained = result.skillGained || preset.rewards.skill_id;
    result.narrativeText = preset.consequence;
    result.sceneChange = preset.sceneChange;
    result.battleConfig = preset.battleConfig;
  } else {
    // 2. 用卡牌 rewards 数据
    result.narrativeText = cardRewards
      ? `你获得了经验值${cardRewards.exp || 0}。`
      : '你的选择没有带来明显变化。';
    result.sceneChange = 'world';
  }

  // 3. 声望变化
  if (cardRewards?.reputation) {
    result.reputationChanges = { ...cardRewards.reputation };
  }

  // 4. 写入存档
  applyEffectToSave(result);

  return result;
}

// 将效果实际写入存档
function applyEffectToSave(result: CardEffectResult): void {
  saveManager.updatePlayer(p => {
    if (result.hpChange !== 0) {
      p.hp = Math.max(1, Math.min(p.maxHp, p.hp + result.hpChange));
    }
    if (result.mpChange !== 0) {
      p.mp = Math.max(0, Math.min(p.maxMp, p.mp + result.mpChange));
    }
    if (result.expChange !== 0) {
      p.exp += result.expChange;
      // 检查升级
      while (p.exp >= p.level * 100) {
        p.exp -= p.level * 100;
        p.level++;
        p.maxHp += 50;
        p.hp = p.maxHp;
        p.maxMp += 10;
        p.mp = p.maxMp;
      }
    }
    if (result.skillGained && !p.skills.includes(result.skillGained)) {
      p.skills.push(result.skillGained);
    }
    for (const [faction, delta] of Object.entries(result.reputationChanges)) {
      if (p.reputation[faction] !== undefined) {
        p.reputation[faction] = Math.max(-100, Math.min(100, p.reputation[faction] + delta));
      }
    }
  });

  if (result.expChange > 0) {
    saveManager.save();
  }
}

// 战斗胜利后处理奖励
export function applyBattleVictoryRewards(rewards?: CardRewards): CardEffectResult {
  const result: CardEffectResult = {
    hpChange: rewards?.hp_up || 0,
    mpChange: rewards?.mp_up || 0,
    expChange: rewards?.exp || 50, // 默认50经验
    skillGained: rewards?.skill_id,
    reputationChanges: {},
    narrativeText: '战斗胜利！',
    sceneChange: 'world',
  };

  if (rewards?.reputation) {
    result.reputationChanges = { ...rewards.reputation };
  }

  saveManager.onBattleWon();
  applyEffectToSave(result);

  return result;
}

// 获得卡牌奖励时的展示数据
export interface RewardDisplay {
  icon: string;
  label: string;
  value: string;
}

export function rewardsToDisplay(rewards?: CardRewards): RewardDisplay[] {
  if (!rewards) return [];
  const displays: RewardDisplay[] = [];
  if (rewards.exp) displays.push({ icon: '✨', label: '经验', value: `+${rewards.exp}` });
  if (rewards.hp_up) displays.push({ icon: '❤️', label: '生命', value: `+${rewards.hp_up}` });
  if (rewards.mp_up) displays.push({ icon: '💙', label: '内力', value: `+${rewards.mp_up}` });
  if (rewards.skill_id) displays.push({ icon: '📜', label: '技能', value: rewards.skill_id });
  if (rewards.reputation) {
    for (const [faction, val] of Object.entries(rewards.reputation)) {
      if (val !== 0) {
        displays.push({ icon: '🏅', label: faction, value: `+${val}` });
      }
    }
  }
  return displays;
}
