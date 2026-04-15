// ChronoCards 存档系统
// 本地优先 + 可扩展云端同步

import type { Player, Deck, WorldState } from '../types/api-schema';
import type { Region, GameScene } from '../types';

export interface SaveSlot {
  id: string;
  name: string;
  createdAt: number;
  updatedAt: number;
  playtimeSeconds: number;
  thumbnail?: string; // base64 缩略图
}

export interface SaveData {
  version: string;          // 存档版本号，用于迁移
  slot: number;              // 存档槽位 1-3

  // 玩家数据
  player: SavedPlayer;

  // 卡组数据
  deck: SavedDeck;

  // 世界状态
  world: SavedWorld;

  // 游戏进度
  progress: SavedProgress;

  // 元数据
  meta: {
    createdAt: number;
    updatedAt: number;
    playtimeSeconds: number;
    sceneBeforeClose: GameScene;
  };
}

export interface SavedPlayer {
  id: string;
  name: string;
  level: number;
  exp: number;
  hp: number;
  maxHp: number;
  mp: number;
  maxMp: number;
  stamina: number;
  maxStamina: number;
  swordIntent: number;
  maxSwordIntent: number;
  faction: string | null;
  skills: string[];
  reputation: Record<string, number>;
  elementMastery: Record<string, number>;
}

export interface SavedDeck {
  id: string;
  name: string;
  cards: SavedCard[];
  currentIndex: number;
  drawnHand: SavedCard[];
  discardPile: SavedCard[];
}

export interface SavedCard {
  id: string;
  type: string;
  title: string;
  description: string;
  triggered: boolean;
  rewards?: {
    exp?: number;
    hp_up?: number;
    mp_up?: number;
    skill_id?: string;
  };
}

export interface SavedWorld {
  currentRegion: Region;
  playerPosition: { x: number; y: number };
  triggeredCardIds: string[];
  activeEventIds: string[];
}

export interface SavedProgress {
  currentChapter: string;
  completedChapters: string[];
  unlockedRegions: Region[];
  achievements: string[];
  stats: {
    battlesWon: number;
    battlesLost: number;
    cardsDrawn: number;
    perfectBlocks: number;
    perfectDodges: number;
  };
}

const SAVE_VERSION = '1.0.0';
const SAVE_KEY_PREFIX = 'chronocards_save_v1_slot';
const SAVE_INDEX_KEY = 'chronocards_save_index';

const DEFAULT_SAVE_DATA = (slot: number, playerName: string): SaveData => ({
  version: SAVE_VERSION,
  slot,
  player: {
    id: `player_${Date.now()}`,
    name: playerName,
    level: 1,
    exp: 0,
    hp: 1000,
    maxHp: 1000,
    mp: 100,
    maxMp: 100,
    stamina: 100,
    maxStamina: 100,
    swordIntent: 0,
    maxSwordIntent: 100,
    faction: null,
    skills: ['s1'],
    reputation: { mingjiao: 0, zhengpai: 0, jinyiwei: 0 },
    elementMastery: { wind: 0, fire: 0, water: 0, thunder: 0, ice: 0, poison: 0 },
  },
  deck: {
    id: `deck_${Date.now()}`,
    name: '初始卡组',
    cards: [],
    currentIndex: 0,
    drawnHand: [],
    discardPile: [],
  },
  world: {
    currentRegion: 'zhongyuan',
    playerPosition: { x: 300, y: 250 },
    triggeredCardIds: [],
    activeEventIds: [],
  },
  progress: {
    currentChapter: '第一章',
    completedChapters: [],
    unlockedRegions: ['zhongyuan'],
    achievements: [],
    stats: {
      battlesWon: 0,
      battlesLost: 0,
      cardsDrawn: 0,
      perfectBlocks: 0,
      perfectDodges: 0,
    },
  },
  meta: {
    createdAt: Date.now(),
    updatedAt: Date.now(),
    playtimeSeconds: 0,
    sceneBeforeClose: 'world',
  },
});

// ========== Storage Layer ==========
class SaveStorage {
  getSlotKey(slot: number): string {
    return `${SAVE_KEY_PREFIX}${slot}`;
  }

  /** 读取存档槽位 */
  loadSlot(slot: number): SaveData | null {
    try {
      const raw = localStorage.getItem(this.getSlotKey(slot));
      if (!raw) return null;
      const data = JSON.parse(raw) as SaveData;
      // 版本迁移检查
      return this.migrate(data);
    } catch (e) {
      console.error(`[Save] Failed to load slot ${slot}:`, e);
      return null;
    }
  }

  /** 保存存档槽位 */
  saveSlot(data: SaveData): void {
    data.meta.updatedAt = Date.now();
    data.version = SAVE_VERSION;
    try {
      localStorage.setItem(this.getSlotKey(data.slot), JSON.stringify(data));
    } catch (e) {
      console.error(`[Save] Failed to save slot ${data.slot}:`, e);
      // 存储满时尝试清理
      if (e instanceof DOMException && e.name === 'QuotaExceededError') {
        this.evictOldest();
        localStorage.setItem(this.getSlotKey(data.slot), JSON.stringify(data));
      }
    }
  }

  /** 删除存档 */
  deleteSlot(slot: number): void {
    localStorage.removeItem(this.getSlotKey(slot));
  }

  /** 获取所有存档槽信息 */
  listSlots(): SaveSlot[] {
    const slots: SaveSlot[] = [];
    for (let i = 1; i <= 3; i++) {
      const data = this.loadSlot(i);
      if (data) {
        slots.push({
          id: data.player.id,
          name: data.player.name,
          createdAt: data.meta.createdAt,
          updatedAt: data.meta.updatedAt,
          playtimeSeconds: data.meta.playtimeSeconds,
        });
      }
    }
    return slots;
  }

  /** 驱逐最旧的存档 */
  private evictOldest(): void {
    let oldest: { slot: number; time: number } | null = null;
    for (let i = 1; i <= 3; i++) {
      const data = this.loadSlot(i);
      if (data) {
        if (!oldest || data.meta.updatedAt < oldest.time) {
          oldest = { slot: i, time: data.meta.updatedAt };
        }
      }
    }
    if (oldest) {
      this.deleteSlot(oldest.slot);
      console.warn(`[Save] Evicted slot ${oldest.slot} due to quota exceeded`);
    }
  }

  /** 存档迁移 */
  private migrate(data: SaveData): SaveData {
    // 当前版本无需迁移，保留扩展接口
    return data;
  }
}

export const saveStorage = new SaveStorage();

// ========== Game State Manager ==========
export interface GameStateManager {
  current: SaveData | null;
  slot: number;
}

class SaveManager {
  private storage = saveStorage;
  private _current: SaveData | null = null;
  private _slot: number = 0;
  private _startTime: number = 0;
  private _lastSaveTime: number = 0;
  private _autoSaveTimer: ReturnType<typeof setInterval> | null = null;

  get current(): SaveData | null {
    return this._current;
  }

  get slot(): number {
    return this._slot;
  }

  /** 启动新游戏 */
  newGame(slot: number, playerName: string): SaveData {
    const data = DEFAULT_SAVE_DATA(slot, playerName);
    this.storage.saveSlot(data);
    this._current = data;
    this._slot = slot;
    this._startTime = Date.now();
    this._lastSaveTime = Date.now();
    return data;
  }

  /** 加载存档 */
  loadGame(slot: number): SaveData | null {
    const data = this.storage.loadSlot(slot);
    if (!data) return null;
    this._current = data;
    this._slot = slot;
    // 累加离线时间
    const offlineSeconds = Math.floor((Date.now() - data.meta.updatedAt) / 1000);
    data.meta.playtimeSeconds += Math.min(offlineSeconds, 3600 * 8); // 最多补8小时
    this._startTime = Date.now();
    this._lastSaveTime = Date.now();
    return data;
  }

  /** 保存当前进度 */
  save(): void {
    if (!this._current) return;
    this._current.meta.playtimeSeconds += Math.floor(
      (Date.now() - this._lastSaveTime) / 1000
    );
    this.storage.saveSlot(this._current);
    this._lastSaveTime = Date.now();
    console.log('[Save] Game saved');
  }

  /** 自动保存 */
  startAutoSave(intervalMs = 60000): void {
    this.stopAutoSave();
    this._autoSaveTimer = setInterval(() => {
      this.save();
    }, intervalMs);
  }

  stopAutoSave(): void {
    if (this._autoSaveTimer) {
      clearInterval(this._autoSaveTimer);
      this._autoSaveTimer = null;
    }
  }

  /** 关键节点保存 */
  saveCheckpoint(): void {
    this.save();
    // 额外保存到 backup
    if (this._current) {
      try {
        localStorage.setItem(`chronocards_backup_v1`, JSON.stringify(this._current));
      } catch {}
    }
  }

  /** 恢复备份 */
  restoreBackup(): SaveData | null {
    try {
      const raw = localStorage.getItem('chronocards_backup_v1');
      if (!raw) return null;
      const data = JSON.parse(raw) as SaveData;
      if (this._current) {
        this.storage.saveSlot(data);
      }
      return data;
    } catch {
      return null;
    }
  }

  /** 主动更新玩家数据 */
  updatePlayer(updater: (p: SavedPlayer) => void): void {
    if (!this._current) return;
    updater(this._current.player);
    // 不在这里自动保存，等下一个 autoSave 或 checkpoint
  }

  /** 主动更新世界数据 */
  updateWorld(updater: (w: SavedWorld) => void): void {
    if (!this._current) return;
    updater(this._current.world);
  }

  /** 主动更新进度 */
  updateProgress(updater: (p: SavedProgress) => void): void {
    if (!this._current) return;
    updater(this._current.progress);
  }

  /** 战斗胜利 */
  onBattleWon(): void {
    if (!this._current) return;
    this._current.progress.stats.battlesWon++;
    // 经验奖励
    this._current.player.exp += 50;
    // 检查升级
    if (this._current.player.exp >= this._current.player.level * 100) {
      this._current.player.level++;
      // 升级音效
      const sfx = new Audio('/assets/audio/levelup.mp3');
      sfx.volume = 0.6;
      sfx.play().catch(() => {});
      this._current.player.maxHp += 50;
      this._current.player.hp = this._current.player.maxHp;
      this._current.player.maxMp += 10;
      this._current.player.mp = this._current.player.maxMp;
    }
    this.save();
  }

  /** 完美格挡计数 */
  onPerfectBlock(): void {
    if (!this._current) return;
    this._current.progress.stats.perfectBlocks++;
  }

  /** 完美闪避计数 */
  onPerfectDodge(): void {
    if (!this._current) return;
    this._current.progress.stats.perfectDodges++;
  }

  /** 抽牌计数 */
  onCardDrawn(): void {
    if (!this._current) return;
    this._current.progress.stats.cardsDrawn++;
  }

  /** 标记卡牌触发 */
  onCardTriggered(cardId: string): void {
    if (!this._current) return;
    if (!this._current.world.triggeredCardIds.includes(cardId)) {
      this._current.world.triggeredCardIds.push(cardId);
    }
  }
}

export const saveManager = new SaveManager();
