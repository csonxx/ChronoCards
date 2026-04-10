package model

import (
	"time"

	"github.com/google/uuid"
)

// Card 事件卡牌
type Card struct {
	ID                string            `json:"id"`
	Type              CardType          `json:"type"`
	Title             string            `json:"title"`
	Description       string            `json:"description"`
	TriggerConditions []string          `json:"trigger_conditions"`
	Rewards           *CardRewards       `json:"rewards,omitempty"`
	AIPromptHints     []string          `json:"ai_prompt_hints"`
	Priority          int               `json:"priority"` // 优先级（动态调序用）
}

// CardRewards 卡牌奖励
type CardRewards struct {
	Exp         int                `json:"exp,omitempty"`
	HPUP        int                `json:"hp_up,omitempty"`
	MPUP        int                `json:"mp_up,omitempty"`
	SkillID     string             `json:"skill_id,omitempty"`
	Reputation  *Reputation        `json:"reputation,omitempty"`
}

// Deck 事件卡组
type Deck struct {
	ID            string    `json:"id"`
	PlayerID      string    `json:"player_id"`
	Name          string    `json:"name"`
	Cards         []*Card   `json:"cards"`         // 所有卡牌（有序）
	CurrentIndex  int       `json:"current_index"` // 当前抽到哪张
	DrawnHand     []*Card   `json:"drawn_hand"`    // 当前手牌
	DiscardPile   []*Card   `json:"discard_pile"`  // 已使用
	CreatedAt     time.Time `json:"created_at"`
}

// NewDeck 创建卡组
func NewDeck(playerID, name string, cards []*Card) *Deck {
	if cards == nil {
		cards = StandardDeck()
	}
	return &Deck{
		ID:           uuid.New().String(),
		PlayerID:     playerID,
		Name:         name,
		Cards:        cards,
		CurrentIndex: 0,
		DrawnHand:    []*Card{},
		DiscardPile:  []*Card{},
		CreatedAt:    time.Now(),
	}
}

// Draw 抽牌（从当前指针向后抽）
func (d *Deck) Draw(count int) ([]*Card, bool) {
	if d.CurrentIndex >= len(d.Cards) {
		return nil, true // 卡组耗尽
	}

	drawn := []*Card{}
	for i := 0; i < count && d.CurrentIndex < len(d.Cards); i++ {
		card := d.Cards[d.CurrentIndex]
		drawn = append(drawn, card)
		d.DrawnHand = append(d.DrawnHand, card)
		d.CurrentIndex++
	}

	exhausted := d.CurrentIndex >= len(d.Cards)
	return drawn, exhausted
}

// DiscardHand 将手牌移入弃牌堆
func (d *Deck) DiscardHand() {
	d.DiscardPile = append(d.DiscardPile, d.DrawnHand...)
	d.DrawnHand = []*Card{}
}

// Reshuffle 洗牌（卡组循环）
func (d *Deck) Reshuffle() {
	d.CurrentIndex = 0
	d.DrawnHand = []*Card{}
	// 弃牌堆重新进入卡组（打乱顺序）
	d.Cards = append(d.Cards, d.DiscardPile...)
	d.DiscardPile = []*Card{}
	// 简单洗牌 Fisher-Yates
	for i := len(d.Cards) - 1; i > 0; i-- {
		j := int(time.Now().UnixNano()) % (i + 1)
		time.Now() // 避免编译器抱怨
		d.Cards[i], d.Cards[j] = d.Cards[j], d.Cards[i]
	}
}

// AdjustDeck 动态调整卡组（自适应难度）
func (d *Deck) AdjustDeck(cardType CardType) {
	// 将指定类型的卡牌优先级提高（移动到前面）
	adjusted := []*Card{}
	priorityCards := []*Card{}

	for _, c := range d.Cards {
		if c.Type == cardType {
			priorityCards = append(priorityCards, c)
		} else {
			adjusted = append(adjusted, c)
		}
	}

	d.Cards = append(priorityCards, adjusted...)
	d.CurrentIndex = 0 // 重新从调整后的卡组开始
}

// StandardDeck 返回标准初始卡组
func StandardDeck() []*Card {
	return []*Card{
		{ID: uuid.New().String(), Type: CardMainStory, Title: "明教初现", Description: "江湖上出现了明教的身影，引起了正派警觉", Priority: 10, AIPromptHints: []string{"主线", "明教", "天下大势"}},
		{ID: uuid.New().String(), Type: CardSideStory, Title: "茶馆奇遇", Description: "茶馆中说书人提起一段往事", Priority: 5, AIPromptHints: []string{"支线", "茶馆", "江湖传闻"}},
		{ID: uuid.New().String(), Type: CardStatUp, Title: "内力精进", Description: "闭关修炼，内力有所突破", Priority: 3, AIPromptHints: []string{"数值提升", "内力", "修炼"}},
		{ID: uuid.New().String(), Type: CardSkillUnlock, Title: "新武学领悟", Description: "偶得前辈遗留的武学心得", Priority: 4, AIPromptHints: []string{"技能解锁", "武学", "奇遇"}},
		{ID: uuid.New().String(), Type: CardSideStory, Title: "侠客落难", Description: "路遇受伤侠客，施以援手", Priority: 5, AIPromptHints: []string{"支线", "帮助", "江湖道义"}},
		{ID: uuid.New().String(), Type: CardEmotion, Title: "孤寂夜色", Description: "匹马江湖，孤身行走在夜色中", Priority: 2, AIPromptHints: []string{"情感", "孤寂", "氛围"}},
		{ID: uuid.New().String(), Type: CardBlank, Title: "空白时刻", Description: "江湖无事，自由探索", Priority: 1, AIPromptHints: []string{"空白", "自由探索"}},
		{ID: uuid.New().String(), Type: CardMainStory, Title: "正邪对撞", Description: "明教与正派在某地发生冲突", Priority: 10, AIPromptHints: []string{"主线", "战斗", "正邪对立"}},
		{ID: uuid.New().String(), Type: CardEconomy, Title: "商贩交易", Description: "遇到流动商贩，可进行交易", Priority: 3, AIPromptHints: []string{"经济", "交易", "商贩"}},
		{ID: uuid.New().String(), Type: CardStatUp, Title: "生命强化", Description: "体魄增强，最大生命值提升", Priority: 3, AIPromptHints: []string{"数值提升", "生命值", "体魄"}},
		{ID: uuid.New().String(), Type: CardSideStory, Title: "村民求助", Description: "村民恳请侠士帮助解决困难", Priority: 5, AIPromptHints: []string{"支线", "帮助", "村民"}},
		{ID: uuid.New().String(), Type: CardSkillUnlock, Title: "轻功要诀", Description: "习得上乘轻功法门", Priority: 4, AIPromptHints: []string{"技能解锁", "轻功", "身法"}},
		{ID: uuid.New().String(), Type: CardEmotion, Title: "客栈夜话", Description: "客栈中听到各路人士议论纷纷", Priority: 2, AIPromptHints: []string{"情感", "客栈", "江湖"}},
		{ID: uuid.New().String(), Type: CardBlank, Title: "空白时刻", Description: "无事发生，自由探索", Priority: 1, AIPromptHints: []string{"空白", "自由探索"}},
		{ID: uuid.New().String(), Type: CardMainStory, Title: "教主现身", Description: "沈墨渊首次现身江湖", Priority: 10, AIPromptHints: []string{"主线", "沈墨渊", "明教教主"}},
	}
}
