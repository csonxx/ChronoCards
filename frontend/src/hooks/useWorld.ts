// 世界地图状态管理 Hook
// 管理当前大区/场景/导航状态，对接 worldApi

import { useState, useCallback, useEffect } from 'react';
import { worldApi } from '../services/api-client';
import type {
  WorldOverview,
  Region,
  Location,
  LocationDetail,
  LocationConnection,
  PlayerLocationInfo,
  NavigateResponse,
} from '../types/world-map-schema';
import { saveManager } from '../services/save-system';

export interface WorldState {
  overview: WorldOverview | null;
  currentRegion: Region | null;
  currentLocation: Location | null;
  locationDetail: LocationDetail | null;
  connections: LocationConnection[];
  nearbyDealers: LocationDetail['dealers'];
  visitedLocations: Set<string>;
  isLoading: boolean;
  error: string | null;
}

export interface WorldActions {
  loadWorldOverview: () => Promise<void>;
  loadRegion: (regionId: string) => Promise<void>;
  loadLocation: (locationId: string) => Promise<void>;
  navigate: (targetLocationId: string) => Promise<NavigateResponse>;
  refreshPlayerLocation: () => Promise<void>;
}

export function useWorld() {
  const [state, setState] = useState<WorldState>({
    overview: null,
    currentRegion: null,
    currentLocation: null,
    locationDetail: null,
    connections: [],
    nearbyDealers: [],
    visitedLocations: new Set(),
    isLoading: false,
    error: null,
  });

  // 初始化：加载世界概览
  const loadWorldOverview = useCallback(async () => {
    setState(s => ({ ...s, isLoading: true, error: null }));
    try {
      const overview = await worldApi.overview();
      // 默认加载第一个大区
      const firstRegion = overview.regions[0];
      setState(s => ({ ...s, overview, isLoading: false }));
      if (firstRegion) {
        const regionData = await worldApi.regionDetail(firstRegion.id);
        setState(s => ({
          ...s,
          currentRegion: regionData.region,
        }));
      }
    } catch (e) {
      setState(s => ({ ...s, isLoading: false, error: '加载世界信息失败' }));
    }
  }, []);

  // 加载大区
  const loadRegion = useCallback(async (regionId: string) => {
    setState(s => ({ ...s, isLoading: true, error: null }));
    try {
      const [regionData, playerLoc] = await Promise.all([
        worldApi.regionDetail(regionId),
        saveManager.current ? worldApi.playerLocation(saveManager.current.player.id).catch(() => null) : null,
      ]);
      setState(s => ({
        ...s,
        currentRegion: regionData.region,
        currentLocation: playerLoc?.current_location || null,
        locationDetail: null,
        connections: [],
        isLoading: false,
      }));
      // 更新存档位置
      if (playerLoc?.current_location) {
        saveManager.updateWorld(w => {
          w.currentRegion = playerLoc.current_location.region_id as any;
        });
      }
    } catch (e) {
      setState(s => ({ ...s, isLoading: false, error: '加载大区失败' }));
    }
  }, []);

  // 加载场景详情
  const loadLocation = useCallback(async (locationId: string) => {
    setState(s => ({ ...s, isLoading: true, error: null }));
    try {
      const [detail, connections] = await Promise.all([
        worldApi.locationDetail(locationId),
        worldApi.locationConnections(locationId),
      ]);
      setState(s => ({
        ...s,
        currentLocation: detail,
        locationDetail: detail,
        connections: connections.connections,
        nearbyDealers: detail.dealers,
        visitedLocations: new Set([...s.visitedLocations, locationId]),
        isLoading: false,
      }));
    } catch (e) {
      setState(s => ({ ...s, isLoading: false, error: '加载场景失败' }));
    }
  }, []);

  // 导航到新场景
  const navigate = useCallback(async (targetLocationId: string): Promise<NavigateResponse> => {
    if (!saveManager.current) {
      return {
        success: false,
        error_code: 'PLAYER_NOT_FOUND',
        message: '玩家未初始化',
        alternative_routes: [],
      };
    }
    try {
      const result = await worldApi.navigate(saveManager.current.player.id, {
        target_location_id: targetLocationId,
        use_optimal_route: true,
      });

      if (result.success) {
        // 更新存档
        saveManager.updateWorld(w => {
          w.currentRegion = result.new_location.region_id as any;
        });
        saveManager.save();

        // 更新UI状态
        setState(s => ({
          ...s,
          currentLocation: result.new_location,
          locationDetail: null,
          connections: [],
        }));
      }

      return result;
    } catch (e) {
      return {
        success: false,
        error_code: 'PLAYER_NOT_FOUND',
        message: '导航请求失败',
        alternative_routes: [],
      };
    }
  }, []);

  // 刷新玩家位置
  const refreshPlayerLocation = useCallback(async () => {
    if (!saveManager.current) return;
    try {
      const info = await worldApi.playerLocation(saveManager.current.player.id);
      setState(s => ({
        ...s,
        currentLocation: info.current_location,
        currentRegion: info.current_region,
      }));
    } catch {}
  }, []);

  // 启动时加载世界
  useEffect(() => {
    loadWorldOverview();
  }, [loadWorldOverview]);

  return { state, actions: { loadWorldOverview, loadRegion, loadLocation, navigate, refreshPlayerLocation } };
}

// 旧 Region 类型兼容（供 OpenWorld 现有代码使用）
export type { Region as GameRegion } from '../types/world-map-schema';
