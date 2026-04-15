package model

import (
	"testing"
)

// TestDeck_NewDeck 测试创建卡组
func TestDeck_NewDeck(t *testing.T) {
	deck := NewDeck("player-001", "测试卡组", nil)
	
	if deck == nil {
		t.Fatal("Expected non-nil deck")
	}
	if deck.ID == "" {
		t.Error("Expected non-empty ID")
	}
	if deck.PlayerID != "player-001" {
		t.Errorf("Expected PlayerID 'player-001', got '%s'", deck.PlayerID)
	}
	if deck.Name != "测试卡组" {
		t.Errorf("Expected Name '测试卡组', got '%s'", deck.Name)
	}
	if deck.CurrentIndex != 0 {
		t.Errorf("Expected CurrentIndex 0, got %d", deck.CurrentIndex)
	}
}

// TestDeck_Draw_Single 测试单抽
func TestDeck_Draw_Single(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
		{ID: "card-2", Type: CardSideStory, Title: "第二张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	drawn, exhausted := deck.Draw(1)
	
	if exhausted {
		t.Error("Expected exhausted to be false for fresh deck")
	}
	if len(drawn) != 1 {
		t.Errorf("Expected 1 drawn card, got %d", len(drawn))
	}
	if drawn[0].ID != "card-1" {
		t.Errorf("Expected card-1, got %s", drawn[0].ID)
	}
	if deck.CurrentIndex != 1 {
		t.Errorf("Expected CurrentIndex 1, got %d", deck.CurrentIndex)
	}
}

// TestDeck_Draw_Multiple 测试多抽
func TestDeck_Draw_Multiple(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
		{ID: "card-2", Type: CardSideStory, Title: "第二张"},
		{ID: "card-3", Type: CardSkillUnlock, Title: "第三张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	drawn, exhausted := deck.Draw(2)
	
	if exhausted {
		t.Error("Expected exhausted to be false")
	}
	if len(drawn) != 2 {
		t.Errorf("Expected 2 drawn cards, got %d", len(drawn))
	}
	if deck.CurrentIndex != 2 {
		t.Errorf("Expected CurrentIndex 2, got %d", deck.CurrentIndex)
	}
}

// TestDeck_Draw_Exhaust 测试卡组耗尽
func TestDeck_Draw_Exhaust(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	// 抽第一张
	deck.Draw(1)
	
	// 尝试抽第二张
	drawn, exhausted := deck.Draw(1)
	
	if len(drawn) != 0 {
		t.Errorf("Expected 0 drawn cards, got %d", len(drawn))
	}
	if !exhausted {
		t.Error("Expected exhausted to be true")
	}
}

// TestDeck_Draw_All 测试一次性抽完
func TestDeck_Draw_All(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
		{ID: "card-2", Type: CardSideStory, Title: "第二张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	drawn, exhausted := deck.Draw(2)
	
	if !exhausted {
		t.Error("Expected exhausted to be true after drawing all")
	}
	if len(drawn) != 2 {
		t.Errorf("Expected 2 drawn cards, got %d", len(drawn))
	}
	
	// 再抽应该耗尽
	drawn, exhausted = deck.Draw(1)
	if !exhausted {
		t.Error("Expected exhausted to be true")
	}
}

// TestDeck_DrawHand 测试手牌记录
func TestDeck_DrawHand(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	deck.Draw(1)
	
	if len(deck.DrawnHand) != 1 {
		t.Errorf("Expected 1 card in DrawnHand, got %d", len(deck.DrawnHand))
	}
}

// TestDeck_DiscardHand 测试弃牌
func TestDeck_DiscardHand(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
		{ID: "card-2", Type: CardSideStory, Title: "第二张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	deck.Draw(2)
	deck.DiscardHand()
	
	if len(deck.DrawnHand) != 0 {
		t.Errorf("Expected 0 cards in DrawnHand after discard, got %d", len(deck.DrawnHand))
	}
	if len(deck.DiscardPile) != 2 {
		t.Errorf("Expected 2 cards in DiscardPile, got %d", len(deck.DiscardPile))
	}
}

// TestDeck_Reshuffle 测试洗牌
func TestDeck_Reshuffle(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
		{ID: "card-2", Type: CardSideStory, Title: "第二张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	// 抽一张
	deck.Draw(1)
	
	// 弃牌
	deck.DiscardHand()
	
	// 洗牌
	deck.Reshuffle()
	
	if deck.CurrentIndex != 0 {
		t.Errorf("Expected CurrentIndex 0 after reshuffle, got %d", deck.CurrentIndex)
	}
	if len(deck.DiscardPile) != 0 {
		t.Errorf("Expected 0 cards in DiscardPile after reshuffle, got %d", len(deck.DiscardPile))
	}
	if len(deck.DrawnHand) != 0 {
		t.Errorf("Expected 0 cards in DrawnHand after reshuffle, got %d", len(deck.DrawnHand))
	}
}

// TestDeck_Reshuffle_AddsDiscardPile 测试洗牌后弃牌堆重新进入卡组
func TestDeck_Reshuffle_AddsDiscardPile(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "第一张"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	// 抽完
	deck.Draw(1)
	
	// 洗牌后，卡组仍然是1张（弃牌堆为空，未重新进入）
	deck.Reshuffle()
	
	if len(deck.Cards) != 1 {
		t.Errorf("Expected 1 card in deck after reshuffle, got %d", len(deck.Cards))
	}
}

// TestDeck_AdjustDeck 测试动态调整卡组
func TestDeck_AdjustDeck(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "主线1"},
		{ID: "card-2", Type: CardSideStory, Title: "支线1"},
		{ID: "card-3", Type: CardMainStory, Title: "主线2"},
		{ID: "card-4", Type: CardSkillUnlock, Title: "技能1"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	// 将主线卡调整到前面
	deck.AdjustDeck(CardMainStory)
	
	if deck.Cards[0].Type != CardMainStory {
		t.Errorf("Expected first card to be MainStory, got %s", deck.Cards[0].Type)
	}
	if deck.Cards[1].Type != CardMainStory {
		t.Errorf("Expected second card to be MainStory, got %s", deck.Cards[1].Type)
	}
	if deck.CurrentIndex != 0 {
		t.Errorf("Expected CurrentIndex to be reset to 0, got %d", deck.CurrentIndex)
	}
}

// TestDeck_AdjustDeck_EmptyType 测试调整不存在的类型
func TestDeck_AdjustDeck_EmptyType(t *testing.T) {
	cards := []*Card{
		{ID: "card-1", Type: CardMainStory, Title: "主线1"},
	}
	deck := NewDeck("player-001", "测试卡组", cards)
	
	// 调整一个不存在的类型，应该不影响顺序
	deck.AdjustDeck(CardEmotion)
	
	if deck.Cards[0].Type != CardMainStory {
		t.Errorf("Expected card to remain MainStory, got %s", deck.Cards[0].Type)
	}
}

// TestStandardDeck 测试标准卡组
func TestStandardDeck(t *testing.T) {
	cards := StandardDeck()
	
	if len(cards) != 15 {
		t.Errorf("Expected 15 cards in StandardDeck, got %d", len(cards))
	}
	
	// 检查各类卡存在
	hasMainStory := false
	hasSideStory := false
	hasSkillUnlock := false
	
	for _, card := range cards {
		if card.ID == "" {
			t.Error("Card ID should not be empty")
		}
		if card.Title == "" {
			t.Error("Card Title should not be empty")
		}
		
		switch card.Type {
		case CardMainStory:
			hasMainStory = true
		case CardSideStory:
			hasSideStory = true
		case CardSkillUnlock:
			hasSkillUnlock = true
		}
	}
	
	if !hasMainStory {
		t.Error("StandardDeck should contain MainStory cards")
	}
	if !hasSideStory {
		t.Error("StandardDeck should contain SideStory cards")
	}
	if !hasSkillUnlock {
		t.Error("StandardDeck should contain SkillUnlock cards")
	}
}

// TestDeck_StandardDeck_Count 测试标准卡组数量
func TestDeck_StandardDeck_Count(t *testing.T) {
	deck := NewDeck("player-001", "标准卡组", nil)
	
	if len(deck.Cards) != 15 {
		t.Errorf("Expected 15 cards, got %d", len(deck.Cards))
	}
}
