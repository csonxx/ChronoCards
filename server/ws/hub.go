package ws

import (
	"encoding/json"
	"log"
	"sync"
	"sync/atomic"

	"github.com/google/uuid"
)

// Hub maintains the set of active clients and broadcasts messages to clients
type Hub struct {
	// Registered clients
	Clients map[string]*Client

	// Register requests from clients
	Register chan *Client

	// Unregister requests from clients
	Unregister chan *Client

	// Messages received from clients
	Receive chan *MessagePacket

	// Sequence counter for message ordering
	seqCounter int64

	// JWT authenticator
	auth *Authenticator

	// NarrativeSvc generates LLM-driven narrative content (may be nil)
	NarrativeSvc any

	// done signals the Run goroutine to exit
	done chan struct{}

	mu      sync.RWMutex
	wg      sync.WaitGroup
	running atomic.Bool
}

// NewHub creates a new Hub instance
func NewHub(auth *Authenticator) *Hub {
	return &Hub{
		Clients:    make(map[string]*Client),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Receive:    make(chan *MessagePacket, 512),
		auth:       auth,
		done:       make(chan struct{}),
	}
}

// Run starts the hub's main loop
func (h *Hub) Run() {
	if h.running.Swap(true) {
		return
	}

	h.wg.Add(1)
	go func() {
		defer h.wg.Done()
		for {
			select {
			case <-h.done:
				return

			case client := <-h.Register:
				h.mu.Lock()
				h.Clients[client.ID] = client
				h.mu.Unlock()

			case client := <-h.Unregister:
				h.mu.Lock()
				if _, ok := h.Clients[client.ID]; ok {
					delete(h.Clients, client.ID)
					close(client.Send)
				}
				h.mu.Unlock()

			case packet := <-h.Receive:
				h.handleMessage(packet)
			}
		}
	}()
}

// Stop stops the hub
func (h *Hub) Stop() {
	if !h.running.Swap(false) {
		return
	}
	close(h.done)
	h.wg.Wait()
}

// SendToPlayerID sends a message to a specific player
func (h *Hub) SendToPlayerID(playerID string, msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, client := range h.Clients {
		if client.PlayerID == playerID && client.IsAuthenticated() {
			select {
			case client.Send <- msg:
			default:
			}
			return
		}
	}
}

// Broadcast sends a message to all authenticated clients
func (h *Hub) Broadcast(msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, client := range h.Clients {
		if !client.IsAuthenticated() {
			continue
		}
		select {
		case client.Send <- msg:
		default:
		}
	}
}

// ClientCount returns the number of connected clients
func (h *Hub) ClientCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.Clients)
}

// handleMessage processes a message from a client
func (h *Hub) handleMessage(packet *MessagePacket) {
	var base BaseMessage
	if err := json.Unmarshal(packet.Data, &base); err != nil {
		return
	}

	packet.Client.UpdateSeq(base.Seq)

	switch base.Event {
	case EventAuth:
		h.handleAuth(packet, &base)
	case EventPing:
		h.handlePing(packet, &base)
	case EventCardDrawReq:
		h.handleCardDraw(packet, &base)
	case EventBattle:
		h.handleBattleAction(packet, &base)
	case EventNavigate:
		h.handleWorldNavigate(packet, &base)
	case EventSkillUseReq:
		h.handleSkillUse(packet, &base)
	case EventItemUseReq:
		h.handleItemUse(packet, &base)
	case EventSync:
		h.handleSync(packet, &base)
	default:
		h.sendError(packet.Client, base.Seq, ErrInvalidAction, "Unknown event: "+string(base.Event))
	}
}

// NextSeq generates the next sequence number
func (h *Hub) NextSeq() int64 {
	return atomic.AddInt64(&h.seqCounter, 1)
}

// broadcastToPlayerArea sends to all clients in the same "area" (simplified: same player)
func (h *Hub) broadcastToPlayerArea(playerID string, msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, client := range h.Clients {
		if client.PlayerID == playerID && client.IsAuthenticated() {
			select {
			case client.Send <- msg:
			default:
			}
		}
	}
}

// ---- Push Events (10 types) ----

// PushCardDrawEvent pushes event_card_draw to a player
func (h *Hub) PushCardDrawEvent(playerID string, data EventCardDrawData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventServerCardDraw,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushWorldMapUpdateEvent pushes event_world_map_update
func (h *Hub) PushWorldMapUpdateEvent(playerID string, data EventWorldMapUpdateData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventWorldMapUpdate,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushBattleUpdateEvent pushes event_battle_update
func (h *Hub) PushBattleUpdateEvent(playerID string, data EventBattleUpdateData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventBattleUpdate,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushPlayerStatusEvent pushes event_player_status
func (h *Hub) PushPlayerStatusEvent(playerID string, data EventPlayerStatusData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventPlayerStatus,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushSkillCooldownEvent pushes event_skill_cooldown
func (h *Hub) PushSkillCooldownEvent(playerID string, data EventSkillCooldownData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventSkillCooldown,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushDeckExhaustedEvent pushes event_deck_exhausted
func (h *Hub) PushDeckExhaustedEvent(playerID string, data EventDeckExhaustedData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventDeckExhausted,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushItemUsedEvent pushes event_item_used
func (h *Hub) PushItemUsedEvent(playerID string, data EventItemUsedData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventItemUsed,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushEncounterEvent pushes event_encounter
func (h *Hub) PushEncounterEvent(playerID string, data EventEncounterData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventEncounter,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushLevelUpEvent pushes event_level_up
func (h *Hub) PushLevelUpEvent(playerID string, data EventLevelUpData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventLevelUp,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushElementReactionEvent pushes event_element_reaction
func (h *Hub) PushElementReactionEvent(playerID string, data EventElementReactionData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventElementReaction,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// PushNarrativeEvent pushes event_narrative
func (h *Hub) PushNarrativeEvent(playerID string, data EventNarrativeData) {
	msg := BaseMessage{
		Type:      TypeEvent,
		Event:     EventNarrative,
		Seq:       h.NextSeq(),
		Timestamp: NowISO(),
		Data:      data,
	}
	h.broadcastToPlayerArea(playerID, MustMarshal(msg))
}

// MustMarshal marshals v to JSON, panics on error
func MustMarshal(v interface{}) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		log.Printf("marshal error: %v", err)
		return []byte(`{}`)
	}
	return b
}

// NewSessionID generates a new session ID
func NewSessionID() string {
	return "sess_" + uuid.New().String()[:8]
}
