package narrative

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"sync"
	"time"

	ws "github.com/csonxx/ChronoCards/ws"
)

// NarrativeService generates narrative content using LLM or fallback.
type NarrativeService struct {
	llmClient *LLMClient
	cache     *NarrativeCache
	fallback  *FallbackProvider
}

// NewNarrativeService creates a new NarrativeService.
// apiKey is read from MINIMAX_API_KEY env var if empty string is passed.
func NewNarrativeService(apiKey string) *NarrativeService {
	if apiKey == "" {
		apiKey = os.Getenv("MINIMAX_API_KEY")
	}
	client := NewLLMClient(apiKey)
	client.SetModel("abab7-chat").SetMaxTokens(512)

	return &NarrativeService{
		llmClient: client,
		cache:     NewNarrativeCache(24 * time.Hour),
		fallback:  NewFallbackProvider(),
	}
}

// SetModel allows overriding the default model.
func (s *NarrativeService) SetModel(model string) *NarrativeService {
	s.llmClient.SetModel(model)
	return s
}

// ---- Request / Response types ----

// CardDrawNarrativeReq is the request for card draw narrative.
type CardDrawNarrativeReq struct {
	PlayerID   string
	CardInfo   ws.CardInfo
	DealerID   string
	DealerName string
	Location   string
	DrawCount  int
}

// PlayerContext holds player information for prompt injection.
type PlayerContext struct {
	Name string
}

// NPCInfo holds NPC information for dialogue generation.
type NPCInfo struct {
	ID          string
	Name        string
	Personality string
}

// SceneContext holds scene information for NPC dialogue.
type SceneContext struct {
	Description string
	Emotion     string
}

// NPCDialogueReq is the request for NPC dialogue.
type NPCDialogueReq struct {
	PlayerID string
	NPCID    string
	NPCName  string
	Scene    string
	Emotion  string
}

// EventContext holds event information for description generation.
type EventContext struct {
	PlayerID     string
	PlayerName   string
	EventType    string
	LocationName string
	EnemyName    string
}

// EventDescReq is the request for event description.
type EventDescReq struct {
	PlayerID     string
	EventType    string
	LocationName string
	EnemyName    string
}

// ---- NarrativeService Interface ----

// GenerateCardDrawNarrative generates narrative for a card draw event.
func (s *NarrativeService) GenerateCardDrawNarrative(ctx context.Context, req CardDrawNarrativeReq) (*ws.EventNarrativeData, error) {
	card := req.CardInfo

	// Build cache key: card type + element + seed (hourly)
	cacheKey := fmt.Sprintf("narrative:card:%s:%s:%d", card.Type, card.Element, time.Now().Unix()/3600)
	seed := fmt.Sprintf("%s:%d", card.ID, time.Now().Unix()/3600)

	// Check cache
	if content, ok := s.cache.Get(cacheKey); ok {
		log.Printf("[Narrative] cache hit for key=%s", cacheKey)
		return s.buildNarrativeData("card_draw", req.PlayerID, card, req.DealerID, req.Location, content), nil
	}

	// Build prompt
	playerCtx := PlayerContext{Name: req.PlayerID}
	prompt := CardDrawPrompt(card, playerCtx, seed)

	// Call LLM
	content, err := s.callLLM(ctx, "card_draw", card.ID, prompt)
	if err != nil {
		log.Printf("[Narrative] LLM failed for card_draw:%s, using fallback (reason: %v)", card.ID, err)
		content = s.fallback.GetCardDrawFallback(card.Type)
	} else {
		// Cache successful response
		s.cache.Set(cacheKey, content)
	}

	return s.buildNarrativeData("card_draw", req.PlayerID, card, req.DealerID, req.Location, content), nil
}

// GenerateNPCDialogue generates NPC dialogue.
func (s *NarrativeService) GenerateNPCDialogue(ctx context.Context, req NPCDialogueReq) (*ws.EventNarrativeData, error) {
	seed := fmt.Sprintf("%s:%d", req.NPCID, time.Now().Unix()/3600)
	cacheKey := fmt.Sprintf("narrative:npc:%s:%s", req.NPCID, req.Scene)

	// Check cache (1h TTL)
	if content, ok := s.cache.Get(cacheKey); ok {
		log.Printf("[Narrative] cache hit for key=%s", cacheKey)
		return s.buildNPCNarrativeData(req.PlayerID, req.NPCID, req.NPCName, content), nil
	}

	npcInfo := NPCInfo{ID: req.NPCID, Name: req.NPCName, Personality: "江湖隐士"}
	sceneCtx := SceneContext{Description: req.Scene, Emotion: req.Emotion}
	prompt := NPCDialoguePrompt(npcInfo, sceneCtx, seed)

	content, err := s.callLLM(ctx, "npc_dialogue", req.NPCID, prompt)
	if err != nil {
		log.Printf("[Narrative] LLM failed for npc_dialogue:%s, using fallback (reason: %v)", req.NPCID, err)
		content = s.fallback.GetNPCDialogueFallback()
	} else {
		s.cache.Set(cacheKey, content)
	}

	return s.buildNPCNarrativeData(req.PlayerID, req.NPCID, req.NPCName, content), nil
}

// GenerateEventDescription generates event description.
func (s *NarrativeService) GenerateEventDescription(ctx context.Context, req EventDescReq) (*ws.EventNarrativeData, error) {
	seed := fmt.Sprintf("%s:%d", req.EventType, time.Now().Unix()/21600)
	cacheKey := fmt.Sprintf("narrative:event:%s:%s:%d", req.EventType, req.LocationName, time.Now().Unix()/21600)

	// Check cache (6h TTL)
	if content, ok := s.cache.Get(cacheKey); ok {
		log.Printf("[Narrative] cache hit for key=%s", cacheKey)
		return s.buildEventNarrativeData(req.PlayerID, req.EventType, req.LocationName, content), nil
	}

	eventCtx := EventContext{
		PlayerID:     req.PlayerID,
		PlayerName:   req.PlayerID,
		EventType:    req.EventType,
		LocationName: req.LocationName,
		EnemyName:    req.EnemyName,
	}
	prompt := EventDescPrompt(eventCtx, seed)

	content, err := s.callLLM(ctx, "event_desc", req.EventType, prompt)
	if err != nil {
		log.Printf("[Narrative] LLM failed for event_desc:%s, using fallback (reason: %v)", req.EventType, err)
		content = s.fallback.GetEventFallback(req.EventType)
	} else {
		s.cache.Set(cacheKey, content)
	}

	return s.buildEventNarrativeData(req.PlayerID, req.EventType, req.LocationName, content), nil
}

// ---- Internal helpers ----

// callLLM sends a prompt to the LLM and parses the JSON content.
func (s *NarrativeService) callLLM(ctx context.Context, triggerType, triggerID, prompt string) (string, error) {
	messages := []ChatMessage{
		{Role: "user", Content: prompt},
	}

	resp, err := s.llmClient.Chat(ctx, messages, 2)
	if err != nil {
		return "", err
	}

	content := strings.TrimSpace(resp.ExtractContent())
	if content == "" {
		return "", fmt.Errorf("empty content from LLM")
	}

	log.Printf("[Narrative] %s:%s generated %d tokens", triggerType, triggerID, resp.Usage.TotalTokens)
	return content, nil
}

// buildNarrativeData builds EventNarrativeData from raw JSON content.
func (s *NarrativeService) buildNarrativeData(triggerType, playerID string, card ws.CardInfo, dealerID, location string, rawJSON string) *ws.EventNarrativeData {
	content := s.parseNarrativeContent(rawJSON, card.Type)
	return &ws.EventNarrativeData{
		TriggerType:       triggerType,
		PlayerID:          playerID,
		CardID:            card.ID,
		CardTitle:         card.Title,
		DealerID:          dealerID,
		Location:          location,
		Content:           content,
		DisplayDurationMs: 5000,
	}
}

func (s *NarrativeService) buildNPCNarrativeData(playerID, npcID, npcName, rawJSON string) *ws.EventNarrativeData {
	var parsed struct {
		Dialogue     string `json:"dialogue"`
		Action       string `json:"action"`
		InnerThought string `json:"inner_thought"`
		EmotionHint  string `json:"emotion_hint"`
		AudioCue     string `json:"audio_cue"`
	}
	json.Unmarshal([]byte(rawJSON), &parsed)

	return &ws.EventNarrativeData{
		TriggerType:      "npc_dialogue",
		PlayerID:         playerID,
		Content: &ws.NarrativeContent{
			Text:       parsed.Dialogue,
			Dialogue:   parsed.Action,
			Atmosphere: parsed.InnerThought,
			AudioCue:   parsed.AudioCue,
		},
		DisplayDurationMs: 5000,
	}
}

func (s *NarrativeService) buildEventNarrativeData(playerID, eventType, locationName, rawJSON string) *ws.EventNarrativeData {
	var parsed struct {
		Narrative     string `json:"narrative"`
		Atmosphere    string `json:"atmosphere"`
		PlayerFeeling string `json:"player_feeling"`
		AudioCue      string `json:"audio_cue"`
	}
	json.Unmarshal([]byte(rawJSON), &parsed)

	return &ws.EventNarrativeData{
		TriggerType:      "event_desc",
		PlayerID:        playerID,
		Location:        locationName,
		Content: &ws.NarrativeContent{
			Text:       parsed.Narrative,
			Dialogue:   parsed.PlayerFeeling,
			Atmosphere: parsed.Atmosphere,
			AudioCue:   parsed.AudioCue,
		},
		DisplayDurationMs: 7000,
	}
}

// parseNarrativeContent parses card draw narrative JSON into NarrativeContent.
func (s *NarrativeService) parseNarrativeContent(rawJSON, cardType string) *ws.NarrativeContent {
	var parsed struct {
		Atmosphere string `json:"atmosphere"`
		Dialogue   string `json:"dialogue"`
		CardStory  string `json:"card_story"`
		AudioCue   string `json:"audio_cue"`
	}
	if err := json.Unmarshal([]byte(rawJSON), &parsed); err != nil {
		log.Printf("[Narrative] parse error: %v, raw: %s", err, rawJSON)
		return s.fallback.GetCardDrawFallback(cardType)
	}

	// Build combined text from card_story and atmosphere
	text := parsed.CardStory
	if parsed.Dialogue != "" {
		text = parsed.Dialogue + "\n" + text
	}

	return &ws.NarrativeContent{
		Text:       text,
		Dialogue:   parsed.Dialogue,
		Atmosphere: parsed.Atmosphere,
		AudioCue:   parsed.AudioCue,
	}
}

// ---- Cache ----

// NarrativeCache is an in-memory cache with TTL support (MVP implementation).
type NarrativeCache struct {
	data map[string]cacheEntry
	ttl  time.Duration
	mu   sync.RWMutex
}

type cacheEntry struct {
	value   string
	created time.Time
}

// NewNarrativeCache creates a new cache with the given TTL.
func NewNarrativeCache(ttl time.Duration) *NarrativeCache {
	return &NarrativeCache{
		data: make(map[string]cacheEntry),
		ttl:  ttl,
	}
}

// Get retrieves a cached value if it hasn't expired.
func (c *NarrativeCache) Get(key string) (string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	entry, ok := c.data[key]
	if !ok {
		return "", false
	}
	if time.Since(entry.created) > c.ttl {
		return "", false
	}
	return entry.value, true
}

// Set stores a value in the cache.
func (c *NarrativeCache) Set(key, value string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.data[key] = cacheEntry{value: value, created: time.Now()}
}
