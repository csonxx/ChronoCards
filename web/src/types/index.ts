// ChronoCards Type Definitions

// ========== 核心枚举 ==========

export type CardType = 
  | 'main'        // 主线剧情卡
  | 'side'        // 支线故事卡
  | 'growth'      // 机制体验卡 + 数值提升卡
  | 'emotion'     // 情感联结卡
  | 'economy'     // 经济系统卡
  | 'blank';      // 空白卡

export type Faction = 
  | 'wudang'      // 武当
  | 'shaolin'     // 少林
  | 'emei'        // 峨眉
  | 'huashan'     // 华山
  | 'kongdong'    // 崆峒
  | 'gaibang'     // 丐帮
  | 'yihua'       // 移花宫
  | 'mingjiao'    // 明教
  | 'jinyiwei';   // 锦衣卫

export type Element = 
  | 'fire'        // 火
  | 'water'       // 水
  | 'thunder'     // 雷
  | 'ice'         // 冰
  | 'wind'        // 风
  | 'poison';     // 毒

export type GameScene = 
  | 'menu'        // 主菜单
  | 'world'       // 开放世界
  | 'card'        // 抽牌界面
  | 'deck'        // 卡组浏览
  | 'battle'      // 战斗界面
  | 'dialog'      // 对话界面
  | 'character'   // 角色状态
  | 'map'         // 世界地图
  | 'settings';   // 设置界面

// ========== 卡牌系统 ==========

export interface Card {
  id: string;
  type: CardType;
  title: string;
  description: string;
  options?: CardOption[];
  triggered: boolean;
  progress?: number; // 0-100, 抽牌进度
}

export interface CardOption {
  id: string;
  text: string;
  consequence?: string;
  rewards?: Reward[];
  nextCardId?: string;
}

export interface Reward {
  type: 'hp' | 'mp' | 'reputation' | 'item' | 'skill' | 'faction';
  value: number | string;
}

// ========== 发牌员系统 ==========

export interface Dealer {
  id: string;
  name: string;
  type: DealerType;
  faction?: Faction;
  position: { x: number; y: number };
  dialog?: string[];
  icon?: string;
}

export type DealerType = 
  | 'teahouse'      // 茶馆说书人
  | 'billboard'     // 悬赏公告栏
  | 'enemy'         // 可审问的敌人
  | 'inn'           // 客栈掌柜
  | 'merchant'      // 商贩NPC
  | 'encounter';    // 动态遭遇

// ========== 战斗系统 ==========

export interface BattleStats {
  hp: number;
  maxHp: number;
  stamina: number;
  maxStamina: number;
  qi: number;
  maxQi: number;
  swordIntent: number;
  maxSwordIntent: number;
  level: number;
  attack: number;
  defense: number;
  elementMastery: number;
}

export interface ElementalStatus {
  element: Element;
  stacks: number;
  duration: number; // seconds remaining
}

export interface Skill {
  id: string;
  name: string;
  type: 'E' | 'Q' | 'passive';
  cooldown: number;
  currentCooldown: number;
  cost?: number;
  icon?: string;
}

export interface ComboAttack {
  stage: 1 | 2 | 3;
  damageMultiplier: number;
  effect: 'hit' | 'sweep' | 'smash';
}

export interface BattleEnemy {
  id: string;
  name: string;
  level: number;
  faction: Faction;
  hp: number;
  maxHp: number;
  elements: Element[];
  skills: Skill[];
  position: { x: number; y: number };
}

// ========== 角色系统 ==========

export interface Player {
  id: string;
  name: string;
  level: number;
  exp: number;
  faction: Faction | null;
  stats: BattleStats;
  elements: Element[];
  skills: Skill[];
  equipment: Equipment[];
  inventory: Item[];
  reputation: Record<Faction, number>;
}

export interface Equipment {
  id: string;
  name: string;
  type: 'weapon' | 'armor' | 'accessory';
  stats: Partial<BattleStats>;
  element?: Element;
}

export interface Item {
  id: string;
  name: string;
  type: 'consumable' | 'quest' | 'material';
  description: string;
  quantity: number;
}

// ========== 世界状态 ==========

export interface WorldState {
  currentRegion: Region;
  playerPosition: { x: number; y: number };
  dealers: Dealer[];
  triggeredCards: string[];
  activeEvents: GameEvent[];
}

export type Region = 
  | 'zhongyuan'      // 中原武林
  | 'jiangnan'       // 江南水乡
  | 'xibei'          // 西北边塞
  | 'xinan'          // 西南苗疆
  | 'donghai';       // 东海侠客岛

export interface GameEvent {
  id: string;
  cardId: string;
  dealerId: string;
  timestamp: number;
}

// ========== UI 状态 ==========

export interface UISate {
  currentScene: GameScene;
  isPaused: boolean;
  showCardDraw: boolean;
  currentCard: Card | null;
  battleState: BattleState | null;
}

export interface BattleState {
  inBattle: boolean;
  playerStats: BattleStats;
  playerElements: ElementalStatus[];
  enemies: BattleEnemy[];
  currentSkill: Skill | null;
  comboStage: 1 | 2 | 3;
  isBlocking: boolean;
  isPerfectBlock: boolean;
  isInvincible: boolean;
}

// ========== 场景布局接口 ==========

export interface SceneLayout {
  scene: GameScene;
  topBar?: React.ReactNode;
  leftPanel?: React.ReactNode;
  mainContent: React.ReactNode;
  bottomBar?: React.ReactNode;
}
