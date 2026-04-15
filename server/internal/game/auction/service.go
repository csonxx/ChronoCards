package auction

import (
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/server/internal/model"
	"github.com/google/uuid"
)

// StoreInterface 拍卖存储接口
type StoreInterface interface {
	CreateAuction(item *model.AuctionItem) error
	GetAuction(id string) (*model.AuctionItem, bool)
	UpdateAuction(item *model.AuctionItem) error
	ListActiveAuctions() []*model.AuctionItem
	ListAuctionsBySeller(sellerID string) []*model.AuctionItem
	ListAuctionsByBidder(bidderID string) []*model.AuctionItem
	CreateBid(bid *model.Bid) error
	GetBidsByAuction(auctionID string) []*model.Bid
	GetPlayerMoney(playerID string) (int, error)
	DeductPlayerMoney(playerID string, amount int) error
	AddPlayerMoney(playerID string, amount int) error
	TransferItem(sellerID, buyerID, itemID string) error
}

// Service 拍卖行服务
type Service struct {
	store  StoreInterface
	mu     sync.RWMutex
	closed map[string]chan struct{}
}

// NewService 创建拍卖服务
func NewService(store StoreInterface) *Service {
	return &Service{
		store:  store,
		closed: make(map[string]chan struct{}),
	}
}

// ListItem 挂售物品
func (s *Service) ListItem(req *ListAuctionRequest) (*model.AuctionItem, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if req.PlayerID == "" {
		return nil, ErrInvalidSeller
	}
	if req.ItemID == "" {
		return nil, ErrInvalidItem
	}
	if req.StartingBid <= 0 {
		return nil, ErrInvalidStartingBid
	}

	if req.DurationMins <= 0 {
		req.DurationMins = 30
	}
	if req.Location == "" {
		req.Location = "拍卖行-苏州总行"
	}

	// 手续费：起拍价5%
	fee := req.StartingBid * 5 / 100
	if fee < 1 {
		fee = 1
	}

	playerMoney, err := s.store.GetPlayerMoney(req.PlayerID)
	if err != nil {
		return nil, err
	}
	if playerMoney < fee {
		return nil, ErrInsufficientFunds
	}

	// 扣除手续费
	if err := s.store.DeductPlayerMoney(req.PlayerID, fee); err != nil {
		return nil, err
	}

	// 创建拍卖
	item := model.NewAuctionItem(
		req.PlayerID,
		req.ItemID,
		req.ItemName,
		req.ItemRarity,
		req.StartingBid,
		req.DurationMins,
		req.Location,
	)

	if err := s.store.CreateAuction(item); err != nil {
		s.store.AddPlayerMoney(req.PlayerID, fee)
		return nil, err
	}

	// 启动自动结束协程
	ch := make(chan struct{})
	s.closed[item.ID] = ch
	go s.autoEnd(item.ID, req.DurationMins, ch)

	return item, nil
}

// PlaceBid 出价
func (s *Service) PlaceBid(auctionID, bidderID string, amount int) (*model.AuctionItem, *model.Bid, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item, ok := s.store.GetAuction(auctionID)
	if !ok {
		return nil, nil, ErrAuctionNotFound
	}

	if !item.IsActive() {
		return nil, nil, ErrAuctionNotActive
	}

	if bidderID == item.SellerID {
		return nil, nil, ErrCannotBidOwnAuction
	}

	if amount <= item.CurrentBid {
		return nil, nil, ErrBidTooLow
	}

	bidderMoney, err := s.store.GetPlayerMoney(bidderID)
	if err != nil {
		return nil, nil, err
	}
	if bidderMoney < amount {
		return nil, nil, ErrInsufficientFunds
	}

	// 退还上一位出价者
	if item.CurrentBidder != "" && item.CurrentBidder != item.SellerID {
		s.store.AddPlayerMoney(item.CurrentBidder, item.CurrentBid)
	}

	// 扣除新出价者资金
	if err := s.store.DeductPlayerMoney(bidderID, amount); err != nil {
		return nil, nil, err
	}

	// 更新拍卖
	if !item.PlaceBid(bidderID, amount) {
		s.store.AddPlayerMoney(bidderID, amount)
		return nil, nil, ErrBidFailed
	}

	bid := &model.Bid{
		ID:        uuid.New().String(),
		AuctionID: auctionID,
		BidderID:  bidderID,
		Amount:    amount,
		Timestamp: time.Now(),
	}
	s.store.CreateBid(bid)
	s.store.UpdateAuction(item)

	return item, bid, nil
}

// GetActiveAuctions 获取所有进行中的拍卖
func (s *Service) GetActiveAuctions() []*model.AuctionItem {
	s.mu.RLock()
	defer s.mu.RUnlock()

	all := s.store.ListActiveAuctions()
	result := make([]*model.AuctionItem, 0, len(all))
	for _, a := range all {
		if a.IsActive() {
			result = append(result, a)
		} else {
			a.State = model.AuctionStateExpired
			s.store.UpdateAuction(a)
		}
	}
	return result
}

// GetAuctionDetail 获取拍卖详情
func (s *Service) GetAuctionDetail(auctionID string) (*model.AuctionItem, []*model.Bid, error) {
	item, ok := s.store.GetAuction(auctionID)
	if !ok {
		return nil, nil, ErrAuctionNotFound
	}

	bids := s.store.GetBidsByAuction(auctionID)

	if item.State == model.AuctionStateActive && !item.IsActive() {
		item.State = model.AuctionStateExpired
		s.store.UpdateAuction(item)
	}

	return item, bids, nil
}

// EndAuction 结束拍卖
func (s *Service) EndAuction(auctionID string) (*model.AuctionItem, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	item, ok := s.store.GetAuction(auctionID)
	if !ok {
		return nil, ErrAuctionNotFound
	}

	if item.State != model.AuctionStateActive {
		return item, nil
	}

	// 关闭自动结束协程
	if ch, exists := s.closed[auctionID]; exists {
		close(ch)
		delete(s.closed, auctionID)
	}

	item.EndAuction()

	// 结算
	if item.CurrentBidder != "" && item.CurrentBidder != item.SellerID {
		err := s.store.TransferItem(item.SellerID, item.CurrentBidder, item.ItemID)
		if err != nil {
			s.store.AddPlayerMoney(item.CurrentBidder, item.CurrentBid)
			s.store.AddPlayerMoney(item.SellerID, item.CurrentBid)
		}
	} else {
		// 流拍，退还起拍价
		s.store.AddPlayerMoney(item.SellerID, item.StartingBid)
	}

	s.store.UpdateAuction(item)
	return item, nil
}

// autoEnd 自动结束协程
func (s *Service) autoEnd(auctionID string, durationMins int, done chan struct{}) {
	timer := time.NewTimer(time.Duration(durationMins) * time.Minute)
	select {
	case <-timer.C:
		s.EndAuction(auctionID)
	case <-done:
		timer.Stop()
	}
}

// ListAuctionRequest 挂售请求
type ListAuctionRequest struct {
	PlayerID     string `json:"player_id"`
	ItemID       string `json:"item_id"`
	ItemName     string `json:"item_name"`
	ItemRarity   int    `json:"item_rarity"`
	StartingBid  int    `json:"starting_bid"`
	DurationMins int    `json:"duration_mins"`
	Location     string `json:"location"`
}

// BidRequest 出价请求
type BidRequest struct {
	PlayerID string `json:"player_id"`
	Amount   int    `json:"amount"`
}

// 错误定义
var (
	ErrInvalidSeller       = &AuctionError{Code: "INVALID_SELLER", Message: "无效的卖家"}
	ErrInvalidItem         = &AuctionError{Code: "INVALID_ITEM", Message: "无效的物品"}
	ErrInvalidStartingBid  = &AuctionError{Code: "INVALID_STARTING_BID", Message: "起拍价必须大于0"}
	ErrAuctionNotFound     = &AuctionError{Code: "AUCTION_NOT_FOUND", Message: "拍卖不存在"}
	ErrAuctionNotActive    = &AuctionError{Code: "AUCTION_NOT_ACTIVE", Message: "拍卖不在进行中"}
	ErrCannotBidOwnAuction = &AuctionError{Code: "CANNOT_BID_OWN", Message: "不能竞拍自己的物品"}
	ErrBidTooLow           = &AuctionError{Code: "BID_TOO_LOW", Message: "出价低于当前最高价"}
	ErrInsufficientFunds   = &AuctionError{Code: "INSUFFICIENT_FUNDS", Message: "资金不足"}
	ErrBidFailed           = &AuctionError{Code: "BID_FAILED", Message: "出价失败"}
)

// AuctionError 拍卖错误
type AuctionError struct {
	Code    string
	Message string
}

func (e *AuctionError) Error() string {
	return e.Message
}
