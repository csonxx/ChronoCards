package model

// ElementReactionRequest 元素反应计算请求
type ElementReactionRequest struct {
	AttackerElement ElementType `json:"attacker_element"`
	DefenderElement ElementType `json:"defender_element"`
	BaseDamage      float64     `json:"base_damage"`
	AttackerMastery int         `json:"attacker_mastery"`
	DefenderLevel   int         `json:"defender_level"`
}

// ElementReactionResponse 元素反应计算响应
type ElementReactionResponse struct {
	ReactionType            string           `json:"reaction_type"`
	SuppressionApplied      bool             `json:"suppression_applied"`
	SuppressionMultiplier   float64          `json:"suppression_multiplier"`
	FinalDamage             float64          `json:"final_damage"`
	StatusEffectsTriggered  []*StatusEffect  `json:"status_effects_triggered"`
	ReactionDescription     string           `json:"reaction_description"`
}

// ElementAttachRequest 元素附着请求
type ElementAttachRequest struct {
	TargetID   string       `json:"target_id"`
	TargetType string       `json:"target_type"`
	Element    ElementType  `json:"element"`
	AttackerID string       `json:"attacker_id"`
}

// ElementAttachResponse 元素附着响应
type ElementAttachResponse struct {
	TargetID           string                `json:"target_id"`
	CurrentAttachments []*ElementAttachment  `json:"current_attachments"`
	ReactionTriggered  bool                  `json:"reaction_triggered"`
	Reaction           *ElementReactionResponse `json:"reaction,omitempty"`
}

// BattleCalculateRequest 战斗伤害计算请求
type BattleCalculateRequest struct {
	AttackerID      string       `json:"attacker_id"`
	DefenderID      string       `json:"defender_id"`
	SkillID         string       `json:"skill_id"`
	SkillType       string       `json:"skill_type"`
	Element         ElementType  `json:"element"`
	BaseDamage      float64      `json:"base_damage"`
	AttackCount     int          `json:"attack_count"`
	IsCritical      bool         `json:"is_critical"`
	ElementMastery  int          `json:"element_mastery"`
	DefenderLevel  int          `json:"defender_level"`
	DefenderElement ElementType  `json:"defender_element"`
}

// BattleDamageResponse 战斗伤害响应
type BattleDamageResponse struct {
	FinalDamage           float64                  `json:"final_damage"`
	ElementalReaction     *ElementReactionResponse  `json:"elemental_reaction,omitempty"`
	SwordIntentGained     int                      `json:"sword_intent_gained"`
	MPConsumed            int                      `json:"mp_consumed"`
	NewDefenderAttachments []*ElementAttachment     `json:"new_defender_attachments,omitempty"`
	Description           string                   `json:"description"`
}

// DodgeRequest 闪避请求
type DodgeRequest struct {
	PlayerID       string `json:"player_id"`
	AttackTimingMs int    `json:"attack_timing_ms"`
	DodgeTimingMs  int    `json:"dodge_timing_ms"`
	StaminaAvail   int    `json:"stamina_available"`
}

// DodgeResponse 闪避响应
type DodgeResponse struct {
	Dodged             bool   `json:"dodged"`
	PerfectDodge       bool   `json:"perfect_dodge"`
	SwordIntentGained  int    `json:"sword_intent_gained"`
	StaminaCost        int    `json:"stamina_cost"`
	StaminaRemaining   int    `json:"stamina_remaining"`
	InvincibleMs      int    `json:"invincible_duration_ms"`
	Description        string `json:"description"`
}

// BlockRequest 格挡请求
type BlockRequest struct {
	PlayerID       string `json:"player_id"`
	AttackTimingMs int    `json:"attack_timing_ms"`
	BlockTimingMs  int    `json:"block_timing_ms"`
	StaminaAvail   int    `json:"stamina_available"`
}

// BlockResponse 格挡响应
type BlockResponse struct {
	Blocked           bool    `json:"blocked"`
	PerfectBlock      bool    `json:"perfect_block"`
	DamageReduction   float64 `json:"damage_reduction"`
	StaminaCost       int     `json:"stamina_cost"`
	StaminaRemaining  int     `json:"stamina_remaining"`
	CounterAvailable  bool    `json:"counter_available"`
	SwordIntentGained int     `json:"sword_intent_gained"`
	MPCost            int     `json:"mp_cost"`
	Description       string  `json:"description"`
}

// NarrativeTriggerRequest AI叙事触发请求
type NarrativeTriggerRequest struct {
	TriggerType string                `json:"trigger_type"`
	PlayerID    string                `json:"player_id,omitempty"`
	DealerID    string                `json:"dealer_id,omitempty"`
	CardID      string                `json:"card_id,omitempty"`
	Location    string                `json:"location,omitempty"`
	Context     NarrativeContext      `json:"context"`
	Constraints NarrativeConstraints `json:"constraints,omitempty"`
}

// NarrativeContext 叙事上下文
type NarrativeContext struct {
	WorldState       string `json:"world_state,omitempty"`
	FactionRelations map[string]int `json:"faction_relations,omitempty"`
	RecentEvents     []string `json:"recent_events,omitempty"`
	PlayerBackground string `json:"player_background,omitempty"`
	Tone             string `json:"tone,omitempty"`
}

// NarrativeConstraints 叙事约束
type NarrativeConstraints struct {
	MaxLength        int    `json:"max_length"`
	DialogueRequired bool   `json:"dialogue_required"`
	NPCName          string `json:"npc_name,omitempty"`
}

// DeckEventNarrativeRequest 卡组事件叙事请求
type DeckEventNarrativeRequest struct {
	Card         *Card `json:"card"`
	PlayerID     string `json:"player_id"`
	DealerID     string `json:"dealer_id,omitempty"`
	Location     string `json:"location,omitempty"`
	DeckPosition int    `json:"deck_position"`
}

// NarrativeContent AI生成的叙事内容
type NarrativeContent struct {
	Title     string           `json:"title"`
	Narrative string           `json:"narrative"`
	Dialogue  []DialogueEntry  `json:"dialogue,omitempty"`
	Choices   []ChoiceEntry    `json:"choices,omitempty"`
	Rewards   []RewardEntry    `json:"rewards,omitempty"`
	Metadata  NarrativeMeta    `json:"metadata"`
}

// DialogueEntry 对话条目
type DialogueEntry struct {
	Speaker string `json:"speaker"`
	Text    string `json:"text"`
	Tone    string `json:"tone,omitempty"`
}

// ChoiceEntry 选项条目
type ChoiceEntry struct {
	ID         string `json:"id"`
	Text       string `json:"text"`
	EffectHint string `json:"effect_hint,omitempty"`
}

// RewardEntry 奖励条目
type RewardEntry struct {
	Type  string `json:"type"`
	Value string `json:"value"`
}

// NarrativeMeta 叙事元数据
type NarrativeMeta struct {
	CardID      string `json:"card_id,omitempty"`
	TriggerType string `json:"trigger_type"`
	AIModel     string `json:"ai_model"`
	TokensUsed  int    `json:"tokens_used,omitempty"`
}

// UpdatePlayerRequest 更新玩家请求
type UpdatePlayerRequest struct {
	HPDelta          int                      `json:"hp_delta,omitempty"`
	MPDelta          int                      `json:"mp_delta,omitempty"`
	SwordIntentDelta int                      `json:"sword_intent_delta,omitempty"`
	StaminaDelta     int                      `json:"stamina_delta,omitempty"`
	ExpDelta         int                      `json:"exp_delta,omitempty"`
	LevelUp          bool                     `json:"level_up,omitempty"`
	SkillAdd         []string                 `json:"skill_add,omitempty"`
	ReputationDelta  *ReputationDeltaRequest  `json:"reputation_delta,omitempty"`
}

// ReputationDeltaRequest 声望变化请求
type ReputationDeltaRequest struct {
	Mingjiao int `json:"mingjiao"`
	Zhengpai int `json:"zhengpai"`
	Jinyiwei int `json:"jinyiwei"`
}

// CreatePlayerRequest 创建玩家请求
type CreatePlayerRequest struct {
	Name    string `json:"name"`
	Faction string `json:"faction,omitempty"`
}

// CreateDeckRequest 创建卡组请求
type CreateDeckRequest struct {
	PlayerID     string  `json:"player_id"`
	Name         string  `json:"name,omitempty"`
	InitialCards []*Card `json:"initial_cards,omitempty"`
}

// DrawRequest 抽牌请求
type DrawRequest struct {
	Count         int      `json:"count,omitempty"`
	ForceCardType CardType `json:"force_card_type,omitempty"`
}

// DrawResponse 抽牌响应
type DrawResponse struct {
	DrawnCards         []*Card   `json:"drawn_cards"`
	NextCardTypeHint   CardType `json:"next_card_type_hint,omitempty"`
	DeckExhausted      bool     `json:"deck_exhausted"`
}

// HandResponse 手牌响应
type HandResponse struct {
	Hand                []*Card `json:"hand"`
	TotalCardsRemaining int     `json:"total_cards_remaining"`
}

// DeckAdjustRequest 卡组调整请求
type DeckAdjustRequest struct {
	CardTypeToPromote CardType `json:"card_type_to_promote,omitempty"`
	Reason            string   `json:"reason"`
}
