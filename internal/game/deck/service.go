package deck

import (
	"github.com/csonxx/ChronoCards/internal/model"
)

// Service 发牌员逻辑服务
type Service struct{}

// NewService 创建服务
func NewService() *Service {
	return &Service{}
}

// DealerTriggerResponse 发牌员触发结果
type DealerTriggerResponse struct {
	DealerID     string       `json:"dealer_id"`
	DealerName   string       `json:"dealer_name"`
	DrawnCard    *model.Card  `json:"drawn_card"`
	DeckExhausted bool        `json:"deck_exhausted"`
	Hint         string       `json:"hint,omitempty"` // 下一张卡牌类型提示
}

// Trigger 发牌员触发抽牌
// 不同发牌员有不同的卡牌触发权重
func (s *Service) Trigger(dealer *model.Dealer, deck *model.Deck) *DealerTriggerResponse {
	resp := &DealerTriggerResponse{
		DealerID:    dealer.ID,
		DealerName:  dealer.Name,
		DeckExhausted: false,
	}

	// 抽1张牌
	cards, exhausted := deck.Draw(1)
	if exhausted || len(cards) == 0 {
		resp.DeckExhausted = true
		resp.Hint = "卡组已空，请洗牌"
		return resp
	}

	resp.DrawnCard = cards[0]
	resp.DeckExhausted = exhausted

	// 根据发牌员类型给出提示
	resp.Hint = s.getHintForDealer(dealer, cards[0])

	return resp
}

// TriggerWithWeight 带权重抽牌
func (s *Service) TriggerWithWeight(dealer *model.Dealer, deck *model.Deck) *DealerTriggerResponse {
	// 对于高权重发牌员，可以一次抽多张
	multiplier := dealer.Weight
	if multiplier < 1 {
		multiplier = 1
	}
	if multiplier > 3 {
		multiplier = 3
	}

	resp := &DealerTriggerResponse{
		DealerID:    dealer.ID,
		DealerName:  dealer.Name,
		DeckExhausted: false,
	}

	count := multiplier
	cards, exhausted := deck.Draw(count)
	if exhausted || len(cards) == 0 {
		resp.DeckExhausted = true
		return resp
	}

	resp.DrawnCard = cards[0]
	resp.DeckExhausted = exhausted
	resp.Hint = s.getHintForDealer(dealer, cards[0])
	return resp
}

// getHintForDealer 根据发牌员类型生成提示
func (s *Service) getHintForDealer(dealer *model.Dealer, card *model.Card) string {
	switch dealer.Type {
	case model.DealerTeahouse:
		return "说书人压低声音：'" + card.Title + "'——客官，这事儿可不简单..."
	case model.DealerBountyBoard:
		return "悬赏板上赫然写着：'" + card.Title + "'，酬金从优"
	case model.DealerEnemy:
		return "敌人哆嗦道：'" + card.Title + "'，我说！我全说！"
	case model.DealerInn:
		return "客栈掌柜道：'" + card.Title + "'，客官可有兴趣？"
	case model.DealerMerchant:
		return "商贩眼中闪过精光：'" + card.Title + "'，这个嘛..."
	case model.DealerDynamicEncounter:
		return "前方传来消息：'" + card.Title + "'"
	case model.DealerEnvironment:
		return "环境似乎在暗示：'" + card.Title + "'"
	default:
		return card.Title
	}
}

// AdjustDeckForPlayerState 根据玩家状态动态调整卡组
// low_hp: 将 stat_up 卡提前
// low_mp: 将 stat_up 或 内力提升卡提前
// underleveled: 将经验/等级相关卡提前
// player_death: 将装备/技能卡提前
func (s *Service) AdjustDeckForPlayerState(deck *model.Deck, reason string) {
	switch reason {
	case "low_hp":
		// 将 stat_up 类型的生命提升卡提前
		deck.AdjustDeck(model.CardStatUp)
	case "low_mp":
		// 将 stat_up 提前
		deck.AdjustDeck(model.CardStatUp)
	case "underleveled":
		// 将经验/技能卡提前
		deck.AdjustDeck(model.CardStatUp)
	case "player_death":
		// 将技能解锁卡提前
		deck.AdjustDeck(model.CardSkillUnlock)
	default:
		// 默认不做调整
	}
}
