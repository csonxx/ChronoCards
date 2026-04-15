package store

import (
	"errors"
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/server/internal/model"
)

// ErrPlayerLocationNotFound 玩家位置未找到
var ErrPlayerLocationNotFound = errors.New("player location not found")

// StoreInterface 存储层接口（支持内存或PostgreSQL）
type StoreInterface interface {
	CreatePlayer(player *model.Player)
	GetPlayer(id string) (*model.Player, bool)
	UpdatePlayer(player *model.Player)
	ListPlayers() []*model.Player
	CreateDeck(deck *model.Deck)
	GetDeck(id string) (*model.Deck, bool)
	UpdateDeck(deck *model.Deck)
	GetDecksByPlayer(playerID string) []*model.Deck
	GetDealer(id string) (*model.Dealer, bool)
	ListDealers() []*model.Dealer
	CreateDealer(dealer *model.Dealer)
	// Inventory 操作
	GetInventory(playerID string) (*model.PlayerInventory, bool)
	CreateInventory(inv *model.PlayerInventory)
	UpdateInventory(inv *model.PlayerInventory)
	// Equipment 操作
	GetEquipment(playerID string) (*model.Equipment, bool)
	CreateEquipment(eq *model.Equipment)
	UpdateEquipment(eq *model.Equipment)
	// Player Location 操作
	SetPlayerLocation(playerID, locationID string) error
	GetPlayerLocation(playerID string) (*model.PlayerLocation, error)
	AddVisited(playerID, locationID string)
	// Auction 操作
	CreateAuction(item *model.AuctionItem) error
	GetAuction(id string) (*model.AuctionItem, bool)
	UpdateAuction(item *model.AuctionItem) error
	ListActiveAuctions() []*model.AuctionItem
	ListAuctionsBySeller(sellerID string) []*model.AuctionItem
	ListAuctionsByBidder(bidderID string) []*model.AuctionItem
	CreateBid(bid *model.AuctionBid) error
	GetBidsByAuction(auctionID string) []*model.AuctionBid
	// Player money operations
	GetPlayerMoney(playerID string) (int, error)
	DeductPlayerMoney(playerID string, amount int) error
	AddPlayerMoney(playerID string, amount int) error
	// Item operations for auction settlement
	TransferItem(sellerID, buyerID, itemID string) error
}

// Store 内存数据存储
type Store struct {
	mu               sync.RWMutex
	players          map[string]*model.Player
	decks            map[string]*model.Deck
	dealers          map[string]*model.Dealer
	inventories      map[string]*model.PlayerInventory
	equipments       map[string]*model.Equipment
	playerLocations  map[string]*model.PlayerLocation
	auctions         map[string]*model.AuctionItem
	bids             map[string][]*model.AuctionBid
}

// NewStore 创建存储
func NewStore() *Store {
	s := &Store{
		players:          make(map[string]*model.Player),
		decks:            make(map[string]*model.Deck),
		dealers:          make(map[string]*model.Dealer),
		inventories:      make(map[string]*model.PlayerInventory),
		equipments:       make(map[string]*model.Equipment),
		playerLocations:  make(map[string]*model.PlayerLocation),
		auctions:         make(map[string]*model.AuctionItem),
		bids:             make(map[string][]*model.AuctionBid),
	}
	// 初始化默认发牌员
	s.initDefaultDealers()
	return s
}

// initDefaultDealers 初始化默认发牌员
func (s *Store) initDefaultDealers() {
	dealers := []*model.Dealer{
		{
			ID:                 "teahouse-1",
			Type:               model.DealerTeahouse,
			Name:               "茶馆说书人",
			Location:           "中原武林-长安城",
			Description:        "茶馆中的老说书人，知晓无数江湖秘闻",
			InteractionPrompt:  "说书人轻敲桌面：客官，可想听一段江湖旧事？",
			Weight:             2,
		},
		{
			ID:                 "bounty-1",
			Type:               model.DealerBountyBoard,
			Name:               "悬赏公告栏",
			Location:           "中原武林-洛阳城",
			Description:        "江湖悬赏告示板，张贴着各类悬赏任务",
			InteractionPrompt:  "悬赏公告栏上贴满了江湖悬赏令",
			Weight:             2,
		},
		{
			ID:                 "inn-1",
			Type:               model.DealerInn,
			Name:               "悦来客栈",
			Location:           "江南水乡-苏州城",
			Description:        "江湖著名的连锁客栈，南来北往的侠士多在此歇脚",
			InteractionPrompt:  "客栈掌柜笑迎：客官，楼上雅间请",
			Weight:             3, // 客栈权重高，因为可以在任何地方发生
		},
		{
			ID:                 "merchant-1",
			Type:               model.DealerMerchant,
			Name:               "神秘商贩",
			Location:           "随机",
			Description:        "行踪不定的神秘商人，专卖稀罕物件",
			InteractionPrompt:  "商贩神秘兮兮：客官，我这有些稀罕物件...",
			Weight:             1,
		},
		{
			ID:                 "enemy-1",
			Type:               model.DealerEnemy,
			Name:               "山道匪帮",
			Location:           "西北边塞",
			Description:        "山道上的匪徒，战斗力不强但知晓江湖传闻",
			InteractionPrompt:  "匪徒跪地求饶：饶命！我说！我什么都说！",
			Weight:             1,
		},
		{
			ID:                 "dynamic-1",
			Type:               model.DealerDynamicEncounter,
			Name:               "动态遭遇",
			Location:           "随机",
			Description:        "开放世界中随机生成的遭遇",
			InteractionPrompt:  "前方似乎有什么动静...",
			Weight:             2,
		},
	}

	for _, d := range dealers {
		s.dealers[d.ID] = d
	}
}

// ---- Player 操作 ----

// CreatePlayer 创建玩家
func (s *Store) CreatePlayer(player *model.Player) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.players[player.ID] = player
}

// GetPlayer 获取玩家
func (s *Store) GetPlayer(id string) (*model.Player, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.players[id]
	return p, ok
}

// UpdatePlayer 更新玩家
func (s *Store) UpdatePlayer(player *model.Player) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.players[player.ID] = player
}

// ListPlayers 列出所有玩家
func (s *Store) ListPlayers() []*model.Player {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*model.Player, 0, len(s.players))
	for _, p := range s.players {
		result = append(result, p)
	}
	return result
}

// ---- Deck 操作 ----

// CreateDeck 创建卡组
func (s *Store) CreateDeck(deck *model.Deck) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.decks[deck.ID] = deck
}

// GetDeck 获取卡组
func (s *Store) GetDeck(id string) (*model.Deck, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	d, ok := s.decks[id]
	return d, ok
}

// UpdateDeck 更新卡组
func (s *Store) UpdateDeck(deck *model.Deck) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.decks[deck.ID] = deck
}

// GetDecksByPlayer 获取玩家的所有卡组
func (s *Store) GetDecksByPlayer(playerID string) []*model.Deck {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*model.Deck, 0)
	for _, d := range s.decks {
		if d.PlayerID == playerID {
			result = append(result, d)
		}
	}
	return result
}

// ---- Dealer 操作 ----

// CreateDealer 创建发牌员
func (s *Store) CreateDealer(dealer *model.Dealer) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.dealers[dealer.ID] = dealer
}

// GetDealer 获取发牌员
func (s *Store) GetDealer(id string) (*model.Dealer, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	d, ok := s.dealers[id]
	return d, ok
}

// ListDealers 列出所有发牌员
func (s *Store) ListDealers() []*model.Dealer {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*model.Dealer, 0, len(s.dealers))
	for _, d := range s.dealers {
		result = append(result, d)
	}
	return result
}

// ---- Inventory 操作 ----

// GetInventory 获取玩家背包
func (s *Store) GetInventory(playerID string) (*model.PlayerInventory, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	inv, ok := s.inventories[playerID]
	return inv, ok
}

// CreateInventory 创建玩家背包
func (s *Store) CreateInventory(inv *model.PlayerInventory) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.inventories[inv.PlayerID] = inv
}

// UpdateInventory 更新玩家背包
func (s *Store) UpdateInventory(inv *model.PlayerInventory) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.inventories[inv.PlayerID] = inv
}

// ---- Equipment 操作 ----

// GetEquipment 获取玩家装备
func (s *Store) GetEquipment(playerID string) (*model.Equipment, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	eq, ok := s.equipments[playerID]
	return eq, ok
}

// CreateEquipment 创建玩家装备
func (s *Store) CreateEquipment(eq *model.Equipment) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.equipments[eq.PlayerID] = eq
}

// UpdateEquipment 更新玩家装备
func (s *Store) UpdateEquipment(eq *model.Equipment) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.equipments[eq.PlayerID] = eq
}

// ---- PlayerLocation 操作 ----

// SetPlayerLocation 设置玩家位置
func (s *Store) SetPlayerLocation(playerID, locationID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// 简单的位置设置：使用"region-central-plains"作为region
	// 实际应该根据location查表
	regionID := "region-central-plains"

	existing, ok := s.playerLocations[playerID]
	if ok {
		existing.CurrentLocation = locationID
		existing.CurrentRegion = regionID
		existing.UpdatedAt = time.Now()
	} else {
		s.playerLocations[playerID] = model.NewPlayerLocation(playerID, locationID, regionID)
	}

	return nil
}

// GetPlayerLocation 获取玩家位置
func (s *Store) GetPlayerLocation(playerID string) (*model.PlayerLocation, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	loc, ok := s.playerLocations[playerID]
	if !ok {
		return nil, ErrPlayerLocationNotFound
	}

	return loc, nil
}

// AddVisited 添加已访问记录
func (s *Store) AddVisited(playerID, locationID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	regionID := "region-central-plains" // 简化处理

	existing, ok := s.playerLocations[playerID]
	if ok {
		existing.AddVisited(locationID, regionID)
		existing.TotalTravelCount++
		existing.UpdatedAt = time.Now()
	} else {
		newLoc := model.NewPlayerLocation(playerID, locationID, regionID)
		newLoc.TotalTravelCount = 1
		s.playerLocations[playerID] = newLoc
	}
}

// ---- Auction 操作 ----

// CreateAuction 创建拍卖
func (s *Store) CreateAuction(item *model.AuctionItem) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.auctions[item.ID] = item
	s.bids[item.ID] = []*model.AuctionBid{}
	return nil
}

// GetAuction 获取拍卖
func (s *Store) GetAuction(id string) (*model.AuctionItem, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	a, ok := s.auctions[id]
	return a, ok
}

// UpdateAuction 更新拍卖
func (s *Store) UpdateAuction(item *model.AuctionItem) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.auctions[item.ID] = item
	return nil
}

// ListActiveAuctions 列出所有进行中的拍卖
func (s *Store) ListActiveAuctions() []*model.AuctionItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*model.AuctionItem, 0, len(s.auctions))
	for _, a := range s.auctions {
		if a.State == model.AuctionStateActive {
			result = append(result, a)
		}
	}
	return result
}

// ListAuctionsBySeller 列出卖家所有拍卖
func (s *Store) ListAuctionsBySeller(sellerID string) []*model.AuctionItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*model.AuctionItem, 0)
	for _, a := range s.auctions {
		if a.SellerID == sellerID {
			result = append(result, a)
		}
	}
	return result
}

// ListAuctionsByBidder 列出竞拍者参与的所有拍卖
func (s *Store) ListAuctionsByBidder(bidderID string) []*model.AuctionItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*model.AuctionItem, 0)
	for _, a := range s.auctions {
		if a.CurrentBidder == bidderID {
			result = append(result, a)
		}
	}
	return result
}

// CreateBid 创建出价记录
func (s *Store) CreateBid(bid *model.AuctionBid) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.bids[bid.AuctionID] = append(s.bids[bid.AuctionID], bid)
	return nil
}

// GetBidsByAuction 获取拍卖的所有出价
func (s *Store) GetBidsByAuction(auctionID string) []*model.AuctionBid {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.bids[auctionID]
}

// ---- Player Money 操作 ----

// GetPlayerMoney 获取玩家金钱
func (s *Store) GetPlayerMoney(playerID string) (int, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.players[playerID]
	if !ok {
		return 0, ErrPlayerLocationNotFound
	}
	return p.Money, nil
}

// DeductPlayerMoney 扣除玩家金钱
func (s *Store) DeductPlayerMoney(playerID string, amount int) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.players[playerID]
	if !ok {
		return ErrPlayerLocationNotFound
	}
	if p.Money < amount {
		return ErrPlayerLocationNotFound
	}
	p.Money -= amount
	s.players[playerID] = p
	return nil
}

// AddPlayerMoney 增加玩家金钱
func (s *Store) AddPlayerMoney(playerID string, amount int) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.players[playerID]
	if !ok {
		return ErrPlayerLocationNotFound
	}
	p.Money += amount
	s.players[playerID] = p
	return nil
}

// TransferItem 转移物品（拍卖结算用）
func (s *Store) TransferItem(sellerID, buyerID, itemID string) error {
	// 简化实现：从卖家背包移除，加入买家背包
	s.mu.Lock()
	defer s.mu.Unlock()

	// 卖家背包移除
	sellerInv, sellerOk := s.inventories[sellerID]
	if !sellerOk {
		return ErrPlayerLocationNotFound
	}
	newSlots := make([]model.InventorySlot, 0)
	for _, slot := range sellerInv.Slots {
		if slot.Item == nil || slot.Item.ID != itemID {
			newSlots = append(newSlots, slot)
		}
	}
	sellerInv.Slots = newSlots

	// 买家背包添加
	buyerInv, buyerOk := s.inventories[buyerID]
	if !buyerOk {
		buyerInv = &model.PlayerInventory{
			PlayerID: buyerID,
			Slots:    make([]model.InventorySlot, 0, 30),
			Capacity: 30,
			Coins:    0,
		}
	}
	// 查找空位
	emptyIdx := -1
	for i, slot := range buyerInv.Slots {
		if slot.Item == nil {
			emptyIdx = i
			break
		}
	}
	if emptyIdx >= 0 {
		buyerInv.Slots[emptyIdx] = model.InventorySlot{Item: &model.Item{ID: itemID}, Count: 1}
	} else if len(buyerInv.Slots) < buyerInv.Capacity {
		buyerInv.Slots = append(buyerInv.Slots, model.InventorySlot{Item: &model.Item{ID: itemID}, Count: 1})
	}

	s.inventories[sellerID] = sellerInv
	s.inventories[buyerID] = buyerInv
	return nil
}

