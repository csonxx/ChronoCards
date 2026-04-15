package deck

import (
	"encoding/json"
	"slices"
	"time"
)

// LuzhePhase 陆喆事件线阶段
type LuzhePhase string

const (
	LuzhePhaseIdle         LuzhePhase = "idle"
	LuzhePhaseTrialStarted LuzhePhase = "trial_started"
	LuzhePhaseTrialPassed  LuzhePhase = "trial_passed"
	LuzhePhaseTrialFailed  LuzhePhase = "trial_failed"
	LuzhePhaseRevealed     LuzhePhase = "revealed"
	LuzhePhaseClimax       LuzhePhase = "climax"
	LuzhePhaseEnding       LuzhePhase = "ending"
)

// LuzheTrialScores 三项考验得分
type LuzheTrialScores struct {
	YiQi   int `json:"yiqi"`
	YongQi int `json:"yongqi"`
	ZhiHui int `json:"zhihui"`
}

// LuzhePlayerState 玩家在陆喆事件线中的状态
type LuzhePlayerState struct {
	PlayerID     string            `json:"player_id"`
	CharacterID  string            `json:"character_id"`
	CurrentPhase LuzhePhase        `json:"current_phase"`
	TrialCount   int               `json:"trial_count"`
	TrustLevel   int               `json:"trust_level"`
	TrialScores  *LuzheTrialScores `json:"trial_scores,omitempty"`
	Choices      []string          `json:"choices"`
	CardHistory  []string          `json:"card_history"`
	UpdatedAt    time.Time         `json:"updated_at"`
}

// LuzheCardDef 陆喆卡牌定义（内存缓存，对应数据库 character_cards 表）
type LuzheCardDef struct {
	ID                string   `json:"id"`
	CharacterID       string   `json:"character_id"`
	SubType           string   `json:"sub_type"`
	Title             string   `json:"title"`
	Description       string   `json:"description"`
	TriggerConditions []string `json:"trigger_conditions"`
	Rewards           struct {
		Exp        int `json:"exp,omitempty"`
		Reputation struct {
			Mingjiao int `json:"mingjiao,omitempty"`
			Zhengpai int `json:"zhengpai,omitempty"`
		} `json:"reputation,omitempty"`
		SkillID string `json:"skill_id,omitempty"`
	} `json:"rewards"`
	Priority int `json:"priority"`
}

// LuzheCardRegistry 陆喆卡牌注册表（内存缓存）
var LuzheCardRegistry = []LuzheCardDef{
	{
		ID:          "char-luzhe-001",
		CharacterID: "luzhe",
		SubType:     "encounter",
		Title:       "丐帮九袋",
		Description: "江南水乡，平阳客栈外，一个衣衫褴褛的老者正靠在墙角，看似随意，眼神却扫过每一个路过之人。",
		TriggerConditions: []string{"first_jiangnan_entry"},
		Priority:         10,
	},
	{
		ID:          "char-luzhe-002",
		CharacterID: "luzhe",
		SubType:     "trial",
		Title:       "江湖试炼",
		Description: "陆喆提出三个江湖考验：义气、勇气、智谋。玩家必须通过至少两项才能获得丐帮认可。",
		TriggerConditions: []string{"state:encountered"},
		Priority:         9,
	},
	{
		ID:          "char-luzhe-003",
		CharacterID: "luzhe",
		SubType:     "background",
		Title:       "身世之谜",
		Description: "通过考验后，陆喆私下透露：你父亲当年与丐帮有一段渊源……此事牵涉三十年前一桩旧案。",
		TriggerConditions: []string{"state:trial_passed"},
		Priority:         8,
	},
	{
		ID:          "char-luzhe-004",
		CharacterID: "luzhe",
		SubType:     "uprising",
		Title:       "丐帮内乱",
		Description: "丐帮内部两派分裂：保守派欲与明教暗中交易，激进派则要正面对抗。陆喆被架空，玩家必须选边站。",
		TriggerConditions: []string{"state:background", "main_progress>=30"},
		Priority:         7,
	},
	{
		ID:          "char-luzhe-005a",
		CharacterID: "luzhe",
		SubType:     "resolution",
		Title:       "正道结局：丐帮团结",
		Description: "玩家协助陆喆稳住帮主之位，丐帮成为正派联盟核心，明教势力被压制。",
		TriggerConditions: []string{"state:uprising", "choice:support_luzhe"},
		Priority:         6,
	},
	{
		ID:          "char-luzhe-005b",
		CharacterID: "luzhe",
		SubType:     "resolution",
		Title:       "暗流结局：丐帮分裂",
		Description: "帮内分裂不可挽回，丐帮元气大伤，陆喆远遁江湖。玩家独木难支，正派联盟摇摇欲坠。",
		TriggerConditions: []string{"state:uprising", "choice:abandon_luzhe"},
		Priority:         5,
	},
}

// LuzheStateMachine 陆喆状态机
type LuzheStateMachine struct{}

// NewLuzheStateMachine 创建状态机
func NewLuzheStateMachine() *LuzheStateMachine {
	return &LuzheStateMachine{}
}

// NewPlayerState 创建新玩家状态
func (sm *LuzheStateMachine) NewPlayerState(playerID string) *LuzhePlayerState {
	return &LuzhePlayerState{
		PlayerID:     playerID,
		CharacterID:  "luzhe",
		CurrentPhase: LuzhePhaseIdle,
		TrialCount:   0,
		TrustLevel:   0,
		TrialScores:  nil,
		Choices:      []string{},
		CardHistory:  []string{},
		UpdatedAt:    time.Now(),
	}
}

// ShouldTriggerEncounter 检查是否应触发首次遭遇
// 触发条件：首次进入江南水乡 或 首次进入苏州城 或 首次进入丐帮总舵
func (sm *LuzheStateMachine) ShouldTriggerEncounter(
	playerLocation *PlayerLocationContext,
	existingState *LuzhePlayerState,
) (bool, string) {
	// 如果已经遭遇过，不重复触发
	if existingState != nil && existingState.CurrentPhase != LuzhePhaseIdle {
		return false, ""
	}

	// 检查是否首次进入江南水乡大区
	hasFirstJiangnan := false
	if playerLocation.IsFirstVisitToRegion("region-jiangnan") {
		hasFirstJiangnan = true
	}

	// 检查是否首次进入苏州城
	hasFirstSuzhou := playerLocation.IsFirstVisitToLocation("loc-suzhou")

	// 检查是否首次进入丐帮总舵
	hasFirstGaibang := playerLocation.IsFirstVisitToLocation("loc-gaibang")

	if hasFirstSuzhou || hasFirstGaibang || hasFirstJiangnan {
		reason := "first_jiangnan_entry"
		if hasFirstSuzhou && hasFirstJiangnan {
			reason = "first_suzhou_entry"
		} else if hasFirstGaibang {
			reason = "first_gaibang_entry"
		}
		return true, reason
	}

	return false, ""
}

// GetNextCard 获取当前状态对应的下一张卡
func (sm *LuzheStateMachine) GetNextCard(state *LuzhePlayerState) *LuzheCardDef {
	phaseToSubType := map[LuzhePhase]string{
		LuzhePhaseIdle:        "encounter",
		LuzhePhaseTrialStarted: "trial",
		LuzhePhaseTrialPassed:  "background",
		LuzhePhaseRevealed:    "uprising",
		LuzhePhaseClimax:      "resolution",
	}

	targetSubType := phaseToSubType[state.CurrentPhase]
	if targetSubType == "" {
		return nil
	}

	for _, card := range LuzheCardRegistry {
		if card.SubType == targetSubType && sm.checkCardConditions(&card, state) {
			// 避免重复触发同一张卡
			if !slices.Contains(state.CardHistory, card.ID) {
				return &card
			}
		}
	}
	return nil
}

// checkCardConditions 检查卡牌触发条件是否满足
// 状态机设计采用 OR 判断：任一条件满足即可触发
func (sm *LuzheStateMachine) checkCardConditions(card *LuzheCardDef, state *LuzhePlayerState) bool {
	for _, cond := range card.TriggerConditions {
		// state:encountered — 状态为 idle 时满足
		if cond == "state:encountered" && state.CurrentPhase == LuzhePhaseIdle {
			return true
		}
		// state:trial_passed — 状态为 trial_passed 时满足
		if cond == "state:trial_passed" && state.CurrentPhase == LuzhePhaseTrialPassed {
			return true
		}
		// state:background — 状态为 revealed 时满足
		if cond == "state:background" && state.CurrentPhase == LuzhePhaseRevealed {
			return true
		}
		// state:uprising — 状态为 climax 时满足
		if cond == "state:uprising" && state.CurrentPhase == LuzhePhaseClimax {
			return true
		}
		// first_jiangnan_entry — 状态为 idle 时满足
		if cond == "first_jiangnan_entry" && state.CurrentPhase == LuzhePhaseIdle {
			return true
		}
	}
	return false
}

// AdvancePhase 推进状态机
func (sm *LuzheStateMachine) AdvancePhase(state *LuzhePlayerState, trigger string) *LuzhePlayerState {
	state.UpdatedAt = time.Now()

	switch state.CurrentPhase {
	case LuzhePhaseIdle:
		if trigger == "encounter_triggered" {
			state.CurrentPhase = LuzhePhaseTrialStarted
			state.TrustLevel += 10
			state.CardHistory = append(state.CardHistory, "char-luzhe-001")
		}
	case LuzhePhaseTrialStarted:
		if trigger == "trial_passed" {
			state.CurrentPhase = LuzhePhaseTrialPassed
			state.TrustLevel += 20
			state.CardHistory = append(state.CardHistory, "char-luzhe-002")
		} else if trigger == "trial_failed" {
			state.CurrentPhase = LuzhePhaseTrialFailed
			state.TrialCount++
			state.CardHistory = append(state.CardHistory, "char-luzhe-002")
		}
	case LuzhePhaseTrialFailed:
		// 考验失败后可以重试（最多3次）
		if trigger == "trial_retry" && state.TrialCount < 3 {
			state.CurrentPhase = LuzhePhaseTrialStarted
		} else if trigger == "trial_abandon" {
			// 放弃，降级为普通NPC（事件线结束）
			state.CurrentPhase = LuzhePhaseEnding
		}
	case LuzhePhaseTrialPassed:
		// 只有 trial_count >= 3 或 explicit_trigger 才允许推进到 Revealed
		if state.TrialCount >= 3 || trigger == "explicit_trigger" {
			state.CurrentPhase = LuzhePhaseRevealed
			state.TrustLevel += 30
			state.CardHistory = append(state.CardHistory, "char-luzhe-003")
		}
	case LuzhePhaseRevealed:
		state.CurrentPhase = LuzhePhaseClimax
		state.CardHistory = append(state.CardHistory, "char-luzhe-004")
	case LuzhePhaseClimax:
		if trigger == "choice:support_luzhe" {
			state.CurrentPhase = LuzhePhaseEnding
			state.TrustLevel += 50
			state.Choices = append(state.Choices, "support_luzhe")
			state.CardHistory = append(state.CardHistory, "char-luzhe-005a")
		} else if trigger == "choice:abandon_luzhe" {
			state.CurrentPhase = LuzhePhaseEnding
			state.Choices = append(state.Choices, "abandon_luzhe")
			state.CardHistory = append(state.CardHistory, "char-luzhe-005b")
		} else if trigger == "choice:negotiate" && state.TrustLevel >= 80 {
			state.CurrentPhase = LuzhePhaseEnding
			state.Choices = append(state.Choices, "negotiate")
		}
	case LuzhePhaseEnding:
		// 最终状态，不做变化
	}

	return state
}

// EvaluateTrial 评估考验结果（通过≥2项合格）
func (sm *LuzheStateMachine) EvaluateTrial(scores *LuzheTrialScores) bool {
	passed := 0
	if scores.YiQi >= 2 {
		passed++
	}
	if scores.YongQi >= 2 {
		passed++
	}
	if scores.ZhiHui >= 2 {
		passed++
	}
	return passed >= 2
}

// TrialScoresJSON 序列化考验分数
func (sm *LuzheStateMachine) TrialScoresJSON(scores *LuzheTrialScores) string {
	if scores == nil {
		return "{}"
	}
	data, _ := json.Marshal(scores)
	return string(data)
}

// ParseTrialScores 反序列化考验分数
func (sm *LuzheStateMachine) ParseTrialScores(jsonStr string) *LuzheTrialScores {
	if jsonStr == "" || jsonStr == "{}" {
		return nil
	}
	var scores LuzheTrialScores
	if err := json.Unmarshal([]byte(jsonStr), &scores); err != nil {
		return nil
	}
	return &scores
}

// IsEventLineComplete 检查事件线是否已完成
func (sm *LuzheStateMachine) IsEventLineComplete(state *LuzhePlayerState) bool {
	return state.CurrentPhase == LuzhePhaseEnding
}

// CanShowNegotiationOption 检查是否可显示协商选项（隐藏结局c）
func (sm *LuzheStateMachine) CanShowNegotiationOption(state *LuzhePlayerState) bool {
	return state.TrustLevel >= 80 && state.CurrentPhase == LuzhePhaseClimax
}

// LuzheStateTriggerResult 陆喆事件触发检查结果
type LuzheStateTriggerResult struct {
	ShouldTrigger bool           `json:"should_trigger"`
	Card         *LuzheCardDef   `json:"card,omitempty"`
	Reason       string          `json:"reason"`
}

// CheckTrigger 检查陆喆事件触发（供 WorldService 调用）
func (sm *LuzheStateMachine) CheckTrigger(
	playerLocation *PlayerLocationContext,
	existingState *LuzhePlayerState,
) *LuzheStateTriggerResult {
	result := &LuzheStateTriggerResult{ShouldTrigger: false}

	// 状态机已完成，不触发
	if existingState != nil && sm.IsEventLineComplete(existingState) {
		return result
	}

	// 首次触发检查
	if existingState == nil || existingState.CurrentPhase == LuzhePhaseIdle {
		shouldTrigger, reason := sm.ShouldTriggerEncounter(playerLocation, existingState)
		if shouldTrigger {
			result.ShouldTrigger = true
			result.Reason = reason
			// 获取对应的卡
			for _, card := range LuzheCardRegistry {
				if slices.Contains(card.TriggerConditions, "first_jiangnan_entry") ||
					slices.Contains(card.TriggerConditions, "first_suzhou_entry") ||
					slices.Contains(card.TriggerConditions, "first_gaibang_entry") {
					result.Card = &card
					break
				}
			}
			return result
		}
	}

	// 状态推进检查（自动触发下一张卡）
	if existingState != nil {
		nextCard := sm.GetNextCard(existingState)
		if nextCard != nil {
			result.ShouldTrigger = true
			result.Card = nextCard
			result.Reason = "state_advance"
		}
	}

	return result
}
