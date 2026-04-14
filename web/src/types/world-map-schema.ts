// ChronoCards World Map API Schema Types (对齐 api_schema_world.json v2.0)

export type LocationType = 'city' | 'town' | 'village' | 'wilderness' | 'dungeon' | 'special';
export type ConnectionType = 'road' | 'river' | 'mountain' | 'teleport' | 'special';
export type Climate = '温带季风' | '亚热带季风' | '温带大陆性' | '热带沙漠' | '热带季风';

// ========== World ==========
export interface WorldOverview {
  id: string;
  name: string;
  description: string;
  total_regions: number;
  total_locations: number;
  regions: RegionSummary[];
  metadata: { version: string; last_updated: string };
}

export interface RegionSummary {
  id: string;
  name: string;
  display_order: number;
  danger_level: number;
  location_count: number;
}

export interface Region {
  id: string;
  name: string;
  display_order: number;
  description: string;
  climate: Climate;
  terrain: string;
  danger_level: number;
  tags: string[];
  connected_regions: string[];
  parent_world: string;
}

// ========== Location ==========
export interface Location {
  id: string;
  name: string;
  display_order: number;
  region_id: string;
  region_name: string;
  location_type: LocationType;
  location_type_ext?: string;
  description: string;
  danger_level: number;
  npc_count: number;
  available_dealers: string[];
  story_chapters: string[];
  tags: string[];
  unlocked: boolean;
  unlock_condition?: string;
}

export interface LocationDetail extends Location {
  dealers: DealerInfo[];
  connections: LocationConnection[];
  narrative?: {
    atmosphere: string;
    notable_npcs: string[];
    secrets: string;
  };
}

export interface LocationSummary {
  id: string;
  name: string;
  region_id: string;
  location_type: LocationType;
}

export interface LocationConnection {
  id: string;
  to_location: LocationSummary;
  connection_type: ConnectionType;
  distance: number;
  danger_level: number;
  description: string;
  blocked: boolean;
  blocked_reason?: string;
}

// ========== Dealer (World Map version) ==========
export interface DealerInfo {
  id: string;
  type: DealerApiType;
  name: string;
  location: string;
  description: string;
  interaction_prompt: string;
  weight: number;
}

export type DealerApiType = 
  | 'teahouse'
  | 'bounty_board'
  | 'inn'
  | 'merchant'
  | 'enemy'
  | 'dynamic_encounter'
  | 'environment'
  | 'training_grounds';

// ========== Navigation ==========
export interface NavigateRequest {
  target_location_id: string;
  use_optimal_route?: boolean;
  preferred_connection_id?: string;
}

export interface NavigateSuccess {
  success: true;
  message: string;
  travel_time: string;
  route: {
    path: LocationSummary[];
    total_distance: number;
    dangers: Array<{ location: string; danger_level: number; description: string }>;
  };
  new_location: Location;
  available_dealers: DealerInfo[];
  encounter_probability: { on_route: number; at_destination: number };
}

export interface NavigateError {
  success: false;
  error_code: 'LOCATION_NOT_FOUND' | 'LOCATION_LOCKED' | 'UNREACHABLE' | 'INSUFFICIENT_ITEMS' | 'PLAYER_NOT_FOUND' | 'ALREADY_AT_LOCATION';
  message: string;
  unlock_requirements?: { required_chapters: string[]; required_items: string[] };
  alternative_routes: LocationConnection[];
}

export type NavigateResponse = NavigateSuccess | NavigateError;

// ========== Player Location ==========
export interface PlayerLocationInfo {
  player_id: string;
  current_location: Location;
  current_region: Region;
  visited_count: { locations: number; regions: number };
  travel_stats: {
    total_travels: number;
    total_distance: number;
    last_travel_at: string;
  };
}

export interface VisitedHistory {
  player_id: string;
  visited_regions: Region[];
  visited_locations: Location[];
  exploration_rate: { regions: number; locations: number };
}

// ========== Pagination ==========
export interface Pagination {
  page: number;
  page_size: number;
  total: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
}

// ========== Error ==========
export interface ApiError {
  error: { code: string; message: string; details?: unknown };
}
