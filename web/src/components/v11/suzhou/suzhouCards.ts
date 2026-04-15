// 苏州城 · 场景事件卡数据 v1.0
// 数据来源：/root/.openclaw/workspace-wuyingshou/suzhou_city_events.md
// UI规范：苏州城专属卡背纹样（运河水波+苏绣纹样）

import type { CardType } from '../CompatibilityMatrix';
import type { EventCardData, CardOption } from '../EventCard';

// ========== 苏州城卡牌类型映射 ==========
// 🟠 主线剧情卡 × 1
// 🟠 情感联结卡 × 2
// 🟡 支线故事卡 × 2
// 🟣 命运转折卡 × 1
// ⚫ 时代印记卡 × 1

export type SuzhouCardId =
  | 'sz_main_shangmi'
  | 'sz_emotion_wupeng'
  | 'sz_emotion_lengxiang'
  | 'sz_side_sichou'
  | 'sz_side_huqiu'
  | 'sz_fate_zhuozheng'
  | 'sz_era_chengyun';

// ========== 触发点常量 ==========
export const SUZHOU_TRIGGER_LOCATIONS = {
  guaniqian_guild: '观前街·总商会门口',
  guaniqian_silk: '观前街·绸缎庄',
  guaniqian_teahouse: '观前街·江南茶舍',
  zhuozheng_entrance: '拙政园入口',
  changmen_dock: '阊门外·码头',
  huqiu_sword_tomb: '虎丘山·剑冢石碑',
  huqiu_lengxiang: '虎丘山·冷香阁',
} as const;

// ========== 7张苏州城事件卡数据 ==========
export const SUZHOU_EVENT_CARDS: Record<SuzhouCardId, EventCardData> = {
  // 🟠 主线剧情卡：苏商密议
  sz_main_shangmi: {
    id: 'sz_main_shangmi',
    type: 'main_story',
    title: '苏商密议',
    description:
      '观前街总商会门口，你撞见盐帮与丝帮两位当家正在密谈。言语间提到"明教江南有人要清洗"——这场对话似乎牵涉甚广。你的选择将影响后续剧情走向。',
    positiveEffect: '偷听成功，获得情报碎片：明教江南分坛线索',
    negativeVariant: '被察觉，商帮关系恶化，盐帮与丝帮对你的好感下降',
  },

  // 🟠 情感联结卡：乌篷船夜话
  sz_emotion_wupeng: {
    id: 'sz_emotion_wupeng',
    type: 'emotion',
    title: '乌篷船夜话',
    description:
      '阊门外码头，夜间。一名神秘女子（疑似明教中人）在等乌篷船。与你同船后，她夜话间透露江南武林近期异动。月色水光中，这场邂逅或许不只是偶然。',
    positiveEffect: '与神秘女子建立联系，好感度提升，获得江南武林情报',
    negativeVariant: '对话触怒对方，好感度下降，对方提前下船离去',
  },

  // 🟠 情感联结卡：冷香阁茶客
  sz_emotion_lengxiang: {
    id: 'sz_emotion_lengxiang',
    type: 'emotion',
    title: '冷香阁茶客',
    description:
      '虎丘山冷香阁，一位隐居老侠客（曾是正派高手）每日在此独坐品茶。他似乎在等什么人，又似乎在逃避什么。与他对话，可解锁一段尘封的往事。',
    positiveEffect: '好感度提升，解锁主线伏笔：老侠客过往与明教有关联',
    negativeVariant: '老侠客闭口不言，拒绝交流，但你获得了他的注意',
  },

  // 🟡 支线故事卡：丝帮大小姐的烦恼
  sz_side_sichou: {
    id: 'sz_side_sichou',
    type: 'side_story',
    title: '丝帮大小姐的烦恼',
    description:
      '观前街绸缎庄内，丝帮大小姐满面愁容——漕帮少主正在逼婚，婚期已定。你可以选择介入这场商帮博弈，或作壁上观，或渔翁得利。',
    positiveEffect: '帮助大小姐，好感度提升，丝帮关系改善，获得丝帮信任',
    negativeVariant: '渔翁得利短期获益，但商帮关系恶化，漕帮少主记恨于心',
  },

  // 🟡 支线故事卡：虎丘剑冢
  sz_side_huqiu: {
    id: 'sz_side_huqiu',
    type: 'side_story',
    title: '虎丘剑冢',
    description:
      '虎丘山剑冢石碑矗立于此，传说埋有吴王宝剑。你可以选择挖掘或离开。挖掘可能触发机关，获得一柄附带武学记忆碎片的古剑，也可能惊醒沉睡于此的守护者。',
    positiveEffect: '挖掘成功，获得古剑与武学记忆碎片',
    negativeVariant: '惊醒守护者，需战胜方可脱身（消耗气力）',
  },

  // 🟣 命运转折卡：拙政园迷阵
  sz_fate_zhuozheng: {
    id: 'sz_fate_zhuozheng',
    type: 'fate',
    title: '拙政园迷阵',
    description:
      '拙政园入口处，黑漆大门无声合上。你踏入回廊，却发现每转一道弯都回到原点——这是幻术考验。回廊在试探你的记忆与推理能力，通过者可获密道线索。',
    positiveEffect: '通过三道谜题考验，获得拙政园密道地图（通往明教江南分坛）',
    negativeVariant: '考验失败，困阵耗费1回合气力',
  },

  // ⚫ 时代印记卡：运河沉船事件
  sz_era_chengyun: {
    id: 'sz_era_chengyun',
    type: 'era',
    title: '运河沉船事件',
    description:
      '第二日清晨，阊门外运河浮起一艘沉没货船。死者身上携带少林信物，江湖震动。商帮之间互相指责，少林介入调查。你也卷入了这场悬案的调查之中。',
    positiveEffect: '成功调查真相，声誉提升，获得少林信任',
    negativeVariant: '调查触怒某方势力，受到漕帮或明教压力',
  },
};

// ========== 苏州城卡牌选项配置 ==========
// 包含选项的卡牌选项数据
export interface SuzhouCardOptions {
  cardId: SuzhouCardId;
  trigger: string;
  options: CardOption[];
  optionOutcomes?: Record<string, { effect: string; followUp?: string }>;
}

export const SUZHOU_CARD_OPTIONS: Record<SuzhouCardId, SuzhouCardOptions> = {
  sz_main_shangmi: {
    cardId: 'sz_main_shangmi',
    trigger: SUZHOU_TRIGGER_LOCATIONS.guaniqian_guild,
    options: [
      { id: 'listen', text: '悄悄偷听', isPositive: true },
      { id: 'avoid', text: '回避离开', isPositive: false },
      { id: 'intervene', text: '直接介入', isPositive: false },
    ],
    optionOutcomes: {
      listen: { effect: '偷听成功→获得情报碎片（明教江南分坛线索）' },
      avoid: { effect: '回避→无变化，安全离开' },
      intervene: { effect: '介入→触发漕帮少主冲突线，商帮关系变化' },
    },
  },

  sz_emotion_wupeng: {
    cardId: 'sz_emotion_wupeng',
    trigger: SUZHOU_TRIGGER_LOCATIONS.changmen_dock,
    options: [
      { id: 'chat', text: '主动攀谈', isPositive: true },
      { id: 'observe', text: '静默观察', isPositive: false },
    ],
    optionOutcomes: {
      chat: { effect: '好感度↑，获得江南武林异动情报' },
      observe: { effect: '对方主动离开，未获情报但未树敌' },
    },
  },

  sz_emotion_lengxiang: {
    cardId: 'sz_emotion_lengxiang',
    trigger: SUZHOU_TRIGGER_LOCATIONS.huqiu_lengxiang,
    options: [
      { id: 'offer_tea', text: '赠送茶点套近乎', isPositive: true },
      { id: 'ask_story', text: '直接询问往事', isPositive: false },
    ],
    optionOutcomes: {
      offer_tea: { effect: '好感度↑，加速解锁老侠客过往（主线伏笔）' },
      ask_story: { effect: '老侠客警觉，但开始注意你' },
    },
  },

  sz_side_sichou: {
    cardId: 'sz_side_sichou',
    trigger: SUZHOU_TRIGGER_LOCATIONS.guaniqian_silk,
    options: [
      { id: 'help', text: '出手相助', isPositive: true },
      { id: 'watch', text: '旁观不动', isPositive: false },
      { id: 'fish', text: '渔翁得利', isPositive: false },
    ],
    optionOutcomes: {
      help: { effect: '好感度↑，丝帮关系UP' },
      watch: { effect: '无变化，但大小姐记住了你' },
      fish: { effect: '短期利益↑，商帮关系恶化' },
    },
  },

  sz_side_huqiu: {
    cardId: 'sz_side_huqiu',
    trigger: SUZHOU_TRIGGER_LOCATIONS.huqiu_sword_tomb,
    options: [
      { id: 'dig', text: '挖掘石碑', isPositive: true },
      { id: 'leave', text: '转身离开', isPositive: false },
    ],
    optionOutcomes: {
      dig: {
        effect: '触发机关→古剑获得（附带武学记忆碎片）或触发守护者战斗',
        followUp: '战斗胜利→武学获取；战斗失败→消耗气力',
      },
      leave: { effect: '无后续，但石碑似乎在等待下一位有缘人' },
    },
  },

  sz_fate_zhuozheng: {
    cardId: 'sz_fate_zhuozheng',
    trigger: SUZHOU_TRIGGER_LOCATIONS.zhuozheng_entrance,
    options: [
      { id: 'solve', text: '沉着应对谜题', isPositive: true },
      { id: 'giveup', text: '放弃退出', isPositive: false },
    ],
    optionOutcomes: {
      solve: { effect: '通过3道谜题→获得拙政园密道地图（通往明教分坛）' },
      giveup: { effect: '退出园林，无损失但无收获' },
    },
  },

  sz_era_chengyun: {
    cardId: 'sz_era_chengyun',
    trigger: SUZHOU_TRIGGER_LOCATIONS.changmen_dock,
    options: [
      { id: 'investigate_shao', text: '追查少林线索', isPositive: true },
      { id: 'investigate_cao', text: '调查漕帮', isPositive: true },
      { id: 'investigate_ming', text: '暗中联络明教', isPositive: false },
      { id: 'investigate_guild', text: '追查商帮内部', isPositive: false },
    ],
    optionOutcomes: {
      investigate_shao: { effect: '少林信任↑，漕帮好感↓' },
      investigate_cao: { effect: '漕帮关系恶化，线索获取' },
      investigate_ming: { effect: '明教关系改善，但少林敌意加深' },
      investigate_guild: { effect: '获得商帮内幕，但各方对你的信任下降' },
    },
  },
};

// ========== 苏州城专属 UI 配置 ==========
export const SUZHOU_UI_CONFIG = {
  // 卡背纹样：运河水波 + 苏绣纹样
  cardBackPattern: {
    primaryColor: '#2D5A5A',    // 运河青
    secondaryColor: '#D4A017',   // 暖金（苏绣常用色）
    patternType: 'canal_wave',   // 运河水波纹
    accentPattern: 'suzhou_embroidery', // 苏绣纹样
  },

  // 触发UI：右下角灯笼图标闪烁
  triggerIndicator: {
    icon: '🏮',
    position: 'bottom-right',
    animation: 'pulse_glow',  // 灯笼呼吸光效
  },

  // 选项卡：折扇展开样式
  optionCardStyle: 'fan_unfold',  // 区别于其他城市的卷轴样式

  // 对话气泡边框
  dialogueBorders: {
    teahouse: 'brush_stroke',     // 江南茶舍/拙政园：毛笔边框
    default: 'celadon',           // 其他区域：青瓷边框
  },

  // 好感度UI：情感联结卡右上角显示角色头像
  affectionUI: {
    position: 'top-right',
    display: 'circular_avatar',
  },
};

// ========== 苏州城场景分区 ==========
export const SUZHOU_ZONES = {
  guaniqian: {
    name: '观前街',
    description: '玩家起点主城，商帮信息中心，发牌员密度最高',
    triggers: ['sz_main_shangmi', 'sz_side_sichou'],
    bgm: { instrument: '琵琶+扬琴+柳琴', mood: '繁华但有距离感' },
  },
  zhuozheng: {
    name: '拙政园',
    description: '江南武林联络处 + 明教江南分坛入口',
    triggers: ['sz_fate_zhuozheng'],
    bgm: { instrument: '古琴+风铃+水滴', mood: '优雅但有压迫感' },
  },
  changmen: {
    name: '阊门外',
    description: '货运枢纽，江湖与漕帮的角力点',
    triggers: ['sz_emotion_wupeng', 'sz_era_chengyun'],
    bgm: { instrument: '梆子+二胡+号子', mood: '喧嚣但有秩序感' },
  },
  huqiu: {
    name: '虎丘山',
    description: '城市边缘，支线任务区，剑冢所在地',
    triggers: ['sz_emotion_lengxiang', 'sz_side_huqiu'],
    bgm: { instrument: '箫+古琴+风声', mood: '穿越时光的寂静' },
  },
};

// ========== 辅助函数 ==========
export function getSuzhouCardById(id: SuzhouCardId): EventCardData {
  return SUZHOU_EVENT_CARDS[id];
}

export function getSuzhouCardOptions(id: SuzhouCardId): SuzhouCardOptions | undefined {
  return SUZHOU_CARD_OPTIONS[id];
}

export function getSuzhouCardsByZone(zone: keyof typeof SUZHOU_ZONES): EventCardData[] {
  const zoneData = SUZHOU_ZONES[zone];
  return zoneData.triggers.map(id => SUZHOU_EVENT_CARDS[id]);
}

export function getAllSuzhouCards(): EventCardData[] {
  return Object.values(SUZHOU_EVENT_CARDS);
}
