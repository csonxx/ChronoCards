package main

import (
	"flag"
	"log"
	"net/http"
	"os"

	"github.com/csonxx/ChronoCards/server/internal/api"
	"github.com/csonxx/ChronoCards/server/internal/game/world"
	"github.com/csonxx/ChronoCards/server/internal/store"
)

func main() {
	useDB := flag.Bool("db", false, "启用PostgreSQL持久化存储")
	flag.Parse()

	log.Println("ChronoCards Backend 启动中...")

	var s store.StoreInterface
	if *useDB || os.Getenv("DB_ENABLED") == "true" {
		cfg := store.NewDBConfig()
		db, err := store.Connect(cfg)
		if err != nil {
			log.Printf("警告: 数据库连接失败 (%v)，回退到内存存储", err)
			s = store.NewStore()
		} else {
			pgStore := store.NewPGStore(db)
			if err := pgStore.InitFromDB(); err != nil {
				log.Printf("警告: 从数据库加载数据失败 (%v)，继续使用空存储", err)
			}
			s = pgStore
			log.Println("已启用 PostgreSQL 持久化存储")
		}
	} else {
		s = store.NewStore()
		log.Println("使用内存存储（数据重启后会丢失）")
	}

	h := api.NewHandler(s)

	// 创建世界地图服务
	worldSvc := world.NewService(s)
	worldHandler := api.NewWorldHandler(worldSvc)

	// 初始化经济系统服务
	api.InitEconomyService()

	mux := http.NewServeMux()

	// 健康检查
	mux.HandleFunc("GET /api/v1/health", h.Health)

	// Player APIs
	mux.HandleFunc("POST /api/v1/players", h.CreatePlayer)
	mux.HandleFunc("GET /api/v1/players/{player_id}", h.GetPlayer)
	mux.HandleFunc("PATCH /api/v1/players/{player_id}", h.UpdatePlayer)
	mux.HandleFunc("GET /api/v1/players/{player_id}/battle-state", h.GetBattleState)
	mux.HandleFunc("GET /api/v1/player/status/{player_id}", h.GetPlayerStatus)
	mux.HandleFunc("POST /api/v1/players/{player_id}/level-up", h.LevelUp)

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
	mux.HandleFunc("POST /api/v1/battle/action", h.BattleAction)

	// Narrative APIs
	mux.HandleFunc("POST /api/v1/narrative/trigger", h.TriggerNarrative)
	mux.HandleFunc("POST /api/v1/narrative/generate", h.GenerateNarrative)
	mux.HandleFunc("POST /api/v1/narrative/deck-event", h.DeckEventNarrative)

	// Dealer APIs
	mux.HandleFunc("GET /api/v1/dealers", h.ListDealers)
	mux.HandleFunc("POST /api/v1/dealers", h.CreateDealer)
	mux.HandleFunc("POST /api/v1/dealers/{dealer_id}/trigger", h.TriggerDealer)

	// World Map APIs
	mux.HandleFunc("GET /api/v1/world", worldHandler.GetWorldOverview)
	mux.HandleFunc("GET /api/v1/world/locations", worldHandler.ListLocations)
	mux.HandleFunc("GET /api/v1/world/locations/{id}", worldHandler.GetLocation)
	mux.HandleFunc("GET /api/v1/world/locations/{id}/connections", worldHandler.GetLocationConnections)
	mux.HandleFunc("GET /api/v1/players/{player_id}/location", worldHandler.GetPlayerLocation)
	mux.HandleFunc("POST /api/v1/players/{player_id}/location/navigate", worldHandler.Navigate)
	mux.HandleFunc("POST /api/v1/players/{player_id}/location/set", worldHandler.SetPlayerLocation)
	mux.HandleFunc("GET /api/v1/players/{player_id}/visited", worldHandler.GetPlayerVisited)

	// Shop APIs
	mux.HandleFunc("GET /api/v1/shops/{shop_type}", h.GetShopInventory)

	// Auction APIs
	mux.HandleFunc("POST /api/v1/auction/list", h.ListAuction)
	mux.HandleFunc("GET /api/v1/auction/active", h.GetActiveAuctions)
	mux.HandleFunc("POST /api/v1/auction/{id}/bid", h.BidOnAuction)
	mux.HandleFunc("GET /api/v1/auction/{id}", h.GetAuctionDetail)

	// Inventory APIs
	mux.HandleFunc("GET /api/v1/players/{player_id}/inventory", h.GetInventory)
	mux.HandleFunc("POST /api/v1/players/{player_id}/inventory/equip", h.EquipItem)
	mux.HandleFunc("POST /api/v1/players/{player_id}/inventory/unequip", h.UnequipItem)
	mux.HandleFunc("POST /api/v1/players/{player_id}/inventory/use", h.UseItem)
	mux.HandleFunc("POST /api/v1/players/{player_id}/inventory/add", h.AddItemToInventory)

	// Item APIs
	mux.HandleFunc("GET /api/v1/items/presets", h.ListPresetItems)

	// Skill APIs
	mux.HandleFunc("GET /api/v1/skills/presets", h.ListPresetSkills)
	mux.HandleFunc("POST /api/v1/players/{player_id}/skills", h.LearnSkill)
	mux.HandleFunc("GET /api/v1/players/{player_id}/skills", h.ListSkills)
	mux.HandleFunc("POST /api/v1/players/{player_id}/skills/use", h.UseSkill)
	mux.HandleFunc("GET /api/v1/players/{player_id}/skills/{skill_id}/cooldown", h.GetSkillCooldown)

	// Economy APIs - Auction
	mux.HandleFunc("POST /api/v1/auctions", h.CreateAuction)
	mux.HandleFunc("GET /api/v1/auctions", h.ListAuctions)
	mux.HandleFunc("GET /api/v1/auctions/{auction_id}", h.GetAuction)
	mux.HandleFunc("GET /api/v1/auctions/{auction_id}/bids", h.GetBidHistory)
	mux.HandleFunc("POST /api/v1/auctions/{auction_id}/bid", h.PlaceBid)
	mux.HandleFunc("POST /api/v1/auctions/{auction_id}/buyout", h.BuyoutAuction)
	mux.HandleFunc("DELETE /api/v1/auctions/{auction_id}", h.CancelAuction)
	mux.HandleFunc("GET /api/v1/players/{player_id}/auctions", h.GetPlayerAuctions)

	// Economy APIs - Black Market
	mux.HandleFunc("GET /api/v1/blackmarket", h.ListBlackMarket)
	mux.HandleFunc("POST /api/v1/blackmarket/buy", h.BuyBlackMarket)
	mux.HandleFunc("POST /api/v1/blackmarket/refresh", h.RefreshBlackMarket)

	// Economy APIs - Wallet
	mux.HandleFunc("GET /api/v1/players/{player_id}/wallet", h.GetWallet)
	mux.HandleFunc("GET /api/v1/players/{player_id}/wallet/transactions", h.GetWalletTransactions)
	mux.HandleFunc("GET /api/v1/players/{player_id}/wallet/stats", h.GetWalletStats)
	mux.HandleFunc("POST /api/v1/players/{player_id}/wallet/reward", h.RewardPlayer)

	// WebSocket for real-time auction notifications
	mux.HandleFunc("GET /api/v1/ws/auctions", h.HandleAuctionWebSocket)

	addr := ":8080"
	log.Printf("ChronoCards Backend 已启动，监听 %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
