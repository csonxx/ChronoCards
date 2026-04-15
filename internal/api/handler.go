package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/csonxx/ChronoCards/internal/game/battle"
	gameplayer "github.com/csonxx/ChronoCards/internal/game/player"
	"github.com/csonxx/ChronoCards/internal/game/deck"
	"github.com/csonxx/ChronoCards/internal/game/element"
	"github.com/csonxx/ChronoCards/internal/game/equipment"
	"github.com/csonxx/ChronoCards/internal/game/item"
	"github.com/csonxx/ChronoCards/internal/game/martial_art"
	"github.com/csonxx/ChronoCards/internal/game/narrative"
	"github.com/csonxx/ChronoCards/internal/game/skill"
	"github.com/csonxx/ChronoCards/internal/model"
	"github.com/csonxx/ChronoCards/internal/store"
)

// Handler HTTP处理器
type Handler struct {
	store         store.StoreInterface
	deckSvc      *deck.Service
	narrativeSvc *narrative.Service
	elementCalc  *element.Calculator
	battleCalc   *battle.BattleCalculator
	skillSvc     *skill.Service
	inventorySvc *item.InventoryService
	shopSvc      *item.Service
	equipmentSvc *equipment.Service
	martialArtSvc *martial_art.Service
}

// NewHandler 创建处理器
func NewHandler(s store.StoreInterface) *Handler {
	return &Handler{
		store:         s,
		deckSvc:      deck.NewService(),
		narrativeSvc: narrative.NewService(),
		elementCalc:  element.NewCalculator(),
		battleCalc:   battle.NewBattleCalculator(),
		skillSvc:     skill.NewService(s),
		inventorySvc: item.NewInventoryService(s),
		shopSvc:      item.NewService(s),
		equipmentSvc: equipment.NewService(),
		martialArtSvc: martial_art.NewService(),
	}
}

// ---- 辅助方法 ----

func (h *Handler) json(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *Handler) error(w http.ResponseWriter, status int, msg string) {
	h.json(w, status, map[string]string{"error": msg})
}

func (h *Handler) notFound(w http.ResponseWriter) {
	h.error(w, http.StatusNotFound, "not found")
}

func (h *Handler) badRequest(w http.ResponseWriter, msg string) {
	h.error(w, http.StatusBadRequest, msg)
}

// ---- Health ----

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	h.json(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"version": "1.0.0",
	})
}

// ---- Player APIs ----

func (h *Handler) CreatePlayer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		Name    string `json:"name"`
		Faction string `json:"faction"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" {
		h.badRequest(w, "name is required")
		return
	}
	if req.Faction == "" {
		req.Faction = "none"
	}

	player := model.NewPlayer(req.Name, req.Faction)
	h.store.CreatePlayer(player)

	// 同时创建一副默认卡组
	deckObj := model.NewDeck(player.ID, "默认卡组", nil)
	h.store.CreateDeck(deckObj)
	player.Decks = append(player.Decks, deckObj.ID)
	h.store.UpdatePlayer(player)

	h.json(w, http.StatusOK, player)
}

func (h *Handler) GetPlayer(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("player_id")
	player, ok := h.store.GetPlayer(id)
	if !ok {
		h.notFound(w)
		return
	}
	h.json(w, http.StatusOK, player)
}

func (h *Handler) UpdatePlayer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		h.badRequest(w, "method not allowed")
		return
	}

	id := r.PathValue("player_id")
	player, ok := h.store.GetPlayer(id)
	if !ok {
		h.notFound(w)
		return
	}

	var req model.UpdatePlayerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	// 应用变化
	if req.HPDelta != 0 {
		player.HP += req.HPDelta
		if player.HP > player.MaxHP {
			player.HP = player.MaxHP
		}
		if player.HP < 0 {
			player.HP = 0
		}
	}
	if req.MPDelta != 0 {
		player.MP += req.MPDelta
		if player.MP > player.MaxMP {
			player.MP = player.MaxMP
		}
		if player.MP < 0 {
			player.MP = 0
		}
	}
	if req.SwordIntentDelta != 0 {
		player.SwordIntent += req.SwordIntentDelta
		if player.SwordIntent > 100 {
			player.SwordIntent = 100
		}
		if player.SwordIntent < 0 {
			player.SwordIntent = 0
		}
	}
	if req.StaminaDelta != 0 {
		player.Stamina += req.StaminaDelta
		if player.Stamina > player.MaxStamina {
			player.Stamina = player.MaxStamina
		}
		if player.Stamina < 0 {
			player.Stamina = 0
		}
	}
	if req.ExpDelta != 0 {
		player.Exp += req.ExpDelta
	}
	if req.LevelUp {
		player.Level++
	}
	if req.SkillAdd != nil {
		player.Skills = append(player.Skills, req.SkillAdd...)
	}
	if req.ReputationDelta != nil {
		player.Reputation.Mingjiao += req.ReputationDelta.Mingjiao
		player.Reputation.Zhengpai += req.ReputationDelta.Zhengpai
		player.Reputation.Jinyiwei += req.ReputationDelta.Jinyiwei
	}
	player.UpdatedAt = time.Now()

	h.store.UpdatePlayer(player)
	h.json(w, http.StatusOK, player)
}

func (h *Handler) GetBattleState(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("player_id")
	player, ok := h.store.GetPlayer(id)
	if !ok {
		h.notFound(w)
		return
	}

	state := &model.BattlePlayerState{
		PlayerID:    player.ID,
		HP:         player.HP,
		MaxHP:      player.MaxHP,
		MP:         player.MP,
		MaxMP:      player.MaxMP,
		Stamina:    player.Stamina,
		MaxStamina: player.MaxStamina,
		SwordIntent: player.SwordIntent,
	}

	h.json(w, http.StatusOK, state)
}

// ---- Deck APIs ----

func (h *Handler) CreateDeck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		PlayerID     string         `json:"player_id"`
		Name         string         `json:"name"`
		InitialCards []*model.Card  `json:"initial_cards"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerID == "" {
		h.badRequest(w, "player_id is required")
		return
	}
	if req.Name == "" {
		req.Name = "默认卡组"
	}

	// 检查玩家存在
	if _, ok := h.store.GetPlayer(req.PlayerID); !ok {
		h.notFound(w)
		return
	}

	deckObj := model.NewDeck(req.PlayerID, req.Name, req.InitialCards)
	h.store.CreateDeck(deckObj)

	// 更新玩家的卡组列表
	player, _ := h.store.GetPlayer(req.PlayerID)
	player.Decks = append(player.Decks, deckObj.ID)
	h.store.UpdatePlayer(player)

	h.json(w, http.StatusOK, deckObj)
}

func (h *Handler) GetDeck(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("deck_id")
	d, ok := h.store.GetDeck(id)
	if !ok {
		h.notFound(w)
		return
	}
	h.json(w, http.StatusOK, d)
}

func (h *Handler) DrawCard(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	id := r.PathValue("deck_id")
	d, ok := h.store.GetDeck(id)
	if !ok {
		h.notFound(w)
		return
	}

	var req struct {
		Count          int            `json:"count"`
		ForceCardType  model.CardType `json:"force_card_type"`
	}
	json.NewDecoder(r.Body).Decode(&req)
	if req.Count < 1 {
		req.Count = 1
	}
	if req.Count > 3 {
		req.Count = 3
	}

	// 如果强制指定了卡牌类型，先调整卡组
	if req.ForceCardType != "" {
		d.AdjustDeck(req.ForceCardType)
	}

	cards, exhausted := d.Draw(req.Count)

	// 获取下一张提示
	var nextHint model.CardType
	if !exhausted && d.CurrentIndex < len(d.Cards) {
		nextHint = d.Cards[d.CurrentIndex].Type
	}

	h.store.UpdateDeck(d)

	h.json(w, http.StatusOK, map[string]interface{}{
		"drawn_cards":         cards,
		"next_card_type_hint": nextHint,
		"deck_exhausted":      exhausted,
	})
}

func (h *Handler) GetHand(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("deck_id")
	d, ok := h.store.GetDeck(id)
	if !ok {
		h.notFound(w)
		return
	}

	remaining := len(d.Cards) - d.CurrentIndex
	h.json(w, http.StatusOK, map[string]interface{}{
		"hand":                 d.DrawnHand,
		"total_cards_remaining": remaining,
	})
}

func (h *Handler) ReshuffleDeck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	id := r.PathValue("deck_id")
	d, ok := h.store.GetDeck(id)
	if !ok {
		h.notFound(w)
		return
	}

	d.Reshuffle()
	h.store.UpdateDeck(d)
	h.json(w, http.StatusOK, d)
}

func (h *Handler) AdjustDeck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	id := r.PathValue("deck_id")
	d, ok := h.store.GetDeck(id)
	if !ok {
		h.notFound(w)
		return
	}

	var req struct {
		CardTypeToPromote model.CardType `json:"card_type_to_promote"`
		Reason            string         `json:"reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	if req.CardTypeToPromote != "" {
		d.AdjustDeck(req.CardTypeToPromote)
	} else {
		h.deckSvc.AdjustDeckForPlayerState(d, req.Reason)
	}

	h.store.UpdateDeck(d)
	h.json(w, http.StatusOK, d)
}

// ---- Element APIs ----

func (h *Handler) CalculateReaction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		AttackerElement model.ElementType `json:"attacker_element"`
		DefenderElement model.ElementType `json:"defender_element"`
		BaseDamage      float64           `json:"base_damage"`
		AttackerMastery int               `json:"attacker_mastery"`
		DefenderLevel   int               `json:"defender_level"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	result := h.elementCalc.CalculateReaction(req.AttackerElement, req.DefenderElement, req.BaseDamage, req.AttackerMastery, req.DefenderLevel)
	h.json(w, http.StatusOK, result)
}

func (h *Handler) AttachElement(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		TargetID   string            `json:"target_id"`
		TargetType string            `json:"target_type"`
		Element    model.ElementType  `json:"element"`
		AttackerID string            `json:"attacker_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	// 简化：直接在响应中标记是否触发反应
	// 实际状态存储在 BattlePlayerState 中
	h.json(w, http.StatusOK, map[string]interface{}{
		"target_id":           req.TargetID,
		"current_attachments": []model.ElementAttachment{
			{Element: req.Element, Stacks: 1, ExpiresAt: time.Now().Add(10 * time.Second)},
		},
		"reaction_triggered": false,
	})
}

// ---- Battle APIs ----

func (h *Handler) CalculateDamage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		AttackerID     string            `json:"attacker_id"`
		DefenderID     string            `json:"defender_id"`
		SkillID        string            `json:"skill_id"`
		SkillType      string            `json:"skill_type"`
		Element        model.ElementType `json:"element"`
		BaseDamage     float64           `json:"base_damage"`
		AttackCount    int               `json:"attack_count"`
		IsCritical     bool              `json:"is_critical"`
		ElementMastery int               `json:"element_mastery"`
		DefenderLevel  int               `json:"defender_level"`
		DefenderElement model.ElementType `json:"defender_element"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	if req.AttackCount < 1 {
		req.AttackCount = 1
	}

	// 计算元素精通加成
	masteryBonus := h.battleCalc.CalculateElementalMasteryBonus(req.ElementMastery, req.DefenderLevel)

	// 计算元素反应
	var reactionResult *model.ElementReactionResponse
	if req.DefenderElement != "" && req.Element != "" {
		reactionResult = h.elementCalc.CalculateReaction(req.Element, req.DefenderElement, req.BaseDamage, req.ElementMastery, req.DefenderLevel)
	}

	reactionMult := 1.0
	if reactionResult != nil {
		reactionMult = reactionResult.SuppressionMultiplier
	}

	finalDamage := h.battleCalc.CalculateDamage(req.BaseDamage, 1.0, reactionMult, req.IsCritical, masteryBonus) * float64(req.AttackCount)

	// 剑意值获得
	siGained := 0
	if req.IsCritical {
		siGained = 10
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"final_damage":           finalDamage,
		"elemental_reaction":    reactionResult,
		"sword_intent_gained":   siGained,
		"mp_consumed":           0,
		"new_defender_attachments": nil,
		"description":           "造成 " + strconv.FormatFloat(finalDamage, 'f', 1, 64) + " 点伤害",
	})
}

func (h *Handler) Dodge(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		PlayerID       string `json:"player_id"`
		AttackTimingMs int    `json:"attack_timing_ms"`
		DodgeTimingMs  int    `json:"dodge_timing_ms"`
		StaminaAvail   int    `json:"stamina_available"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	result := h.battleCalc.Dodge(req.AttackTimingMs, req.DodgeTimingMs, req.StaminaAvail)
	h.json(w, http.StatusOK, result)
}

func (h *Handler) Block(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		PlayerID       string `json:"player_id"`
		AttackTimingMs int    `json:"attack_timing_ms"`
		BlockTimingMs  int    `json:"block_timing_ms"`
		StaminaAvail   int    `json:"stamina_available"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	// 判断是否在完美格挡窗口
	timeDiff := req.BlockTimingMs - req.AttackTimingMs
	if timeDiff < 0 {
		timeDiff = -timeDiff
	}
	isPerfect := timeDiff <= 150 // 0.15秒 = 150毫秒

	result := h.battleCalc.Block(req.AttackTimingMs, req.BlockTimingMs, req.StaminaAvail, isPerfect)
	h.json(w, http.StatusOK, result)
}

// ---- Narrative APIs ----

func (h *Handler) TriggerNarrative(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req narrative.TriggerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request")
		return
	}

	content, err := h.narrativeSvc.Generate(&req)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.json(w, http.StatusOK, content)
}

func (h *Handler) DeckEventNarrative(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		Card        *model.Card `json:"card"`
		PlayerID    string      `json:"player_id"`
		DealerID    string      `json:"dealer_id"`
		Location    string      `json:"location"`
		DeckPosition int       `json:"deck_position"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Card == nil {
		h.badRequest(w, "card is required")
		return
	}

	narrativeReq := &narrative.TriggerRequest{
		TriggerType: narrative.TriggerCardDrawn,
		PlayerID:    req.PlayerID,
		DealerID:    req.DealerID,
		CardID:      req.Card.ID,
		CardType:    string(req.Card.Type),
		CardTitle:   req.Card.Title,
		Location:    req.Location,
		Context: narrative.NarrativeContext{
			WorldState:    "明教崛起，天下将乱",
			Tone:          "mysterious",
			RecentEvents:  []string{},
		},
		Constraints: narrative.NarrativeConstraints{
			MaxLength:        500,
			DialogueRequired: true,
		},
	}

	content, err := h.narrativeSvc.Generate(narrativeReq)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.json(w, http.StatusOK, content)
}

// ---- Dealer APIs ----

func (h *Handler) ListDealers(w http.ResponseWriter, r *http.Request) {
	dealers := h.store.ListDealers()
	h.json(w, http.StatusOK, map[string]interface{}{
		"dealers": dealers,
	})
}

func (h *Handler) CreateDealer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		Type               string `json:"type"`
		Name               string `json:"name"`
		Location           string `json:"location"`
		Description        string `json:"description"`
		InteractionPrompt  string `json:"interaction_prompt"`
		Weight             int    `json:"weight"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Type == "" || req.Name == "" {
		h.badRequest(w, "type and name are required")
		return
	}

	dealer := model.NewDealer(model.DealerType(req.Type), req.Name, req.Location, req.Description)
	if req.InteractionPrompt != "" {
		dealer.InteractionPrompt = req.InteractionPrompt
	}
	if req.Weight > 0 {
		dealer.Weight = req.Weight
	}

	h.store.CreateDealer(dealer)
	h.json(w, http.StatusOK, dealer)
}

func (h *Handler) TriggerDealer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	dealerID := r.PathValue("dealer_id")
	dealer, ok := h.store.GetDealer(dealerID)
	if !ok {
		h.notFound(w)
		return
	}

	var req struct {
		PlayerID string `json:"player_id"`
		DeckID  string `json:"deck_id"`
		Location string `json:"location"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerID == "" || req.DeckID == "" {
		h.badRequest(w, "player_id and deck_id are required")
		return
	}

	deckObj, ok := h.store.GetDeck(req.DeckID)
	if !ok {
		h.notFound(w)
		return
	}

	result := h.deckSvc.TriggerWithWeight(dealer, deckObj)
	h.store.UpdateDeck(deckObj)

	h.json(w, http.StatusOK, map[string]interface{}{
		"dealer_id":      result.DealerID,
		"dealer_name":    result.DealerName,
		"drawn_card":     result.DrawnCard,
		"deck_exhausted": result.DeckExhausted,
		"hint":           result.Hint,
	})
}

// ---- Battle Action (Unified) ----

// BattleActionRequest 统一战斗动作请求
type BattleActionRequest struct {
	PlayerID       string `json:"player_id"`
	Action         string `json:"action"` // dodge, block, counter, attack
	AttackTimingMs int    `json:"attack_timing_ms,omitempty"`
	ActionTimingMs int    `json:"action_timing_ms,omitempty"` // 玩家闪避/格挡输入时机
	StaminaAvail   int    `json:"stamina_available,omitempty"`
	MPAvail        int    `json:"mp_available,omitempty"`
	// Attack params
	BaseDamage      float64           `json:"base_damage,omitempty"`
	Element         model.ElementType `json:"element,omitempty"`
	DefenderElement model.ElementType `json:"defender_element,omitempty"`
	ElementMastery  int               `json:"element_mastery,omitempty"`
	DefenderLevel   int               `json:"defender_level,omitempty"`
	IsCritical      bool              `json:"is_critical,omitempty"`
	// Counter params
	CounterBaseDamage float64 `json:"counter_base_damage,omitempty"`
}

// BattleActionResponse 统一战斗动作响应
type BattleActionResponse struct {
	Action         string  `json:"action"`
	Success        bool    `json:"success"`
	DodgeResult    *battle.DodgeResult   `json:"dodge_result,omitempty"`
	BlockResult    *battle.BlockResult   `json:"block_result,omitempty"`
	CounterDamage  float64 `json:"counter_damage,omitempty"`
	AttackDamage   *model.BattleDamageResponse `json:"attack_damage,omitempty"`
	SwordIntentGained int `json:"sword_intent_gained"`
	Description    string  `json:"description"`
}

// BattleAction 统一战斗动作处理
func (h *Handler) BattleAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req BattleActionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	resp := &BattleActionResponse{
		Action:  req.Action,
		Success: false,
	}

	player, ok := h.store.GetPlayer(req.PlayerID)
	if !ok {
		h.notFound(w)
		return
	}

	switch req.Action {
	case "dodge":
		// 闪避判定
		if req.StaminaAvail < 20 {
			resp.Description = "体力不足，无法闪避"
			h.json(w, http.StatusOK, resp)
			return
		}
		result := h.battleCalc.Dodge(req.AttackTimingMs, req.ActionTimingMs, req.StaminaAvail)
		resp.Success = result.Dodged
		resp.DodgeResult = result
		resp.SwordIntentGained = result.SwordIntentGained
		resp.Description = result.Description

		// 更新玩家剑意值
		if result.SwordIntentGained > 0 {
			player.AddSwordIntent(result.SwordIntentGained)
			h.store.UpdatePlayer(player)
		}

	case "block":
		// 格挡判定
		timeDiff := req.ActionTimingMs - req.AttackTimingMs
		if timeDiff < 0 {
			timeDiff = -timeDiff
		}
		isPerfect := timeDiff <= 150
		result := h.battleCalc.Block(req.AttackTimingMs, req.ActionTimingMs, req.StaminaAvail, isPerfect)
		resp.Success = result.Blocked
		resp.BlockResult = result
		resp.SwordIntentGained = result.SwordIntentGained
		resp.Description = result.Description

		// 更新玩家剑意值
		if result.SwordIntentGained > 0 {
			player.AddSwordIntent(result.SwordIntentGained)
			h.store.UpdatePlayer(player)
		}

	case "counter":
		// 反击（需要在完美格挡后触发）
		if req.CounterBaseDamage <= 0 {
			req.CounterBaseDamage = 50 // 默认反击伤害
		}
		counterDamage := h.battleCalc.CounterDamage(req.CounterBaseDamage)
		resp.Success = true
		resp.CounterDamage = counterDamage
		resp.SwordIntentGained = 5
		resp.Description = "反击成功，造成 " + strconv.FormatFloat(counterDamage, 'f', 1, 64) + " 点伤害"

		player.AddSwordIntent(5)
		h.store.UpdatePlayer(player)

	case "attack":
		// 攻击计算（包含元素反应）
		if req.BaseDamage <= 0 {
			req.BaseDamage = 30
		}
		if req.AttackTimingMs <= 0 {
			req.AttackTimingMs = 500
		}

		// 计算元素精通加成
		masteryBonus := h.battleCalc.CalculateElementalMasteryBonus(req.ElementMastery, req.DefenderLevel)

		// 计算元素反应
		var reactionResult *model.ElementReactionResponse
		if req.DefenderElement != "" && req.Element != "" {
			reactionResult = h.elementCalc.CalculateReaction(req.Element, req.DefenderElement, req.BaseDamage, req.ElementMastery, req.DefenderLevel)
		}

		reactionMult := 1.0
		if reactionResult != nil {
			reactionMult = reactionResult.SuppressionMultiplier
		}

		finalDamage := h.battleCalc.CalculateDamage(req.BaseDamage, 1.0, reactionMult, req.IsCritical, masteryBonus)

		// 剑意值获得
		siGained := 0
		if req.IsCritical {
			siGained = 10
		}

		damageResp := &model.BattleDamageResponse{
			FinalDamage:       finalDamage,
			ElementalReaction: reactionResult,
			SwordIntentGained: siGained,
			MPConsumed:        0,
			Description:       "造成 " + strconv.FormatFloat(finalDamage, 'f', 1, 64) + " 点伤害",
		}

		resp.Success = true
		resp.AttackDamage = damageResp
		resp.SwordIntentGained = siGained
		resp.Description = damageResp.Description

		if siGained > 0 {
			player.AddSwordIntent(siGained)
			h.store.UpdatePlayer(player)
		}

	default:
		h.badRequest(w, "invalid action: must be dodge, block, counter, or attack")
		return
	}

	h.json(w, http.StatusOK, resp)
}

// ---- Player Status (Simplified) ----

// LevelUp 玩家手动触发升级判定
func (h *Handler) LevelUp(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	id := r.PathValue("player_id")
	player, ok := h.store.GetPlayer(id)
	if !ok {
		h.notFound(w)
		return
	}

	// 判断是否有足够的经验升级（AddExp(0)只检查不添加）
	fromLevel := player.Level
	leveledUp, times, newLevel := player.AddExp(0)

	if !leveledUp {
		h.json(w, http.StatusOK, map[string]interface{}{
			"leveled_up":   false,
			"level":        player.Level,
			"exp":          player.Exp,
			"exp_needed":   gameplayer.CalcExpToNextLevel(player.Level),
			"message":      "经验不足，无法升级",
		})
		return
	}

	h.store.UpdatePlayer(player)

	h.json(w, http.StatusOK, map[string]interface{}{
		"leveled_up":    true,
		"level_up_times": times,
		"from_level":    fromLevel,
		"new_level":     newLevel,
		"exp":           player.Exp,
		"max_hp":        player.MaxHP,
		"max_mp":        player.MaxMP,
		"max_stamina":   player.MaxStamina,
		"message":       "升级成功！等级提升至 " + strconv.Itoa(newLevel),
	})
}

// GetPlayerStatus 获取玩家状态（简化版）
func (h *Handler) GetPlayerStatus(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("player_id")
	player, ok := h.store.GetPlayer(id)
	if !ok {
		h.notFound(w)
		return
	}

	// 返回完整的玩家状态
	status := map[string]interface{}{
		"player_id":     player.ID,
		"name":          player.Name,
		"level":         player.Level,
		"exp":           player.Exp,
		// 战斗相关核心数值
		"hp":            player.HP,
		"max_hp":        player.MaxHP,
		"mp":            player.MP,
		"max_mp":        player.MaxMP,
		"sword_intent":  player.SwordIntent,
		"stamina":       player.Stamina,
		"max_stamina":   player.MaxStamina,
		// 元素精通
		"element_mastery": player.ElementMastery,
		// 阵营声望
		"reputation":    player.Reputation,
		// 技能列表
		"skills":        player.Skills,
		// 阵营
		"faction":       player.Faction,
		// 拥有的卡组
		"decks":         player.Decks,
	}

	h.json(w, http.StatusOK, status)
}

// ---- Draw Card (Standalone) ----

// DrawCardStandalone 独立抽牌接口
func (h *Handler) DrawCardStandalone(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req struct {
		DeckID         string            `json:"deck_id"`
		Count          int               `json:"count"`
		ForceCardType  model.CardType    `json:"force_card_type"`
		DealerID       string            `json:"dealer_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.DeckID == "" {
		h.badRequest(w, "deck_id is required")
		return
	}

	d, ok := h.store.GetDeck(req.DeckID)
	if !ok {
		h.notFound(w)
		return
	}

	if req.Count < 1 {
		req.Count = 1
	}
	if req.Count > 3 {
		req.Count = 3
	}

	// 如果指定了发牌员，先触发发牌员效果
	var dealer *model.Dealer
	if req.DealerID != "" {
		dealer, _ = h.store.GetDealer(req.DealerID)
	}

	// 如果强制指定了卡牌类型，先调整卡组
	if req.ForceCardType != "" {
		d.AdjustDeck(req.ForceCardType)
	} else if dealer != nil {
		// 根据发牌员类型调整卡组
		h.deckSvc.AdjustDeckByDealer(d, dealer)
	}

	cards, exhausted := d.Draw(req.Count)

	// 获取下一张提示
	var nextHint model.CardType
	if !exhausted && d.CurrentIndex < len(d.Cards) {
		nextHint = d.Cards[d.CurrentIndex].Type
	}

	h.store.UpdateDeck(d)

	// 如果有发牌员，获取发牌员提示
	var hint string
	if dealer != nil {
		if len(cards) > 0 {
			hint = h.deckSvc.GetHintForDealer(dealer, cards[0])
		}
	} else if len(cards) > 0 {
		hint = "你抽到了「" + cards[0].Title + "」"
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"drawn_cards":          cards,
		"next_card_type_hint": nextHint,
		"deck_exhausted":      exhausted,
		"dealer_hint":         hint,
		"cards_remaining":     len(d.Cards) - d.CurrentIndex,
	})
}

// ---- Narrative Generate ----

// GenerateNarrative AI生成叙事内容
func (h *Handler) GenerateNarrative(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	var req narrative.TriggerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	content, err := h.narrativeSvc.Generate(&req)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.json(w, http.StatusOK, content)
}

// ---- Skill APIs ----

// LearnSkill 玩家学习新技能
func (h *Handler) LearnSkill(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")
	player, ok := h.store.GetPlayer(playerID)
	if !ok {
		h.notFound(w)
		return
	}

	var req struct {
		SkillID string `json:"skill_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.SkillID == "" {
		h.badRequest(w, "skill_id is required")
		return
	}

	err := h.skillSvc.LearnSkill(player, req.SkillID)
	if err != nil {
		h.badRequest(w, err.Error())
		return
	}
	h.json(w, http.StatusOK, map[string]interface{}{
		"message": "技能学习成功",
		"skills":  player.Skills,
	})
}

// ListSkills 列出玩家已学会的技能（带冷却状态）
func (h *Handler) ListSkills(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")

	player, ok := h.store.GetPlayer(playerID)
	if !ok {
		h.notFound(w)
		return
	}

	skills := h.skillSvc.GetAvailableSkills(player, skill.AllPresetSkills())
	h.json(w, http.StatusOK, map[string]interface{}{
		"player_id": playerID,
		"skills":    skills,
	})
}

// UseSkill 使用技能
func (h *Handler) UseSkill(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		SkillID  string      `json:"skill_id"`
		TargetID interface{} `json:"target_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.SkillID == "" {
		h.badRequest(w, "skill_id is required")
		return
	}

	// 获取玩家
	player, ok := h.store.GetPlayer(playerID)
	if !ok {
		h.notFound(w)
		return
	}

	// 检查玩家是否学会该技能
	hasSkill := false
	for _, sid := range player.Skills {
		if sid == req.SkillID {
			hasSkill = true
			break
		}
	}
	if !hasSkill {
		h.badRequest(w, "skill not learned")
		return
	}

	// 获取技能定义
	skillDef := skill.GetSkillByID(req.SkillID)
	if skillDef == nil {
		h.badRequest(w, "skill not found")
		return
	}

	// 使用技能
	var targetHP *int
	if req.TargetID != nil {
		if v, ok := req.TargetID.(float64); ok {
			hpi := int(v)
			targetHP = &hpi
		}
	}
	result, err := h.skillSvc.UseSkill(player, skillDef, targetHP)
	if err != nil {
		h.badRequest(w, err.Error())
		return
	}

	// 刷新玩家数据
	player, _ = h.store.GetPlayer(playerID)

	h.json(w, http.StatusOK, map[string]interface{}{
		"result":         result,
		"player_hp":      player.HP,
		"player_mp":      player.MP,
		"player_si":      player.SwordIntent,
	})
}

// GetSkillCooldown 获取技能冷却状态
func (h *Handler) GetSkillCooldown(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	skillID := r.PathValue("skill_id")

	cooldown := h.skillSvc.GetSkillCooldownRemaining(playerID, skillID)

	h.json(w, http.StatusOK, map[string]interface{}{
		"player_id":  playerID,
		"skill_id":   skillID,
		"cooldown_seconds": cooldown,
	})
}

// ListPresetSkills 列出所有预设技能
func (h *Handler) ListPresetSkills(w http.ResponseWriter, r *http.Request) {
	skills := skill.AllPresetSkills()
	h.json(w, http.StatusOK, map[string]interface{}{
		"skills": skills,
	})
}

// ---- Inventory APIs ----

// GetInventory 获取玩家背包
func (h *Handler) GetInventory(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")

	// 检查玩家存在
	if _, ok := h.store.GetPlayer(playerID); !ok {
		h.notFound(w)
		return
	}

	inv := h.inventorySvc.GetInventory(playerID)
	eq := h.inventorySvc.GetEquipment(playerID)
	stats := h.inventorySvc.CalculateStats(nil, eq)

	h.json(w, http.StatusOK, map[string]interface{}{
		"inventory": inv,
		"equipment": eq,
		"stats":     stats,
	})
}

// EquipItem 装备物品
func (h *Handler) EquipItem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		SlotIndex int `json:"slot_index"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	// 检查玩家存在
	if _, ok := h.store.GetPlayer(playerID); !ok {
		h.notFound(w)
		return
	}

	eq, err := h.inventorySvc.EquipItem(playerID, req.SlotIndex)
	if err != nil {
		h.badRequest(w, err.Error())
		return
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"equipment": eq,
		"message":   "装备成功",
	})
}

// UnequipItem 卸下装备
func (h *Handler) UnequipItem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		SlotType string `json:"slot_type"` // "weapon"|"armor"|"accessory"
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	// 检查玩家存在
	if _, ok := h.store.GetPlayer(playerID); !ok {
		h.notFound(w)
		return
	}

	var slotType model.ItemType
	switch req.SlotType {
	case "weapon":
		slotType = model.ItemTypeWeapon
	case "armor":
		slotType = model.ItemTypeArmor
	case "accessory":
		slotType = model.ItemTypeAccessory
	default:
		h.badRequest(w, "invalid slot_type: must be weapon, armor, or accessory")
		return
	}

	slot, err := h.inventorySvc.UnequipItem(playerID, slotType)
	if err != nil {
		h.badRequest(w, err.Error())
		return
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"slot":   slot,
		"message": "卸下成功",
	})
}

// UseItem 使用物品
func (h *Handler) UseItem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		ItemID string `json:"item_id"`
		Count  int    `json:"count"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.Count <= 0 {
		req.Count = 1
	}

	// 检查玩家存在
	player, ok := h.store.GetPlayer(playerID)
	if !ok {
		h.notFound(w)
		return
	}

	// 使用物品
	if err := h.inventorySvc.UseItem(playerID, req.ItemID, req.Count); err != nil {
		h.badRequest(w, err.Error())
		return
	}

	// 应用消耗品效果到玩家
	presetItem := item.GetItemByID(req.ItemID)
	effects := make(map[string]interface{})
	if presetItem != nil && presetItem.Type == model.ItemTypeConsumable {
		for _, effect := range presetItem.Effects {
			switch effect.Type {
			case "hp":
				player.HP = min(player.HP+effect.Value, player.MaxHP)
				effects["hp_restored"] = effect.Value
			case "mp":
				player.MP = min(player.MP+effect.Value, player.MaxMP)
				effects["mp_restored"] = effect.Value
			case "teleport":
				effects["teleport"] = true
			case "buff":
				effects["buff_active"] = true
			}
		}
		h.store.UpdatePlayer(player)
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"message":  "使用成功",
		"effects": effects,
		"player":  player,
	})
}

// GetShopInventory 获取商店库存
func (h *Handler) GetShopInventory(w http.ResponseWriter, r *http.Request) {
	shopType := r.PathValue("shop_type")

	items := h.shopSvc.GetShopInventory(shopType)
	if len(items) == 0 {
		h.notFound(w)
		return
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"shop_type": shopType,
		"items":     items,
	})
}

// AddItemToInventory 添加物品到背包（GM/测试用）
func (h *Handler) AddItemToInventory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		ItemID string `json:"item_id"`
		Count  int    `json:"count"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.Count <= 0 {
		req.Count = 1
	}

	// 检查玩家存在
	if _, ok := h.store.GetPlayer(playerID); !ok {
		h.notFound(w)
		return
	}

	presetItem := item.GetItemByID(req.ItemID)
	if presetItem == nil {
		h.badRequest(w, "item not found")
		return
	}

	if err := h.inventorySvc.AddItem(playerID, presetItem, req.Count); err != nil {
		h.badRequest(w, err.Error())
		return
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"message": "添加成功",
		"item":    presetItem,
		"count":   req.Count,
	})
}

// ListPresetItems 列出所有预设物品
func (h *Handler) ListPresetItems(w http.ResponseWriter, r *http.Request) {
	items := item.MVPItems
	h.json(w, http.StatusOK, map[string]interface{}{
		"items": items,
	})
}

// ---- Equipment APIs (基于装备系统) ----

// GetPlayerEquipment 获取玩家装备
func (h *Handler) GetPlayerEquipment(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")

	if _, ok := h.store.GetPlayer(playerID); !ok {
		h.notFound(w)
		return
	}

	// 获取装备数据
	eq, ok := h.store.GetEquipment(playerID)
	if !ok {
		eq = &model.Equipment{PlayerID: playerID}
		h.store.CreateEquipment(eq)
	}

	// 获取背包数据
	inv, _ := h.store.GetInventory(playerID)
	if inv == nil {
		inv = model.NewInventory(playerID)
	}

	// 获取完整装备信息
	eqInfo := h.equipmentSvc.GetEquipmentInfo(&model.PlayerEquipment{
		PlayerID:  playerID,
		Slots:     h.getEquipmentSlots(eq),
		StatsBonus: model.PlayerStatsBonus{},
	})

	h.json(w, http.StatusOK, map[string]interface{}{
		"player_id":  playerID,
		"equipment":  eqInfo,
		"inventory":  inv,
	})
}

// EquipItemToSlot 装备物品到指定槽位
func (h *Handler) EquipItemToSlot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		Slot  string `json:"slot"`  // weapon, armor, accessory1, accessory2
		ItemID string `json:"item_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.Slot == "" || req.ItemID == "" {
		h.badRequest(w, "slot and item_id are required")
		return
	}

	if _, ok := h.store.GetPlayer(playerID); !ok {
		h.notFound(w)
		return
	}

	// 获取装备和背包
	eq, _ := h.store.GetEquipment(playerID)
	if eq == nil {
		eq = &model.Equipment{PlayerID: playerID}
	}

	inv, _ := h.store.GetInventory(playerID)
	if inv == nil {
		inv = model.NewInventory(playerID)
	}

	// 转换为装备槽位类型
	var slotType model.EquipmentSlotType
	switch req.Slot {
	case "weapon":
		slotType = model.EquipSlotWeapon
	case "armor":
		slotType = model.EquipSlotArmor
	case "accessory1":
		slotType = model.EquipSlotAccessory1
	case "accessory2":
		slotType = model.EquipSlotAccessory2
	default:
		h.badRequest(w, "invalid slot: must be weapon, armor, accessory1, or accessory2")
		return
	}

	// 创建PlayerEquipment用于调用service
	playerEq := &model.PlayerEquipment{
		PlayerID: playerID,
		Slots:    h.getEquipmentSlots(eq),
	}

	resp := h.equipmentSvc.EquipItem(playerEq, inv, slotType, req.ItemID)
	if !resp.Success {
		h.badRequest(w, resp.Message)
		return
	}

	// 更新存储
	h.updateEquipmentFromSlots(eq, playerEq)
	h.store.UpdateEquipment(eq)
	h.store.UpdateInventory(inv)

	h.json(w, http.StatusOK, resp)
}

// getEquipmentSlots 转换Equipment到PlayerEquipment的槽位map
func (h *Handler) getEquipmentSlots(eq *model.Equipment) map[model.EquipmentSlotType]*model.EquipmentSlot {
	slots := make(map[model.EquipmentSlotType]*model.EquipmentSlot)
	slots[model.EquipSlotWeapon] = &model.EquipmentSlot{Type: model.EquipSlotWeapon, ItemID: h.getItemIDFromEquipment(eq, "weapon")}
	slots[model.EquipSlotArmor] = &model.EquipmentSlot{Type: model.EquipSlotArmor, ItemID: h.getItemIDFromEquipment(eq, "armor")}
	slots[model.EquipSlotAccessory1] = &model.EquipmentSlot{Type: model.EquipSlotAccessory1, ItemID: h.getItemIDFromEquipment(eq, "accessory1")}
	slots[model.EquipSlotAccessory2] = &model.EquipmentSlot{Type: model.EquipSlotAccessory2, ItemID: h.getItemIDFromEquipment(eq, "accessory2")}
	return slots
}

// getItemIDFromEquipment 从Equipment获取物品ID
func (h *Handler) getItemIDFromEquipment(eq *model.Equipment, slotType string) string {
	if eq == nil {
		return ""
	}
	switch slotType {
	case "weapon":
		if eq.Weapon != nil {
			return eq.Weapon.ID
		}
	case "armor":
		if eq.Armor != nil {
			return eq.Armor.ID
		}
	case "accessory1":
		if eq.Accessory1 != nil {
			return eq.Accessory1.ID
		}
	case "accessory2":
		if eq.Accessory2 != nil {
			return eq.Accessory2.ID
		}
	}
	return ""
}

// updateEquipmentFromSlots 从PlayerEquipment更新回Equipment
func (h *Handler) updateEquipmentFromSlots(eq *model.Equipment, playerEq *model.PlayerEquipment) {
	if playerEq == nil || playerEq.Slots == nil {
		return
	}

	// 清空所有槽位
	eq.Weapon = nil
	eq.Armor = nil
	eq.Accessory1 = nil
	eq.Accessory2 = nil

	// 根据槽位类型设置物品
	for slotType, slot := range playerEq.Slots {
		if slot.ItemID == "" {
			continue
		}
		item := item.GetPresetItem(slot.ItemID)
		if item == nil {
			continue
		}
		switch slotType {
		case model.EquipSlotWeapon:
			eq.Weapon = item
		case model.EquipSlotArmor:
			eq.Armor = item
		case model.EquipSlotAccessory1:
			eq.Accessory1 = item
		case model.EquipSlotAccessory2:
			eq.Accessory2 = item
		}
	}
}

// ---- Martial Arts APIs ----

// GetPlayerMartialArts 获取玩家武学列表
func (h *Handler) GetPlayerMartialArts(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")

	player, ok := h.store.GetPlayer(playerID)
	if !ok {
		h.notFound(w)
		return
	}

	// 获取或创建玩家武学数据
	pm := h.getOrCreatePlayerMartialArts(playerID)

	// 获取技能树信息
	skillTree := h.martialArtSvc.GetSkillTree(pm)
	skillTree["player_id"] = playerID
	skillTree["name"] = player.Name
	skillTree["level"] = player.Level

	h.json(w, http.StatusOK, skillTree)
}

// LearnMartialArt 学习武学
func (h *Handler) LearnMartialArt(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		MartialArtID string `json:"martial_art_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.MartialArtID == "" {
		h.badRequest(w, "martial_art_id is required")
		return
	}

	player, ok := h.store.GetPlayer(playerID)
	if !ok {
		h.notFound(w)
		return
	}

	pm := h.getOrCreatePlayerMartialArts(playerID)

	resp := h.martialArtSvc.LearnMartialArt(pm, player, req.MartialArtID)
	if !resp.Success {
		h.badRequest(w, resp.Message)
		return
	}

	h.store.SetPlayerMartialArts(pm)

	h.json(w, http.StatusOK, resp)
}

// EquipMartialArt 装备武学
func (h *Handler) EquipMartialArt(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}

	playerID := r.PathValue("player_id")

	var req struct {
		MartialArtID string `json:"martial_art_id"`
		Type         string `json:"type"` // external, internal, lightness
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.MartialArtID == "" {
		h.badRequest(w, "martial_art_id is required")
		return
	}

	pm := h.getOrCreatePlayerMartialArts(playerID)

	// 获取武学定义
	art := h.martialArtSvc.GetMartialArt(req.MartialArtID)
	if art == nil {
		h.badRequest(w, "武学不存在")
		return
	}

	// 如果指定了type，使用指定type；否则使用武学原本的type
	artType := art.Type
	if req.Type != "" {
		artType = model.MartialArtType(req.Type)
	}

	// 检查是否是有效的武学类型
	switch artType {
	case model.MartialArtExternal, model.MartialArtInternal, model.MartialArtLightness:
		// 有效
	default:
		h.badRequest(w, "invalid type: must be external, internal, or lightness")
		return
	}

	// 临时修改art的type用于Equip
	originalType := art.Type
	art.Type = artType

	resp := h.martialArtSvc.EquipMartialArt(pm, req.MartialArtID)

	// 恢复原始type
	art.Type = originalType

	if !resp.Success {
		h.badRequest(w, resp.Message)
		return
	}

	h.store.SetPlayerMartialArts(pm)

	h.json(w, http.StatusOK, resp)
}

// getOrCreatePlayerMartialArts 获取或创建玩家武学数据
func (h *Handler) getOrCreatePlayerMartialArts(playerID string) *model.PlayerMartialArts {
	pm, ok := h.store.GetPlayerMartialArts(playerID)
	if !ok {
		pm = model.NewPlayerMartialArts(playerID)
		h.store.CreatePlayerMartialArts(pm)
	}
	return pm
}
