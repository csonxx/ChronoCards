// ChronoCards API Schema Types (对齐 api_schema.json v1.0)
// 与后端 乃乃 确认契约

export type Element = 'wind' | 'fire' | 'water' | 'thunder' | 'ice' | 'poison';

export type CardApiType = 
  | 'main_story'    // 主线
  | 'side_story'    // 支线
  | 'skill_unlock'  // 技能解锁
  | 'stat_up'       // 数值提升
  | 'emotion'       // 情感
  | 'economy'       // 经济
  | 'blank';        // 空白

// ========== Player ==========
export interface Player {
  id: string;
  name: string;
  level: number;
  exp: number;
  hp: number;
  max_hp: number;
  mp: number;
  max_mp: number;
  stamina: number;
  max_stamina: number;
  sword_intent: number;
  element_mastery: ElementMastery;
  faction: string;
  reputation: Reputation;
  skills: string[];
  decks: string[];
  created_at: string;
  updated_at: string;
}

export interface ElementMastery {
  wind: number;
  fire: number;
  water: number;
  thunder: number;
  ice: number;
  poison: number;
}

export interface Reputation {
  mingjiao: number;
  zhengpai: number;
  jinyiwei: number;
}

export interface UpdatePlayerRequest {
  hp_delta?: number;
  mp_delta?: number;
  sword_intent_delta?: number;
  stamina_delta?: number;
  exp_delta?: number;
  level_up?: boolean;
  skill_add?: string[];
  reputation_delta?: ReputationDeltaRequest;
}

export interface ReputationDeltaRequest {
  mingjiao?: number;
  zhengpai?: number;
  jinyiwei?: number;
}

// ========== Deck ==========
export interface Deck {
  id: string;
  player_id: string;
  name: string;
  cards: Card[];
  current_index: number;
  drawn_hand: Card[];
  discard_pile: Card[];
  created_at: string;
}

export interface CreateDeckRequest {
  player_id: string;
  name?: string;
  initial_cards?: Card[];
}

export interface DrawRequest {
  count?: number;
  force_card_type?: CardApiType;
}

export interface DrawResponse {
  drawn_cards: Card[];
  next_card_type_hint?: string;
  deck_exhausted: boolean;
}

export interface HandResponse {
  hand: Card[];
  total_cards_remaining: number;
}

// ========== Card ==========
export interface Card {
  id: string;
  type: CardApiType;
  title: string;
  description: string;
  trigger_conditions?: string[];
  rewards?: CardRewards;
  ai_prompt_hints?: string[];
  priority?: number;
}

export interface CardRewards {
  exp?: number;
  hp_up?: number;
  mp_up?: number;
  skill_id?: string;
  reputation?: Reputation;
}

// ========== Battle ==========
export interface BattlePlayerState {
  player_id: string;
  hp: number;
  max_hp: number;
  mp: number;
  max_mp: number;
  stamina: number;
  max_stamina: number;
  sword_intent: number;
  element_attachments: ElementAttachment[];
  status_effects: StatusEffect[];
  active_skills: Skill[];
}

export interface ElementAttachment {
  element: Element;
  stacks: number;
  expires_at: string;
}

export interface StatusEffect {
  type: 'burn' | 'freeze' | 'poison' | 'paralyze' | 'slow';
  stacks: number;
  damage_per_second?: number;
  duration_seconds?: number;
  effects?: StatusEffectDetails;
}

export interface StatusEffectDetails {
  heal_reduction?: number;
  move_speed_reduction?: number;
  freezing?: boolean;
  paralyzing?: boolean;
}

export interface Skill {
  id: string;
  name: string;
  type: 'E' | 'Q' | 'passive' | 'ultimate';
  element?: Element;
  cooldown_seconds?: number;
  mp_cost?: number;
  sword_intent_cost?: number;
  base_damage?: number;
  description?: string;
}

export interface BattleActionRequest {
  player_id: string;
  action: 'dodge' | 'block' | 'counter' | 'attack';
  attack_timing_ms?: number;
  action_timing_ms?: number;
  stamina_available?: number;
  mp_available?: number;
  base_damage?: number;
  element?: Element;
  defender_element?: string;
  element_mastery?: number;
  defender_level?: number;
  is_critical?: boolean;
  counter_base_damage?: number;
}

export interface BattleActionResponse {
  action: string;
  success: boolean;
  dodge_result?: DodgeResponse;
  block_result?: BlockResponse;
  counter_damage?: number;
  attack_damage?: BattleDamageResponse;
  sword_intent_gained?: number;
  description?: string;
}

export interface BattleDamageResponse {
  final_damage: number;
  elemental_reaction?: ElementReactionResponse;
  sword_intent_gained?: number;
  mp_consumed?: number;
  new_defender_attachments?: ElementAttachment[];
  description?: string;
}

export interface DodgeResponse {
  dodged: boolean;
  perfect_dodge: boolean;
  sword_intent_gained?: number;
  stamina_cost?: number;
  stamina_remaining?: number;
  invincible_duration_ms?: number;
  description?: string;
}

export interface BlockResponse {
  blocked: boolean;
  perfect_block: boolean;
  damage_reduction?: number;
  stamina_cost?: number;
  stamina_remaining?: number;
  counter_available?: boolean;
  sword_intent_gained?: number;
  mp_cost?: number;
  description?: string;
}

export interface ElementReactionResponse {
  reaction_type: string;
  suppression_applied: boolean;
  suppression_multiplier: number;
  final_damage: number;
  status_effects_triggered?: StatusEffect[];
  reaction_description: string;
}

export interface BattleCalculateRequest {
  attacker_id: string;
  defender_id: string;
  skill_id?: string;
  skill_type?: string;
  element?: Element;
  base_damage: number;
  attack_count?: number;
  is_critical?: boolean;
  element_mastery?: number;
  defender_level?: number;
  defender_element?: string;
}

// ========== Narrative ==========
export type NarrativeTriggerType = 
  | 'dealer_interact'
  | 'card_drawn'
  | 'battle_start'
  | 'battle_end'
  | 'location_enter'
  | 'npc_met'
  | 'custom';

export interface NarrativeTriggerRequest {
  trigger_type: NarrativeTriggerType;
  player_id?: string;
  dealer_id?: string;
  card_id?: string;
  card_type?: string;
  card_title?: string;
  location?: string;
  context?: NarrativeContext;
  constraints?: NarrativeConstraints;
}

export interface NarrativeContext {
  world_state?: string;
  faction_relations?: Record<string, number>;
  recent_events?: string[];
  player_background?: string;
  tone?: 'epic' | 'intimate' | 'mysterious' | 'tense' | 'peaceful';
}

export interface NarrativeConstraints {
  max_length?: number;
  dialogue_required?: boolean;
  npc_name?: string;
}

export interface NarrativeContent {
  title: string;
  narrative: string;
  dialogue?: DialogueEntry[];
  choices?: ChoiceEntry[];
  rewards?: RewardEntry[];
  metadata?: NarrativeMetadata;
}

export interface DialogueEntry {
  speaker: string;
  text: string;
  tone?: string;
}

export interface ChoiceEntry {
  id: string;
  text: string;
  effect_hint?: string;
}

export interface RewardEntry {
  type: string;
  value: string;
}

export interface NarrativeMetadata {
  card_id?: string;
  trigger_type?: string;
  ai_model?: string;
  tokens_used?: number;
}

// ========== Dealer ==========
export type DealerApiType = 
  | 'teahouse'
  | 'bounty_board'
  | 'enemy'
  | 'inn'
  | 'merchant'
  | 'dynamic_encounter'
  | 'environment';

export interface Dealer {
  id: string;
  type: DealerApiType;
  name: string;
  location?: string;
  description?: string;
  interaction_prompt?: string;
  weight?: number;
}

export interface DealerTriggerRequest {
  player_id: string;
  deck_id: string;
  location?: string;
}

export interface DealerTriggerResponse {
  dealer_id: string;
  dealer_name: string;
  drawn_card: Card;
  deck_exhausted: boolean;
  hint?: string;
}
