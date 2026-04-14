package ws

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"nhooyr.io/websocket"
)

// Handler handles WebSocket connections
type Handler struct {
	hub            *Hub
	auth           *Authenticator
	mux            *http.ServeMux
	server         *http.Server
	narrativeSvc   any // narrative service, may be nil
}

// NewHandler creates a new WebSocket handler
// jwtSecret is the JWT secret for authentication
// narrativeSvc is optional (may be nil) and should implement:
//   GenerateCardDrawNarrative(ctx context.Context, req CardDrawNarrativeReq) (*EventNarrativeData, error)
func NewHandler(jwtSecret string, narrativeSvc ...any) *Handler {
	auth := NewAuthenticator(jwtSecret)
	hub := NewHub(auth)
	h := &Handler{
		hub:          hub,
		auth:         auth,
		mux:          http.NewServeMux(),
		narrativeSvc: nil,
	}
	// Accept variadic narrative service argument
	if len(narrativeSvc) > 0 {
		h.narrativeSvc = narrativeSvc[0]
		hub.NarrativeSvc = narrativeSvc[0]
	}
	h.setupRoutes()
	return h
}

// setupRoutes registers HTTP routes
func (h *Handler) setupRoutes() {
	h.mux.HandleFunc("/ws/v1", h.handleWebSocket)
	h.mux.HandleFunc("/health", h.handleHealth)
}

// ServeHTTP implements http.Handler
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	h.mux.ServeHTTP(w, r)
}

// Run starts the WebSocket server
func (h *Handler) Run(addr string) error {
	// Start the hub
	h.hub.Run()

	h.server = &http.Server{
		Addr:         addr,
		Handler:      h,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Printf("[WS] WebSocket server starting on %s", addr)
	return h.server.ListenAndServe()
}

// Shutdown gracefully shuts down the WebSocket server
func (h *Handler) Shutdown(ctx context.Context) error {
	h.hub.Stop()
	if h.server != nil {
		return h.server.Shutdown(ctx)
	}
	return nil
}

// handleWebSocket handles the WebSocket upgrade and main connection flow
func (h *Handler) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Get player_id from query param for initial HTTP header auth
	playerID := r.URL.Query().Get("player_id")
	authHeader := r.Header.Get("Authorization")
	deviceID := r.Header.Get("X-Device-ID")

	// Try HTTP header auth first
	var validatedPlayerID string
	if authHeader != "" && playerID != "" {
		token := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := h.auth.ValidateToken(token)
		if err == nil && claims.PlayerID == playerID {
			validatedPlayerID = playerID
		}
	}

	// Upgrade to WebSocket
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		CompressionMode: websocket.CompressionContextTakeover,
	})
	if err != nil {
		log.Printf("[WS] Accept error: %v", err)
		return
	}

	clientID := uuid.New().String()
	client := NewClient(h.hub, conn, clientID)

	// Register client
	h.hub.Register <- client

	// If HTTP header auth succeeded, mark as authenticated immediately
	if validatedPlayerID != "" {
		sessionID := NewSessionID()
		client.SetAuthenticated(validatedPlayerID, deviceID, sessionID)

		// Send auth_ack
		ack := BaseMessage{
			Type:      TypeResponse,
			Event:     EventAuthAck,
			Seq:       h.hub.NextSeq(),
			Timestamp: NowISO(),
			Data: AuthAckData{
				Success:    true,
				PlayerID:   validatedPlayerID,
				SessionID:  sessionID,
				ServerTime: NowISO(),
			},
		}
		select {
		case client.Send <- MustMarshal(ack):
		default:
		}
	}

	// Start read/write pumps
	go client.WritePump()
	go client.ReadPump()
}

// handleHealth returns server health status
func (h *Handler) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "ok",
		"clients": h.hub.ClientCount(),
		"time":    NowISO(),
	})
}

// Hub returns the hub for external use (e.g., pushing events)
func (h *Handler) Hub() *Hub {
	return h.hub
}

// ---- Message Handlers ----

func (h *Hub) handleAuth(packet *MessagePacket, base *BaseMessage) {
	var req AuthMessage
	if err := json.Unmarshal(mustDataBytes(base), &req); err != nil {
		h.sendAuthAck(packet.Client, base.Seq, false, string(ErrInvalidToken), "Invalid auth message")
		return
	}

	// Validate token
	claims, err := h.auth.ValidateToken(req.Token)
	if err != nil {
		h.sendAuthAck(packet.Client, base.Seq, false, string(ErrInvalidToken), "认证失败，请重新登录")
		return
	}

	// Optionally verify player_id matches
	if req.PlayerID != "" && claims.PlayerID != req.PlayerID {
		h.sendAuthAck(packet.Client, base.Seq, false, string(ErrInvalidToken), "Player ID mismatch")
		return
	}

	sessionID := NewSessionID()
	packet.Client.SetAuthenticated(claims.PlayerID, req.DeviceID, sessionID)

	h.sendAuthAck(packet.Client, base.Seq, true, "", "")
	log.Printf("[WS] Client authenticated: player=%s session=%s", claims.PlayerID, sessionID)
}

func (h *Hub) handlePing(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		return
	}

	pong := BaseMessage{
		Type:      TypeResponse,
		Event:     EventPong,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data: PongData{
			ServerTime: NowISO(),
			LatencyMs:  0, // Client should calculate RTT
		},
	}
	select {
	case packet.Client.Send <- MustMarshal(pong):
	default:
	}
}

func (h *Hub) handleCardDraw(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		h.sendError(packet.Client, base.Seq, ErrSessionExpired, "Not authenticated")
		return
	}

	var req CardDrawRequest
	json.Unmarshal(mustDataBytes(base), &req)

	// TODO: Integrate with actual game logic
	// For now, return a mock response
	forceType := req.ForceCardType
	if forceType == "" {
		forceType = "attack"
	}

	drawnCards := []CardInfo{
		{
			ID:          "card_" + uuid.New().String()[:8],
			Type:        forceType,
			Title:       "破天一剑",
			Description: "凝聚全身真气，发出毁天灭地的一击",
			Element:     "thunder",
			Damage:      85,
			MPCost:      20,
			Cooldown:    0,
			Effects:     []string{"破甲", "眩晕"},
		},
	}

	resp := BaseMessage{
		Type:      TypeResponse,
		Event:     EventCardDrawResp,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data: CardDrawResponseData{
			Success:          true,
			DrawnCards:       drawnCards,
			NextCardTypeHint: "defense",
			DeckExhausted:    false,
			DealerHint:       "说书人轻敲桌面：此剑一出，江湖再无安宁",
			CardsRemaining:   23,
		},
	}
	select {
	case packet.Client.Send <- MustMarshal(resp):
	default:
	}

	// Asynchronously generate and push narrative for each drawn card
	if h.NarrativeSvc != nil {
		go func() {
			for _, card := range drawnCards {
				narrativeReq := CardDrawNarrativeReq{
					PlayerID:   packet.Client.PlayerID,
					CardInfo:   card,
					DealerID:   req.DealerID,
					DealerName: "说书人",
					Location:   "长安城",
					DrawCount: len(drawnCards),
				}
				// Type assert and call narrative service
				type narrativeGenerator interface {
					GenerateCardDrawNarrative(ctx context.Context, req CardDrawNarrativeReq) (*EventNarrativeData, error)
				}
				if gen, ok := h.NarrativeSvc.(narrativeGenerator); ok {
					data, err := gen.GenerateCardDrawNarrative(context.Background(), narrativeReq)
					if err != nil {
						log.Printf("[Narrative] generate error: %v", err)
						continue
					}
					h.PushNarrativeEvent(packet.Client.PlayerID, *data)
				}
			}
		}()
	}
}

// CardDrawNarrativeReq is the request type for card draw narrative generation.
// Duplicated here to avoid circular import with narrative package.
type CardDrawNarrativeReq struct {
	PlayerID   string
	CardInfo   CardInfo
	DealerID   string
	DealerName string
	Location   string
	DrawCount  int
}

func (h *Hub) handleBattleAction(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		h.sendError(packet.Client, base.Seq, ErrSessionExpired, "Not authenticated")
		return
	}

	var req BattleActionRequest
	json.Unmarshal(mustDataBytes(base), &req)

	// TODO: Integrate with actual battle logic
	var respData BattleActionResponseData
	switch req.Action {
	case "dodge":
		respData = BattleActionResponseData{
			Action:  "dodge",
			Success: true,
			DodgeResult: map[string]interface{}{
				"dodged":           true,
				"timing_diff_ms":   20,
				"timing_rating":    "perfect",
				"stamina_cost":     20,
				"sword_intent_gained": 5,
				"description":     "完美闪避！时机拿捏分毫不差",
			},
			SwordIntentGained: 5,
			Description:       "完美闪避！时机拿捏分毫不差",
		}
	case "block":
		respData = BattleActionResponseData{
			Action:  "block",
			Success: true,
			BlockResult: map[string]interface{}{
				"blocked":            true,
				"perfect_block":      true,
				"timing_diff_ms":     80,
				"timing_rating":      "perfect",
				"damage_reduction":   1.0,
				"stamina_cost":       15,
				"counter_window_ms":  500,
				"sword_intent_gained": 8,
				"description":        "完美格挡！刀光剑影中尽显宗师风范",
			},
			SwordIntentGained: 8,
			Description:       "完美格挡！刀光剑影中尽显宗师风范",
		}
	case "counter":
		respData = BattleActionResponseData{
			Action:  "counter",
			Success: true,
			AttackDamage: map[string]interface{}{
				"final_damage":      req.CounterBaseDamage * 1.5,
				"sword_intent_gained": 12,
				"description":       fmt.Sprintf("反击造成 %.1f 点伤害", req.CounterBaseDamage*1.5),
			},
			SwordIntentGained: 12,
			Description:       "完美反击！",
		}
	case "attack":
		respData = BattleActionResponseData{
			Action:  "attack",
			Success: true,
			AttackDamage: map[string]interface{}{
				"final_damage": 127.5,
				"elemental_reaction": map[string]interface{}{
					"reaction_type":         "evaporation",
					"reaction_damage":       25.5,
					"suppression_multiplier": 1.2,
					"description":           "蒸发！水火相激，威力倍增",
				},
				"sword_intent_gained": 10,
				"mp_consumed":         15,
				"description":         "造成 127.5 点伤害（+蒸发反应 25.5）",
			},
			SwordIntentGained: 10,
			Description:       "造成 127.5 点伤害",
		}
	default:
		h.sendError(packet.Client, base.Seq, ErrInvalidAction, "Unknown action: "+req.Action)
		return
	}

	resp := BaseMessage{
		Type:      TypeResponse,
		Event:     EventBattleActionResp,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data:      respData,
	}
	select {
	case packet.Client.Send <- MustMarshal(resp):
	default:
	}
}

func (h *Hub) handleWorldNavigate(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		h.sendError(packet.Client, base.Seq, ErrSessionExpired, "Not authenticated")
		return
	}

	var req WorldNavigateRequest
	json.Unmarshal(mustDataBytes(base), &req)

	// TODO: Integrate with actual world logic
	resp := BaseMessage{
		Type:      TypeResponse,
		Event:     EventWorldNavigate,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data: WorldNavigateResponseData{
			Success:    true,
			Message:    fmt.Sprintf("你踏上了前往%v的旅程。", req.TargetLocationID),
			TravelTime: "1天",
			Route: &RouteInfo{
				Path: []LocationSummary{
					{ID: "loc-changan", Name: "长安城"},
					{ID: "loc-suzhou", Name: "苏州城"},
				},
				TotalDistance: 500,
				Dangers:       []string{},
			},
			NewLocation: &LocationInfo{
				ID:           "loc-suzhou",
				Name:         "苏州城",
				LocationType: "city",
				DangerLevel:  2,
			},
			AvailableDealers: []DealerInfo{
				{ID: "teahouse-2", Type: "teahouse", Name: "茶馆说书人"},
				{ID: "bounty-1", Type: "bounty_board", Name: "江湖悬赏令"},
			},
			EncounterProbability: &EncounterProb{
				OnRoute:        0.15,
				AtDestination: 0.25,
			},
		},
	}
	select {
	case packet.Client.Send <- MustMarshal(resp):
	default:
	}
}

func (h *Hub) handleSkillUse(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		h.sendError(packet.Client, base.Seq, ErrSessionExpired, "Not authenticated")
		return
	}

	// TODO: Integrate with actual skill logic
	resp := BaseMessage{
		Type:      TypeResponse,
		Event:     EventSkillUseResp,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data: map[string]interface{}{
			"success": true,
			"message": "技能使用成功",
		},
	}
	select {
	case packet.Client.Send <- MustMarshal(resp):
	default:
	}
}

func (h *Hub) handleItemUse(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		h.sendError(packet.Client, base.Seq, ErrSessionExpired, "Not authenticated")
		return
	}

	var req ItemUseRequest
	json.Unmarshal(mustDataBytes(base), &req)

	resp := BaseMessage{
		Type:      TypeResponse,
		Event:     EventItemUseResp,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data: map[string]interface{}{
			"success":             true,
			"item_id":             req.ItemID,
			"hp_restored":         50,
			"item_count_remaining": 2,
		},
	}
	select {
	case packet.Client.Send <- MustMarshal(resp):
	default:
	}
}

func (h *Hub) handleSync(packet *MessagePacket, base *BaseMessage) {
	if !packet.Client.IsAuthenticated() {
		h.sendError(packet.Client, base.Seq, ErrSessionExpired, "Not authenticated")
		return
	}

	var req SyncRequest
	json.Unmarshal(mustDataBytes(base), &req)

	// TODO: Load actual player state from game server
	resp := BaseMessage{
		Type:      TypeResponse,
		Event:     EventSyncResp,
		Seq:       base.Seq,
		Timestamp: NowISO(),
		Data: SyncResponseData{
			CurrentPlayerStatus: &PlayerStatus{
				HP:          80,
				MaxHP:       100,
				MP:          45,
				MaxMP:       80,
				Stamina:     60,
				MaxStamina:  100,
				SwordIntent: 35,
				Level:       5,
				Exp:         350,
			},
			CurrentLocation: &LocationInfo{
				ID:           "loc-changan",
				Name:         "长安城",
				LocationType: "city",
				DangerLevel:  1,
				RegionID:    "region-central-plains",
			},
			CurrentBattle: nil,
			PendingEvents: []BaseMessage{},
		},
	}
	select {
	case packet.Client.Send <- MustMarshal(resp):
	default:
	}
}

// ---- Helper Methods ----

func (h *Hub) sendAuthAck(client *Client, seq int64, success bool, errorCode, message string) {
	ack := BaseMessage{
		Type:      TypeResponse,
		Event:     EventAuthAck,
		Seq:       seq,
		Timestamp: NowISO(),
		Data: AuthAckData{
			Success:    success,
			PlayerID:   client.PlayerID,
			SessionID:  client.SessionID,
			ServerTime: NowISO(),
			ErrorCode:  errorCode,
			Message:    message,
		},
	}
	select {
	case client.Send <- MustMarshal(ack):
	default:
	}
}

func (h *Hub) sendError(client *Client, seq int64, code ErrorCode, message string) {
	errMsg := BaseMessage{
		Type:      TypeError,
		Event:     EventType(code),
		Seq:       seq,
		Timestamp: NowISO(),
		Data: map[string]interface{}{
			"error_code": code,
			"message":    message,
		},
	}
	select {
	case client.Send <- MustMarshal(errMsg):
	default:
	}
}

func mustDataBytes(base *BaseMessage) []byte {
	if base.Data == nil {
		return []byte("{}")
	}
	b, _ := json.Marshal(base.Data)
	return b
}
