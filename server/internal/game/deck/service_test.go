package deck

import (
	"testing"

	"github.com/csonxx/ChronoCards/server/internal/model"
)

// TestService_NewService 测试Service创建
func TestService_NewService(t *testing.T) {
	svc := NewService()
	if svc == nil {
		t.Fatal("Expected non-nil service")
	}
}

// TestService_Trigger_Teahouse 测试茶馆说书人发牌员
func TestService_Trigger_Teahouse(t *testing.T) {
	svc := NewService()
	
	dealer := &model.Dealer{
		ID:    "teahouse-1",
		Type:  model.DealerTeahouse,
		Name:  "茶馆说书人",
		Weight: 1,
	}
	
	deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
	
	resp := svc.Trigger(dealer, deck)
	
	if resp == nil {
		t.Fatal("Expected non-nil response")
	}
	if resp.DealerID != "teahouse-1" {
		t.Errorf("Expected DealerID 'teahouse-1', got '%s'", resp.DealerID)
	}
	if resp.DrawnCard == nil {
		t.Error("Expected DrawnCard to be non-nil")
	}
	if resp.DeckExhausted {
		t.Error("Expected DeckExhausted to be false for fresh deck")
	}
	
	// 验证hint包含说书人风格
	if len(resp.Hint) == 0 {
		t.Error("Expected non-empty hint")
	}
}

// TestService_Trigger_BountyBoard 测试悬赏公告栏发牌员
func TestService_Trigger_BountyBoard(t *testing.T) {
	svc := NewService()
	
	dealer := &model.Dealer{
		ID:    "bounty-1",
		Type:  model.DealerBountyBoard,
		Name:  "江湖悬赏令",
		Weight: 1,
	}
	
	deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
	
	resp := svc.Trigger(dealer, deck)
	
	if resp == nil {
		t.Fatal("Expected non-nil response")
	}
	if resp.DrawnCard == nil {
		t.Error("Expected DrawnCard to be non-nil")
	}
	
	// 验证hint包含悬赏风格
	if resp.Hint == "" {
		t.Error("Expected non-empty hint")
	}
}

// TestService_Trigger_DeckExhausted 测试卡组耗尽
func TestService_Trigger_DeckExhausted(t *testing.T) {
	svc := NewService()
	
	dealer := &model.Dealer{
		ID:    "teahouse-1",
		Type:  model.DealerTeahouse,
		Name:  "茶馆说书人",
		Weight: 1,
	}
	
	// 创建只剩1张牌的卡组
	cards := []*model.Card{
		{ID: "card-1", Type: model.CardMainStory, Title: "测试卡牌"},
	}
	deck := model.NewDeck("player-001", "测试卡组", cards)
	
	// 先抽一张
	deck.Draw(1)
	
	// 再抽应该耗尽
	resp := svc.Trigger(dealer, deck)
	
	if resp == nil {
		t.Fatal("Expected non-nil response")
	}
	if !resp.DeckExhausted {
		t.Error("Expected DeckExhausted to be true after exhausting deck")
	}
	if resp.Hint != "卡组已空，请洗牌" {
		t.Errorf("Expected hint '卡组已空，请洗牌', got '%s'", resp.Hint)
	}
}

// TestService_TriggerWithWeight_HighWeight 测试高权重发牌员
func TestService_TriggerWithWeight_HighWeight(t *testing.T) {
	svc := NewService()
	
	// 权重为3的发牌员
	dealer := &model.Dealer{
		ID:    "temple-1",
		Type:  model.DealerTeahouse, // 实际用teahouse因为model.DealerTemple可能不存在
		Name:  "寺庙高人",
		Weight: 3,
	}
	
	// 创建有足够卡牌的卡组
	deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
	
	resp := svc.TriggerWithWeight(dealer, deck)
	
	if resp == nil {
		t.Fatal("Expected non-nil response")
	}
	if resp.DrawnCard == nil {
		t.Error("Expected DrawnCard to be non-nil")
	}
}

// TestService_TriggerWithWeight_WeightCapped 测试权重上限
func TestService_TriggerWithWeight_WeightCapped(t *testing.T) {
	svc := NewService()
	
	// 权重超过3的发牌员（应该被限制为3）
	dealer := &model.Dealer{
		ID:    "high-weight-1",
		Type:  model.DealerTeahouse,
		Name:  "测试发牌员",
		Weight: 10, // 超过上限
	}
	
	deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
	
	resp := svc.TriggerWithWeight(dealer, deck)
	
	if resp == nil {
		t.Fatal("Expected non-nil response")
	}
	// 应该成功抽牌，没有panic或错误
	if resp.DrawnCard == nil && !resp.DeckExhausted {
		t.Error("Expected either DrawnCard or DeckExhausted")
	}
}

// TestService_TriggerWithWeight_ZeroWeight 测试零权重发牌员
func TestService_TriggerWithWeight_ZeroWeight(t *testing.T) {
	svc := NewService()
	
	dealer := &model.Dealer{
		ID:    "zero-weight-1",
		Type:  model.DealerTeahouse,
		Name:  "测试发牌员",
		Weight: 0, // 零权重
	}
	
	deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
	
	resp := svc.TriggerWithWeight(dealer, deck)
	
	if resp == nil {
		t.Fatal("Expected non-nil response")
	}
	// 零权重应该被视为1
	if resp.DrawnCard == nil && !resp.DeckExhausted {
		t.Error("Expected either DrawnCard or DeckExhausted")
	}
}

// TestService_AdjustDeckForPlayerState 测试玩家状态调整卡组
func TestService_AdjustDeckForPlayerState(t *testing.T) {
	svc := NewService()
	
	deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
	
	// 测试 low_hp 状态调整
	svc.AdjustDeckForPlayerState(deck, "low_hp")
	
	// deck应该被调整，但不影响功能（只改变抽牌顺序）
	if len(deck.Cards) != 15 {
		t.Errorf("Expected 15 cards, got %d", len(deck.Cards))
	}
}

// TestService_AdjustDeckByDealer 测试发牌员类型调整卡组
func TestService_AdjustDeckByDealer(t *testing.T) {
	svc := NewService()
	
	dealers := []model.DealerType{
		model.DealerTeahouse,
		model.DealerBountyBoard,
		model.DealerEnemy,
		model.DealerInn,
		model.DealerMerchant,
		model.DealerDynamicEncounter,
		model.DealerEnvironment,
	}
	
	for _, dealerType := range dealers {
		deck := model.NewDeck("player-001", "测试卡组", model.StandardDeck())
		dealer := &model.Dealer{
			ID:   "test-" + string(dealerType),
			Type: dealerType,
			Name: "测试发牌员",
		}
		
		// 不应该panic
		svc.AdjustDeckByDealer(deck, dealer)
		
		if len(deck.Cards) != 15 {
			t.Errorf("Dealer %s: Expected 15 cards, got %d", dealerType, len(deck.Cards))
		}
	}
}

// TestService_GetHintForDealer 测试发牌员提示生成
func TestService_GetHintForDealer(t *testing.T) {
	svc := NewService()
	
	card := &model.Card{
		ID:    "card-1",
		Type:  model.CardMainStory,
		Title: "测试卡牌",
	}
	
	dealers := []model.DealerType{
		model.DealerTeahouse,
		model.DealerBountyBoard,
		model.DealerEnemy,
		model.DealerInn,
		model.DealerMerchant,
		model.DealerDynamicEncounter,
		model.DealerEnvironment,
	}
	
	for _, dealerType := range dealers {
		dealer := &model.Dealer{
			ID:   "test-" + string(dealerType),
			Type: dealerType,
			Name: "测试发牌员",
		}
		
		hint := svc.GetHintForDealer(dealer, card)
		
		if hint == "" {
			t.Errorf("Dealer %s: Expected non-empty hint", dealerType)
		}
	}
}
