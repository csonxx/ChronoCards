package model

import (
	"time"

	"github.com/google/uuid"
)

// AuctionState 拍卖状态
type AuctionState string

const (
	AuctionStateActive   AuctionState = "active"
	AuctionStateEnded    AuctionState = "ended"
	AuctionStateExpired  AuctionState = "expired"
	AuctionStateCanceled AuctionState = "canceled"
)

// AuctionItem 拍卖物品
type AuctionItem struct {
	ID            string       `json:"id"`
	SellerID      string       `json:"seller_id"`
	ItemID        string       `json:"item_id"`
	ItemName      string       `json:"item_name"`
	ItemRarity    int          `json:"item_rarity"`
	StartingBid   int          `json:"starting_bid"`
	CurrentBid    int          `json:"current_bid"`
	CurrentBidder string       `json:"current_bidder"`
	BidCount      int          `json:"bid_count"`
	StartTime     time.Time    `json:"start_time"`
	EndTime       time.Time    `json:"end_time"`
	State         AuctionState `json:"state"`
	Location      string       `json:"location"`
	CreatedAt     time.Time    `json:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at"`
}

// Bid 出价记录
type AuctionBid struct {
	ID        string    `json:"id"`
	AuctionID string    `json:"auction_id"`
	BidderID  string    `json:"bidder_id"`
	Amount    int       `json:"amount"`
	Timestamp time.Time `json:"timestamp"`
}

// NewAuctionItem 创建拍卖物品
func NewAuctionItem(sellerID, itemID, itemName string, itemRarity, startingBid, durationMinutes int, location string) *AuctionItem {
	now := time.Now()
	return &AuctionItem{
		ID:          uuid.New().String(),
		SellerID:    sellerID,
		ItemID:      itemID,
		ItemName:    itemName,
		ItemRarity:  itemRarity,
		StartTime:   now,
		EndTime:     now.Add(time.Duration(durationMinutes) * time.Minute),
		CurrentBid:  startingBid,
		StartingBid: startingBid,
		State:       AuctionStateActive,
		Location:    location,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

// IsActive 检查拍卖是否在进行中
func (a *AuctionItem) IsActive() bool {
	return a.State == AuctionStateActive && time.Now().Before(a.EndTime)
}

// CanBid 检查玩家是否可以出价
func (a *AuctionItem) CanBid(bidderID string) bool {
	return a.IsActive() && bidderID != a.SellerID
}

// PlaceBid 尝试出价
func (a *AuctionItem) PlaceBid(bidderID string, amount int) bool {
	if !a.CanBid(bidderID) {
		return false
	}
	if amount <= a.CurrentBid {
		return false
	}
	a.CurrentBid = amount
	a.CurrentBidder = bidderID
	a.BidCount++
	a.UpdatedAt = time.Now()
	return true
}

// EndAuction 结束拍卖
func (a *AuctionItem) EndAuction() {
	a.State = AuctionStateEnded
	a.UpdatedAt = time.Now()
}
