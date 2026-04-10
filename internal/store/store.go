package store

import (
	"sync"
	"github.com/csonxx/ChronoCards/internal/model"
)

// Store 内存数据存储
type Store struct {
	mu      sync.RWMutex
	players map[string]*model.Player
	decks   map[string]*model.Deck
	dealers map[string]*model.Dealer
}

// NewStore 创建存储
func NewStore() *Store {
	s := &Store{
		players: make(map[string]*model.Player),
		decks:   make(map[string]*model.Deck),
		dealers: make(map[string]*model.Dealer),
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
