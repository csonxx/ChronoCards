package economy

import (
	"math/rand"
	"sort"
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/server/internal/model"
	"github.com/google/uuid"
)

// Service 经济系统服务
type Service struct {
	mu               sync.RWMutex
	auctionListings   map[string]*model.AuctionListing
	bidHistory       map[string][]*model.Bid
	blackMarketListings map[string]*model.BlackMarketListing
	playerWallets    map[string]*model.PlayerWallet
	walletTransactions map[string][]*model.WalletTransaction

	notifyBidFunc        func(auctionID string, bid *model.Bid, listing *model.AuctionListing)
	notifyAuctionEndFunc func(listing *model.AuctionListing)
	notifyBlackMarketFunc func(listing *model.BlackMarketListing)
}

// NewService 创建经济系统服务
func NewService() *Service {
	s := &Service{
		auctionListings:     make(map[string]*model.AuctionListing),
		bidHistory:          make(map[string][]*model.Bid),
		blackMarketListings: make(map[string]*model.BlackMarketListing),
		playerWallets:       make(map[string]*model.PlayerWallet),
		walletTransactions:  make(map[string][]*model.WalletTransaction),
	}
	go s.auctionExpiryChecker()
	go s.initBlackMarket()
	return s
}

func (s *Service) initBlackMarket() {
	s.mu.Lock()
	defer s.mu.Unlock()

	items := []struct {
		id, name, icon string
		rarity    int
		basePrice int
		stock     int
	}{
		{"mysterious_talisman", "神秘符咒", "icon_talisman", 3, 500, 5},
		{"dragon_scale", "龙鳞碎片", "icon_scale", 4, 2000, 2},
		{"phoenix_feather", "凤凰羽毛", "icon_feather", 4, 1500, 3},
		{"shadow_essence", "暗影精华", "icon_essence", 3, 800, 4},
		{"elixir_rare", "稀世丹药", "icon_elixir", 4, 3000, 1},
		{"ancient_sword_shard", "古剑残片", "icon_shard", 3, 1200, 3},
		{"spirit_stone", "灵石", "icon_stone", 2, 300, 10},
		{"celestial_rope", "捆仙绳(伪)", "icon_rope", 3, 600, 2},
	}

	for _, item := range items {
		listing := &model.BlackMarketListing{
			ID:           uuid.New().String(),
			ItemID:       item.id,
			ItemName:     item.name,
			ItemRarity:   item.rarity,
			ItemIcon:     item.icon,
			BasePrice:    item.basePrice,
			CurrentPrice: item.basePrice,
			Stock:        item.stock,
			MaxStock:     item.stock * 3,
			TotalSold:    0,
			RefreshedAt:  time.Now(),
			CreatedAt:    time.Now(),
		}
		s.blackMarketListings[item.id] = listing
	}
}

// ---- Auction ----

func (s *Service) ListAuction(sellerID, sellerName, itemID, itemName, itemIcon string, itemRarity, startPrice, buyoutPrice, durationHours int) *model.AuctionListing {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing := model.NewAuctionListing(sellerID, sellerName, itemID, itemName, itemIcon, itemRarity, startPrice, buyoutPrice, durationHours)
	s.auctionListings[listing.ID] = listing
	s.bidHistory[listing.ID] = []*model.Bid{}
	return listing
}

func (s *Service) GetAuction(auctionID string) *model.AuctionListing {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.auctionListings[auctionID]
}

func (s *Service) ListActiveAuctions() []*model.AuctionListing {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []*model.AuctionListing
	for _, listing := range s.auctionListings {
		if listing.Status == model.AuctionActive {
			result = append(result, listing)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].EndTime.Before(result[j].EndTime)
	})
	return result
}

func (s *Service) ListAuctionsByPlayer(playerID string) (selling, bidOn []*model.AuctionListing) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, listing := range s.auctionListings {
		if listing.SellerID == playerID {
			selling = append(selling, listing)
		}
		if listing.BidderID == playerID {
			bidOn = append(bidOn, listing)
		}
	}
	return
}

func (s *Service) PlaceBid(auctionID, bidderID, bidderName string, amount int) (*model.Bid, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing := s.auctionListings[auctionID]
	if listing == nil || listing.Status != model.AuctionActive {
		return nil, false
	}

	minBid := listing.StartPrice
	if listing.CurrentBid > 0 {
		minBid = listing.CurrentBid + 1
	}
	if amount < minBid {
		return nil, false
	}

	listing.CurrentBid = amount
	listing.BidderID = bidderID
	listing.BidderName = bidderName
	listing.UpdatedAt = time.Now()

	bid := &model.Bid{
		ID:         uuid.New().String(),
		AuctionID:  auctionID,
		BidderID:   bidderID,
		BidderName: bidderName,
		Amount:     amount,
		CreatedAt:  time.Now(),
	}
	s.bidHistory[auctionID] = append(s.bidHistory[auctionID], bid)

	if s.notifyBidFunc != nil {
		go s.notifyBidFunc(auctionID, bid, listing)
	}

	return bid, true
}

func (s *Service) BuyoutAuction(auctionID, buyerID, buyerName string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing := s.auctionListings[auctionID]
	if listing == nil || listing.Status != model.AuctionActive || listing.BuyoutPrice <= 0 {
		return false
	}

	listing.CurrentBid = listing.BuyoutPrice
	listing.BidderID = buyerID
	listing.BidderName = buyerName
	listing.Status = model.AuctionSold
	listing.UpdatedAt = time.Now()

	return true
}

func (s *Service) CancelAuction(auctionID, playerID string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing := s.auctionListings[auctionID]
	if listing == nil || listing.SellerID != playerID || listing.CurrentBid > 0 {
		return false
	}

	listing.Status = model.AuctionCancelled
	listing.UpdatedAt = time.Now()
	return true
}

func (s *Service) GetBidHistory(auctionID string) []*model.Bid {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.bidHistory[auctionID]
}

// ---- Black Market ----

func (s *Service) ListBlackMarket() []*model.BlackMarketListing {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []*model.BlackMarketListing
	for _, listing := range s.blackMarketListings {
		listing.UpdatePrice()
		result = append(result, listing)
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].ItemRarity > result[j].ItemRarity
	})
	return result
}

func (s *Service) BuyBlackMarket(playerID, playerName, itemID string, quantity int) (int, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing := s.blackMarketListings[itemID]
	if listing == nil || listing.Stock < quantity {
		return 0, false
	}

	listing.UpdatePrice()
	totalPrice := listing.CurrentPrice * quantity
	listing.Stock -= quantity
	listing.TotalSold++

	return totalPrice, true
}

func (s *Service) RefreshBlackMarket() {
	s.mu.Lock()
	defer s.mu.Unlock()

	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	refreshCount := r.Intn(3) + 3
	keys := make([]string, 0, len(s.blackMarketListings))
	for k := range s.blackMarketListings {
		keys = append(keys, k)
	}
	r.Shuffle(len(keys), func(i, j int) { keys[i], keys[j] = keys[j], keys[i] })

	for i := 0; i < refreshCount && i < len(keys); i++ {
		listing := s.blackMarketListings[keys[i]]
		newStock := r.Intn(listing.MaxStock/2) + listing.MaxStock/2
		if newStock < 1 {
			newStock = 1
		}
		listing.Stock = newStock
		listing.RefreshedAt = time.Now()
		listing.UpdatePrice()

		if s.notifyBlackMarketFunc != nil {
			go s.notifyBlackMarketFunc(listing)
		}
	}
}

func (s *Service) GetBlackMarketListing(itemID string) *model.BlackMarketListing {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.blackMarketListings[itemID]
}

// ---- Wallet ----

func (s *Service) GetOrCreateWallet(playerID string) *model.PlayerWallet {
	s.mu.Lock()
	defer s.mu.Unlock()

	if wallet, ok := s.playerWallets[playerID]; ok {
		return wallet
	}

	wallet := model.NewPlayerWallet(playerID)
	s.playerWallets[playerID] = wallet
	s.walletTransactions[playerID] = []*model.WalletTransaction{}
	return wallet
}

func (s *Service) GetWallet(playerID string) *model.PlayerWallet {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.playerWallets[playerID]
}

func (s *Service) Spend(playerID, currency string, amount int, txType model.TransactionType, note string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	wallet := s.playerWallets[playerID]
	if wallet == nil || !wallet.CanSpend(currency, amount) {
		return false
	}

	wallet.Spend(currency, amount)

	tx := &model.WalletTransaction{
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Type:      txType,
		Amount:    -amount,
		Balance:   s.getBalance(wallet, currency),
		Currency:  currency,
		Note:      note,
		CreatedAt: time.Now(),
	}
	s.walletTransactions[playerID] = append(s.walletTransactions[playerID], tx)
	return true
}

func (s *Service) Earn(playerID, currency string, amount int, txType model.TransactionType, note string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	wallet := s.playerWallets[playerID]
	if wallet == nil {
		wallet = model.NewPlayerWallet(playerID)
		s.playerWallets[playerID] = wallet
		s.walletTransactions[playerID] = []*model.WalletTransaction{}
	}

	wallet.Earn(currency, amount)

	tx := &model.WalletTransaction{
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Type:      txType,
		Amount:    amount,
		Balance:   s.getBalance(wallet, currency),
		Currency:  currency,
		Note:      note,
		CreatedAt: time.Now(),
	}
	s.walletTransactions[playerID] = append(s.walletTransactions[playerID], tx)
}

func (s *Service) getBalance(wallet *model.PlayerWallet, currency string) int {
	switch currency {
	case "gold":
		return wallet.Gold
	case "silver":
		return wallet.Silver
	}
	return 0
}

func (s *Service) GetTransactions(playerID string, limit int) []*model.WalletTransaction {
	s.mu.RLock()
	defer s.mu.RUnlock()

	txs := s.walletTransactions[playerID]
	if limit <= 0 {
		limit = 50
	}
	if len(txs) <= limit {
		return txs
	}
	return txs[len(txs)-limit:]
}

func (s *Service) GetStats(playerID string) (int, int) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	wallet := s.playerWallets[playerID]
	if wallet == nil {
		return 0, 0
	}
	return wallet.TotalEarned, wallet.TotalSpent
}

// ---- Timer ----

func (s *Service) auctionExpiryChecker() {
	ticker := time.NewTicker(1 * time.Minute)
	for range ticker.C {
		s.mu.Lock()
		for _, listing := range s.auctionListings {
			if listing.Status == model.AuctionActive && time.Now().After(listing.EndTime) {
				listing.Status = model.AuctionExpired
				listing.UpdatedAt = time.Now()
				if s.notifyAuctionEndFunc != nil {
					go s.notifyAuctionEndFunc(listing)
				}
			}
		}
		s.mu.Unlock()
	}
}

// ---- Callbacks ----

func (s *Service) OnBid(f func(auctionID string, bid *model.Bid, listing *model.AuctionListing)) {
	s.notifyBidFunc = f
}

func (s *Service) OnAuctionEnd(f func(listing *model.AuctionListing)) {
	s.notifyAuctionEndFunc = f
}

func (s *Service) OnBlackMarketRefresh(f func(listing *model.BlackMarketListing)) {
	s.notifyBlackMarketFunc = f
}
