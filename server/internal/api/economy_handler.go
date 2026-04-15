package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/server/internal/game/economy"
	"github.com/csonxx/ChronoCards/server/internal/model"
	"nhooyr.io/websocket"
)

var economySvc = economy.NewService()

func InitEconomyService() *economy.Service {
	return economySvc
}

// ---- WebSocket ----

type wsAuctionClient struct {
	conn     *websocket.Conn
	send     chan []byte
	playerID string
}

var auctionHub = &AuctionHub{
	clients:    make(map[*wsAuctionClient]bool),
	broadcast:  make(chan *AuctionNotification),
	register:   make(chan *wsAuctionClient),
	unregister: make(chan *wsAuctionClient),
}

type AuctionNotification struct {
	Type      string      `json:"type"`
	AuctionID string      `json:"auction_id,omitempty"`
	Data      interface{} `json:"data"`
}

type AuctionHub struct {
	mu         sync.RWMutex
	clients    map[*wsAuctionClient]bool
	broadcast  chan *AuctionNotification
	register   chan *wsAuctionClient
	unregister chan *wsAuctionClient
}

func (h *AuctionHub) run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			log.Printf("WS client connected: %s", client.playerID)
		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mu.Unlock()
		case notification := <-h.broadcast:
			h.mu.RLock()
			message, _ := json.Marshal(notification)
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(h.clients, client)
				}
			}
			h.mu.RUnlock()
		}
	}
}

func init() {
	go auctionHub.run()
}

func (h *Handler) HandleAuctionWebSocket(w http.ResponseWriter, r *http.Request) {
	playerID := r.URL.Query().Get("player_id")
	if playerID == "" {
		playerID = "anonymous"
	}

	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		CompressionMode: websocket.CompressionContextTakeover,
	})
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	client := &wsAuctionClient{
		conn:     conn,
		send:     make(chan []byte, 256),
		playerID: playerID,
	}

	auctionHub.register <- client
	go client.writePump()
	client.readPump()
}

func (c *wsAuctionClient) readPump() {
	defer func() {
		auctionHub.unregister <- c
		c.conn.Close(websocket.StatusNormalClosure, "")
	}()

	ctx := context.Background()
	for {
		_, message, err := c.conn.Read(ctx)
		if err != nil {
			break
		}
		var msg map[string]string
		if json.Unmarshal(message, &msg) == nil && msg["type"] == "ping" {
			c.send <- []byte(`{"type":"pong"}`)
		}
	}
}

func (c *wsAuctionClient) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	ctx := context.Background()
	defer func() {
		ticker.Stop()
		c.conn.Close(websocket.StatusNormalClosure, "")
	}()

	for {
		select {
		case message, ok := <-c.send:
			if !ok {
				return
			}
			c.conn.Write(ctx, websocket.MessageText, message)
		case <-ticker.C:
			c.conn.Ping(ctx)
		}
	}
}

// ---- Auction Handlers ----

func (h *Handler) CreateAuction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}
	var req struct {
		SellerID      string `json:"seller_id"`
		SellerName    string `json:"seller_name"`
		ItemID        string `json:"item_id"`
		ItemName      string `json:"item_name"`
		ItemIcon      string `json:"item_icon"`
		ItemRarity    int    `json:"item_rarity"`
		StartPrice    int    `json:"start_price"`
		BuyoutPrice   int    `json:"buyout_price"`
		DurationHours int    `json:"duration_hours"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.SellerID == "" || req.ItemID == "" {
		h.badRequest(w, "invalid request")
		return
	}
	if req.DurationHours <= 0 {
		req.DurationHours = 24
	}

	listing := economySvc.ListAuction(
		req.SellerID, req.SellerName,
		req.ItemID, req.ItemName, req.ItemIcon, req.ItemRarity,
		req.StartPrice, req.BuyoutPrice, req.DurationHours,
	)
	h.json(w, http.StatusOK, listing)
}

func (h *Handler) ListAuctions(w http.ResponseWriter, r *http.Request) {
	listings := economySvc.ListActiveAuctions()
	h.json(w, http.StatusOK, map[string]interface{}{
		"auctions": listings,
		"total":    len(listings),
	})
}

func (h *Handler) GetAuction(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("auction_id")
	listing := economySvc.GetAuction(id)
	if listing == nil {
		h.notFound(w)
		return
	}
	h.json(w, http.StatusOK, listing)
}

func (h *Handler) GetPlayerAuctions(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	selling, bidOn := economySvc.ListAuctionsByPlayer(playerID)
	h.json(w, http.StatusOK, map[string]interface{}{
		"selling": selling,
		"bid_on":  bidOn,
	})
}

func (h *Handler) PlaceBid(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}
	auctionID := r.PathValue("auction_id")
	var req struct {
		BidderID   string `json:"bidder_id"`
		BidderName string `json:"bidder_name"`
		Amount     int    `json:"amount"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.BidderID == "" {
		h.badRequest(w, "invalid request")
		return
	}

	bid, ok := economySvc.PlaceBid(auctionID, req.BidderID, req.BidderName, req.Amount)
	if !ok {
		h.error(w, http.StatusBadRequest, "bid failed")
		return
	}

	listing := economySvc.GetAuction(auctionID)
	auctionHub.broadcast <- &AuctionNotification{
		Type:      "bid",
		AuctionID: auctionID,
		Data:      map[string]interface{}{"bid": bid, "listing": listing},
	}

	h.json(w, http.StatusOK, map[string]interface{}{"bid": bid, "message": "bid placed successfully"})
}

func (h *Handler) BuyoutAuction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}
	auctionID := r.PathValue("auction_id")
	var req struct {
		BuyerID   string `json:"buyer_id"`
		BuyerName string `json:"buyer_name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.BuyerID == "" {
		h.badRequest(w, "invalid request")
		return
	}

	ok := economySvc.BuyoutAuction(auctionID, req.BuyerID, req.BuyerName)
	if !ok {
		h.error(w, http.StatusBadRequest, "buyout failed")
		return
	}

	listing := economySvc.GetAuction(auctionID)
	auctionHub.broadcast <- &AuctionNotification{
		Type:      "auction_end",
		AuctionID: auctionID,
		Data:      listing,
	}

	h.json(w, http.StatusOK, map[string]string{"message": "buyout successful"})
}

func (h *Handler) CancelAuction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		h.badRequest(w, "method not allowed")
		return
	}
	auctionID := r.PathValue("auction_id")
	playerID := r.URL.Query().Get("player_id")
	if playerID == "" {
		h.badRequest(w, "player_id required")
		return
	}

	ok := economySvc.CancelAuction(auctionID, playerID)
	if !ok {
		h.error(w, http.StatusBadRequest, "cancel failed")
		return
	}
	h.json(w, http.StatusOK, map[string]string{"message": "cancelled"})
}

func (h *Handler) GetBidHistory(w http.ResponseWriter, r *http.Request) {
	auctionID := r.PathValue("auction_id")
	bids := economySvc.GetBidHistory(auctionID)
	h.json(w, http.StatusOK, map[string]interface{}{"bids": bids, "total": len(bids)})
}

// ---- Black Market Handlers ----

func (h *Handler) ListBlackMarket(w http.ResponseWriter, r *http.Request) {
	listings := economySvc.ListBlackMarket()
	h.json(w, http.StatusOK, map[string]interface{}{"items": listings, "total": len(listings)})
}

func (h *Handler) BuyBlackMarket(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}
	var req struct {
		PlayerID   string `json:"player_id"`
		PlayerName string `json:"player_name"`
		ItemID     string `json:"item_id"`
		Quantity   int    `json:"quantity"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerID == "" || req.ItemID == "" {
		h.badRequest(w, "invalid request")
		return
	}
	if req.Quantity <= 0 {
		req.Quantity = 1
	}

	price, ok := economySvc.BuyBlackMarket(req.PlayerID, req.PlayerName, req.ItemID, req.Quantity)
	if !ok {
		h.error(w, http.StatusBadRequest, "purchase failed - out of stock")
		return
	}

	economySvc.Spend(req.PlayerID, "gold", price, model.TransactionBlackMarketBuy, "黑市购买:"+req.ItemID)

	h.json(w, http.StatusOK, map[string]interface{}{
		"item_id": req.ItemID, "quantity": req.Quantity, "price": price, "message": "purchase successful",
	})
}

func (h *Handler) RefreshBlackMarket(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}
	economySvc.RefreshBlackMarket()
	auctionHub.broadcast <- &AuctionNotification{
		Type: "blackmarket_refresh",
		Data: economySvc.ListBlackMarket(),
	}
	h.json(w, http.StatusOK, map[string]string{"message": "blackmarket refreshed"})
}

// ---- Wallet Handlers ----

func (h *Handler) GetWallet(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	wallet := economySvc.GetOrCreateWallet(playerID)
	h.json(w, http.StatusOK, wallet)
}

func (h *Handler) GetWalletTransactions(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	limit := 50
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}
	txs := economySvc.GetTransactions(playerID, limit)
	h.json(w, http.StatusOK, map[string]interface{}{"transactions": txs, "total": len(txs)})
}

func (h *Handler) GetWalletStats(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	earned, spent := economySvc.GetStats(playerID)
	h.json(w, http.StatusOK, map[string]interface{}{
		"total_earned": earned, "total_spent": spent, "net": earned - spent,
	})
}

func (h *Handler) RewardPlayer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.badRequest(w, "method not allowed")
		return
	}
	playerID := r.PathValue("player_id")
	var req struct {
		Currency string `json:"currency"`
		Amount   int    `json:"amount"`
		Note     string `json:"note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Currency == "" || req.Amount <= 0 {
		h.badRequest(w, "invalid request")
		return
	}

	economySvc.Earn(playerID, req.Currency, req.Amount, model.TransactionReward, req.Note)
	wallet := economySvc.GetWallet(playerID)
	h.json(w, http.StatusOK, map[string]interface{}{"message": "rewarded", "wallet": wallet})
}
