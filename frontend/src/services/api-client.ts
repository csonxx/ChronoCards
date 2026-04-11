// ChronoCards API Client
// 对接 api_schema.json v1.0

import type {
  Player,
  UpdatePlayerRequest,
  BattlePlayerState,
  Deck,
  CreateDeckRequest,
  DrawRequest,
  DrawResponse,
  HandResponse,
  Card,
  BattleActionRequest,
  BattleActionResponse,
  BattleDamageResponse,
  BattleCalculateRequest,
  DodgeResponse,
  BlockResponse,
  Dealer,
  DealerTriggerRequest,
  DealerTriggerResponse,
  NarrativeTriggerRequest,
  NarrativeContent,
  ElementReactionResponse,
  ElementAttachRequest,
  ElementAttachResponse,
  ElementReactionRequest,
} from '../types/api-schema';

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async request<T>(
    method: string,
    path: string,
    body?: unknown
  ): Promise<T> {
    const options: RequestInit = {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(import.meta.env.VITE_API_KEY && {
          'Authorization': `Bearer ${import.meta.env.VITE_API_KEY}`,
        }),
      },
    };

    if (body) {
      options.body = JSON.stringify(body);
    }

    const res = await fetch(`${this.baseUrl}${path}`, options);

    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: res.statusText }));
      throw new ApiError(res.status, err.message || 'API Error', path);
    }

    return res.json();
  }

  get<T>(path: string): Promise<T> {
    return this.request<T>('GET', path);
  }

  post<T>(path: string, body?: unknown): Promise<T> {
    return this.request<T>('POST', path, body);
  }

  patch<T>(path: string, body: unknown): Promise<T> {
    return this.request<T>('PATCH', path, body);
  }
}

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public path: string
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

// ========== World Map API ==========
export const worldApi = {
  /** 世界概览 */
  overview(): Promise<import('../types/world-map-schema').WorldOverview> {
    return api.get<import('../types/world-map-schema').WorldOverview>('/world');
  },

  /** 所有大区列表 */
  regions(params?: { danger_level?: number; climate?: string; tags?: string }): Promise<{
    world: string; world_name: string; total_regions: number;
    regions: import('../types/world-map-schema').Region[];
  }> {
    const qs = new URLSearchParams();
    if (params?.danger_level) qs.set('danger_level', String(params.danger_level));
    if (params?.climate) qs.set('climate', params.climate);
    if (params?.tags) qs.set('tags', params.tags);
    return api.get(`/world/regions${qs.size ? '?' + qs : ''}`);
  },

  /** 大区详情 */
  regionDetail(regionId: string, includeLocations = true): Promise<{
    region: import('../types/world-map-schema').Region;
    locations: import('../types/world-map-schema').Location[];
    stats: { total_locations: number; unlocked_count: number; visited_count: number };
  }> {
    return api.get(`/world/regions/${regionId}?include_locations=${includeLocations}`);
  },

  /** 大区下所有场景 */
  regionLocations(
    regionId: string,
    params?: { type?: string; unlocked_only?: boolean; danger_level?: number }
  ): Promise<{
    region: import('../types/world-map-schema').Region;
    locations: import('../types/world-map-schema').Location[];
    pagination: import('../types/world-map-schema').Pagination;
  }> {
    const qs = new URLSearchParams();
    if (params?.type) qs.set('type', params.type);
    if (params?.unlocked_only) qs.set('unlocked_only', 'true');
    if (params?.danger_level) qs.set('danger_level', String(params.danger_level));
    return api.get(`/world/regions/${regionId}/locations${qs.size ? '?' + qs : ''}`);
  },

  /** 搜索场景 */
  searchLocations(params: {
    q?: string; type?: string; region_id?: string; unlocked?: boolean;
    page?: number; page_size?: number;
  }): Promise<{
    total: number;
    locations: import('../types/world-map-schema').Location[];
    pagination: import('../types/world-map-schema').Pagination;
  }> {
    const qs = new URLSearchParams();
    if (params.q) qs.set('q', params.q);
    if (params.type) qs.set('type', params.type);
    if (params.region_id) qs.set('region_id', params.region_id);
    if (params.unlocked !== undefined) qs.set('unlocked', String(params.unlocked));
    if (params.page) qs.set('page', String(params.page));
    if (params.page_size) qs.set('page_size', String(params.page_size));
    return api.get(`/world/locations${qs.size ? '?' + qs : ''}`);
  },

  /** 场景详情 */
  locationDetail(locationId: string, includeDealers = true): Promise<import('../types/world-map-schema').LocationDetail> {
    return api.get(`/world/locations/${locationId}?include_dealers=${includeDealers}`);
  },

  /** 场景连通性 */
  locationConnections(locationId: string, params?: { connection_type?: string; max_danger?: number }): Promise<{
    current_location: import('../types/world-map-schema').Location;
    connections: import('../types/world-map-schema').LocationConnection[];
  }> {
    const qs = new URLSearchParams();
    if (params?.connection_type) qs.set('connection_type', params.connection_type);
    if (params?.max_danger) qs.set('max_danger', String(params.max_danger));
    return api.get(`/world/locations/${locationId}/connections${qs.size ? '?' + qs : ''}`);
  },

  /** 玩家当前位置 */
  playerLocation(playerId: string): Promise<import('../types/world-map-schema').PlayerLocationInfo> {
    return api.get(`/players/${playerId}/current-location`);
  },

  /** 导航到新场景 */
  navigate(playerId: string, data: import('../types/world-map-schema').NavigateRequest): Promise<import('../types/world-map-schema').NavigateResponse> {
    return api.post(`/players/${playerId}/navigate`, data);
  },

  /** 玩家访问历史 */
  visitedHistory(playerId: string, regionId?: string): Promise<import('../types/world-map-schema').VisitedHistory> {
    return api.get(`/players/${playerId}/visited${regionId ? '?region_id=' + regionId : ''}`);
  },
};

// ========== Singleton ==========
export const api = new ApiClient(BASE_URL);

// ========== Player API ==========
export const playerApi = {
  /** 获取玩家详情 */
  get(playerId: string): Promise<Player> {
    return api.get<Player>(`/players/${playerId}`);
  },

  /** 更新玩家状态 */
  update(playerId: string, data: UpdatePlayerRequest): Promise<Player> {
    return api.patch<Player>(`/players/${playerId}`, data);
  },

  /** 获取战斗状态快照 */
  getBattleState(playerId: string): Promise<BattlePlayerState> {
    return api.get<BattlePlayerState>(`/players/${playerId}/battle-state`);
  },

  /** 获取完整状态 */
  getStatus(playerId: string): Promise<Player> {
    return api.get<Player>(`/player/status/${playerId}`);
  },
};

// ========== Deck API ==========
export const deckApi = {
  /** 创建卡组 */
  create(data: CreateDeckRequest): Promise<Deck> {
    return api.post<Deck>('/decks', data);
  },

  /** 获取卡组详情 */
  get(deckId: string): Promise<Deck> {
    return api.get<Deck>(`/decks/${deckId}`);
  },

  /** 抽牌 */
  draw(deckId: string, data?: DrawRequest): Promise<DrawResponse> {
    return api.post<DrawResponse>(`/decks/${deckId}/draw`, data);
  },

  /** 获取当前手牌 */
  getHand(deckId: string): Promise<HandResponse> {
    return api.get<HandResponse>(`/decks/${deckId}/hand`);
  },

  /** 洗牌 */
  reshuffle(deckId: string): Promise<Deck> {
    return api.post<Deck>(`/decks/${deckId}/reshuffle`);
  },

  /** 动态调整卡组 */
  adjust(deckId: string, cardTypeToPromote?: string, reason?: string): Promise<Deck> {
    return api.post<Deck>(`/decks/${deckId}/adjust`, { card_type_to_promote: cardTypeToPromote, reason });
  },
};

// ========== Battle API ==========
export const battleApi = {
  /** 统一战斗动作 */
  action(data: BattleActionRequest): Promise<BattleActionResponse> {
    return api.post<BattleActionResponse>('/battle/action', data);
  },

  /** 计算战斗伤害 */
  calculate(data: BattleCalculateRequest): Promise<BattleDamageResponse> {
    return api.post<BattleDamageResponse>('/battle/calculate', data);
  },

  /** 闪避判定 */
  dodge(
    playerId: string,
    attackTimingMs: number,
    dodgeTimingMs: number,
    staminaAvailable: number
  ): Promise<DodgeResponse> {
    return api.post<DodgeResponse>('/battle/dodge', {
      player_id: playerId,
      attack_timing_ms: attackTimingMs,
      dodge_timing_ms: dodgeTimingMs,
      stamina_available: staminaAvailable,
    });
  },

  /** 格挡判定 */
  block(
    playerId: string,
    attackTimingMs: number,
    blockTimingMs: number,
    staminaAvailable: number
  ): Promise<BlockResponse> {
    return api.post<BlockResponse>('/battle/block', {
      player_id: playerId,
      attack_timing_ms: attackTimingMs,
      block_timing_ms: blockTimingMs,
      stamina_available: staminaAvailable,
    });
  },
};

// ========== Element API ==========
export const elementApi = {
  /** 附着元素 */
  attach(data: ElementAttachRequest): Promise<ElementAttachResponse> {
    return api.post<ElementAttachResponse>('/element/attach', data);
  },

  /** 计算元素反应 */
  reaction(data: ElementReactionRequest): Promise<ElementReactionResponse> {
    return api.post<ElementReactionResponse>('/element/reactions', data);
  },
};

// ========== Narrative API ==========
export const narrativeApi = {
  /** AI生成叙事内容 */
  generate(data: NarrativeTriggerRequest): Promise<NarrativeContent> {
    return api.post<NarrativeContent>('/narrative/generate', data);
  },

  /** 卡组事件叙事 */
  deckEvent(card: Card, playerId: string, dealerId?: string, location?: string): Promise<NarrativeContent> {
    return api.post<NarrativeContent>('/narrative/deck-event', {
      card,
      player_id: playerId,
      dealer_id: dealerId,
      location,
    });
  },
};

// ========== Dealer API ==========
export const dealerApi = {
  /** 获取发牌员列表 */
  list(): Promise<{ dealers: Dealer[] }> {
    return api.get<{ dealers: Dealer[] }>('/dealers');
  },

  /** 触发发牌员 */
  trigger(dealerId: string, data: DealerTriggerRequest): Promise<DealerTriggerResponse> {
    return api.post<DealerTriggerResponse>(`/dealers/${dealerId}/trigger`, data);
  },
};
