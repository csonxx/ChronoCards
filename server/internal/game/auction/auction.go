package auction

// AuctionListResponse 拍卖列表响应
type AuctionListResponse struct {
	Auctions []*AuctionItemResponse `json:"auctions"`
	Total    int                    `json:"total"`
}

// AuctionDetailResponse 拍卖详情响应
type AuctionDetailResponse struct {
	Auction *AuctionItemResponse `json:"auction"`
	Bids    []*BidResponse       `json:"bids"`
}

// AuctionItemResponse 拍卖物品响应（兼容前端）
type AuctionItemResponse struct {
	ID            string `json:"id"`
	SellerID      string `json:"seller_id"`
	ItemID        string `json:"item_id"`
	ItemName      string `json:"item_name"`
	ItemRarity    int    `json:"item_rarity"`
	StartingBid   int    `json:"starting_bid"`
	CurrentBid    int    `json:"current_bid"`
	CurrentBidder string `json:"current_bidder"`
	BidCount      int    `json:"bid_count"`
	State         string `json:"state"`
	Location      string `json:"location"`
	EndTime       string `json:"end_time"`
}

// BidResponse 出价记录响应
type BidResponse struct {
	ID         string `json:"id"`
	BidderID   string `json:"bidder_id"`
	Amount     int    `json:"amount"`
	Timestamp  string `json:"timestamp"`
}
