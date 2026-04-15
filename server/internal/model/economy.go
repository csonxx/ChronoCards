package model

import (
	"time"

	"github.com/google/uuid"
)

// AuctionStatus 拍卖状态
type AuctionStatus string

const (
	AuctionActive    AuctionStatus = "active"
	AuctionSold      AuctionStatus = "sold"
	AuctionExpired   AuctionStatus = "expired"
	AuctionCancelled AuctionStatus = "cancelled"
)

// AuctionListing 拍卖上架
type AuctionListing struct {
	ID         string        `json:"id"`
	SellerID   string        `json:"seller_id"`
	SellerName string        `json:"seller_name"`
	ItemID     string        `json:"item_id"`
	ItemName   string        `json:"item_name"`
	ItemRarity int           `json:"item_rarity"`
	ItemIcon   string        `json:"item_icon"`
	StartPrice int           `json:"start_price"`
	BuyoutPrice int          `json:"buyout_price"`
	CurrentBid int           `json:"current_bid"`
	BidderID   string        `json:"bidder_id,omitempty"`
	BidderName string        `json:"bidder_name,omitempty"`
	Status     AuctionStatus `json:"status"`
	EndTime    time.Time     `json:"end_time"`
	CreatedAt  time.Time     `json:"created_at"`
	UpdatedAt  time.Time     `json:"updated_at"`
}

// Bid 竞价记录
type Bid struct {
	ID         string    `json:"id"`
	AuctionID  string    `json:"auction_id"`
	BidderID   string    `json:"bidder_id"`
	BidderName string    `json:"bidder_name"`
	Amount     int       `json:"amount"`
	CreatedAt  time.Time `json:"created_at"`
}

// NewAuctionListing 创建拍卖上架
func NewAuctionListing(sellerID, sellerName string, itemID, itemName, itemIcon string, itemRarity int, startPrice, buyoutPrice int, durationHours int) *AuctionListing {
	now := time.Now()
	return &AuctionListing{
		ID:          uuid.New().String(),
		SellerID:    sellerID,
		SellerName:  sellerName,
		ItemID:      itemID,
		ItemName:    itemName,
		ItemRarity:  itemRarity,
		ItemIcon:    itemIcon,
		StartPrice:  startPrice,
		BuyoutPrice: buyoutPrice,
		CurrentBid:  0,
		Status:      AuctionActive,
		EndTime:     now.Add(time.Duration(durationHours) * time.Hour),
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

// PlaceBid 竞价
func (a *AuctionListing) PlaceBid(bidderID, bidderName string, amount int) bool {
	if a.Status != AuctionActive {
		return false
	}
	if time.Now().After(a.EndTime) {
		a.Status = AuctionExpired
		return false
	}
	if amount <= a.CurrentBid {
		return false
	}
	a.CurrentBid = amount
	a.BidderID = bidderID
	a.BidderName = bidderName
	a.UpdatedAt = time.Now()
	return true
}

// Buyout 一口价购买
func (a *AuctionListing) Buyout(buyerID, buyerName string) bool {
	if a.Status != AuctionActive || a.BuyoutPrice <= 0 {
		return false
	}
	a.CurrentBid = a.BuyoutPrice
	a.BidderID = buyerID
	a.BidderName = buyerName
	a.Status = AuctionSold
	a.UpdatedAt = time.Now()
	return true
}

// IsExpired 检查是否超时
func (a *AuctionListing) IsExpired() bool {
	return a.Status == AuctionActive && time.Now().After(a.EndTime)
}

// BlackMarketListing 黑市上架
type BlackMarketListing struct {
	ID           string    `json:"id"`
	ItemID       string    `json:"item_id"`
	ItemName     string    `json:"item_name"`
	ItemRarity   int       `json:"item_rarity"`
	ItemIcon     string    `json:"item_icon"`
	BasePrice    int       `json:"base_price"`
	CurrentPrice int       `json:"current_price"`
	Stock        int       `json:"stock"`
	MaxStock     int       `json:"max_stock"`
	TotalSold    int       `json:"total_sold"`
	RefreshedAt  time.Time `json:"refreshed_at"`
	CreatedAt    time.Time `json:"created_at"`
}

// PriceMultiplier 价格波动系数
func (b *BlackMarketListing) PriceMultiplier() float64 {
	if b.TotalSold == 0 {
		return 1.0
	}
	return 1.0 + float64(b.TotalSold)*0.05
}

// UpdatePrice 更新价格
func (b *BlackMarketListing) UpdatePrice() {
	b.CurrentPrice = int(float64(b.BasePrice) * b.PriceMultiplier())
}

// PlayerWallet 玩家钱包
type PlayerWallet struct {
	PlayerID    string    `json:"player_id"`
	Gold        int       `json:"gold"`
	Silver      int       `json:"silver"`
	TotalEarned int       `json:"total_earned"`
	TotalSpent  int       `json:"total_spent"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// TransactionType 交易类型
type TransactionType string

const (
	TransactionAuctionSell    TransactionType = "auction_sell"
	TransactionAuctionBuy     TransactionType = "auction_buy"
	TransactionAuctionBid     TransactionType = "auction_bid"
	TransactionBlackMarketBuy TransactionType = "blackmarket_buy"
	TransactionShopBuy        TransactionType = "shop_buy"
	TransactionShopSell       TransactionType = "shop_sell"
	TransactionReward         TransactionType = "reward"
	TransactionRefund         TransactionType = "refund"
)

// WalletTransaction 钱包交易记录
type WalletTransaction struct {
	ID        string          `json:"id"`
	PlayerID  string          `json:"player_id"`
	Type      TransactionType `json:"type"`
	Amount    int             `json:"amount"`
	Balance   int             `json:"balance"`
	Currency  string          `json:"currency"`
	Note      string          `json:"note,omitempty"`
	CreatedAt time.Time       `json:"created_at"`
}

// NewPlayerWallet 创建新钱包
func NewPlayerWallet(playerID string) *PlayerWallet {
	return &PlayerWallet{
		PlayerID: playerID,
		Gold:     1000,
		Silver:   100,
		UpdatedAt: time.Now(),
	}
}

// CanSpend 检查能否消费
func (w *PlayerWallet) CanSpend(currency string, amount int) bool {
	switch currency {
	case "gold":
		return w.Gold >= amount
	case "silver":
		return w.Silver >= amount
	}
	return false
}

// Spend 消费
func (w *PlayerWallet) Spend(currency string, amount int) bool {
	if !w.CanSpend(currency, amount) {
		return false
	}
	switch currency {
	case "gold":
		w.Gold -= amount
		w.TotalSpent += amount
	case "silver":
		w.Silver -= amount
		w.TotalSpent += amount
	}
	w.UpdatedAt = time.Now()
	return true
}

// Earn 收入
func (w *PlayerWallet) Earn(currency string, amount int) {
	switch currency {
	case "gold":
		w.Gold += amount
		w.TotalEarned += amount
	case "silver":
		w.Silver += amount
		w.TotalEarned += amount
	}
	w.UpdatedAt = time.Now()
}
