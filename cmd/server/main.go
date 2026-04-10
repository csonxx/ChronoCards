package main

import (
	"log"
	"net/http"

	"github.com/csonxx/ChronoCards/internal/api"
	"github.com/csonxx/ChronoCards/internal/store"
)

func main() {
	log.Println("ChronoCards Backend 启动中...")

	s := store.NewStore()
	h := api.NewHandler(s)

	mux := http.NewServeMux()

	// 健康检查
	mux.HandleFunc("GET /api/v1/health", h.Health)

	// Player APIs
	mux.HandleFunc("POST /api/v1/players", h.CreatePlayer)
	mux.HandleFunc("GET /api/v1/players/{player_id}", h.GetPlayer)
	mux.HandleFunc("PATCH /api/v1/players/{player_id}", h.UpdatePlayer)
	mux.HandleFunc("GET /api/v1/players/{player_id}/battle-state", h.GetBattleState)

	// Deck APIs
	mux.HandleFunc("POST /api/v1/decks", h.CreateDeck)
	mux.HandleFunc("GET /api/v1/decks/{deck_id}", h.GetDeck)
	mux.HandleFunc("POST /api/v1/decks/{deck_id}/draw", h.DrawCard)
	mux.HandleFunc("GET /api/v1/decks/{deck_id}/hand", h.GetHand)
	mux.HandleFunc("POST /api/v1/decks/{deck_id}/reshuffle", h.ReshuffleDeck)
	mux.HandleFunc("POST /api/v1/decks/{deck_id}/adjust", h.AdjustDeck)

	// Element APIs
	mux.HandleFunc("POST /api/v1/element/reactions", h.CalculateReaction)
	mux.HandleFunc("POST /api/v1/element/attach", h.AttachElement)

	// Battle APIs
	mux.HandleFunc("POST /api/v1/battle/calculate", h.CalculateDamage)
	mux.HandleFunc("POST /api/v1/battle/dodge", h.Dodge)
	mux.HandleFunc("POST /api/v1/battle/block", h.Block)

	// Narrative APIs
	mux.HandleFunc("POST /api/v1/narrative/trigger", h.TriggerNarrative)
	mux.HandleFunc("POST /api/v1/narrative/deck-event", h.DeckEventNarrative)

	// Dealer APIs
	mux.HandleFunc("GET /api/v1/dealers", h.ListDealers)
	mux.HandleFunc("POST /api/v1/dealers", h.CreateDealer)
	mux.HandleFunc("POST /api/v1/dealers/{dealer_id}/trigger", h.TriggerDealer)

	addr := ":8080"
	log.Printf("ChronoCards Backend 已启动，监听 %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
