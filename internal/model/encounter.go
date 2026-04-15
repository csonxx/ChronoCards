package model

import (
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// DynamicEncounterType 动态遭遇类型
type DynamicEncounterType string

const (
	EncounterBandits   DynamicEncounterType = "bandits"   // 山道匪帮
	EncounterTraveler  DynamicEncounterType = "traveler"  // 路过的旅人
	EncounterBeast     DynamicEncounterType = "beast"     // 野外野兽
	EncounterMerchant  DynamicEncounterType = "merchant" // 行商
	EncounterRefugee   DynamicEncounterType = "refugee"  // 流民
	EncounterMysterious DynamicEncounterType = "mysterious" // 神秘人
)

// DynamicEncounter 动态遭遇（程序化生成的发牌员）
type DynamicEncounter struct {
	ID          string               `json:"id"`
	Type        DynamicEncounterType `json:"type"`
	Name        string               `json:"name"`
	Description string               `json:"description"`
	Location    string               `json:"location"` // 出现位置
	
	// 遭遇配置
	Config struct {
		Weight           int  `json:"weight"`            // 触发权重
		IsHostile        bool `json:"is_hostile"`        // 是否敌对
		CanCombat        bool `json:"can_combat"`         // 可否战斗
		CanNegotiate     bool `json:"can_negotiate"`      // 可否交涉
		CanTrade         bool `json:"can_trade"`          // 可否交易
		CanQuest         bool `json:"can_quest"`          // 是否触发任务
		MinPlayerLevel   int  `json:"min_player_level"`   // 最低玩家等级
		MaxPlayerLevel   int  `json:"max_player_level"`   // 最高玩家等级（0=无限制）
		FactionRequired  string `json:"faction_required"`  // 需要特定阵营
		ElementRequired  ElementType `json:"element_required"` // 需要特定元素（空=无要求）
	} `json:"config"`
	
	// 关联的发牌员数据（用于触发事件）
	Dealer Dealer `json:"dealer"`
	
	// 过期时间
	ExpiresAt time.Time `json:"expires_at"`
	
	// 是否已触发
	Triggered bool `json:"triggered"`
}

// DynamicEncounterPool 遭遇池（用于程序化生成）
type DynamicEncounterPool struct {
	Templates []EncounterTemplate `json:"templates"`
	RNG       *rand.Rand          `json:"-"` // 随机数生成器
}

// EncounterTemplate 遭遇模板
type EncounterTemplate struct {
	Type           DynamicEncounterType `json:"type"`
	NamePool       []string             `json:"name_pool"`       // 名称池
	DescPool       []string             `json:"desc_pool"`       // 描述池
	LocationPool   []string             `json:"location_pool"`   // 位置池
	Weight         int                  `json:"weight"`          // 基础权重
	IsHostile      bool                 `json:"is_hostile"`
	CanCombat      bool                 `json:"can_combat"`
	CanNegotiate   bool                 `json:"can_negotiate"`
	CanTrade       bool                 `json:"can_trade"`
	CanQuest       bool                 `json:"can_quest"`
	MinPlayerLevel int                  `json:"min_player_level"`
	MaxPlayerLevel int                  `json:"max_player_level"`
	DealerPrompt   string               `json:"dealer_prompt"`   // 发牌员提示语模板
}

// NewDynamicEncounterPool 创建遭遇池
func NewDynamicEncounterPool(seed int64) *DynamicEncounterPool {
	return &DynamicEncounterPool{
		Templates: getDefaultEncounterTemplates(),
		RNG:       rand.New(rand.NewSource(seed)),
	}
}

// GenerateEncounter 程序化生成一个遭遇
func (p *DynamicEncounterPool) GenerateEncounter(location string, playerLevel int) *DynamicEncounter {
	// 按权重随机选择模板类型
	templates := p.filterByLevel(p.Templates, playerLevel)
	if len(templates) == 0 {
		return nil
	}
	
	totalWeight := 0
	for _, t := range templates {
		totalWeight += t.Weight
	}
	
	roll := p.RNG.Intn(totalWeight)
	var selected *EncounterTemplate
	for i := range templates {
		roll -= templates[i].Weight
		if roll < 0 {
			selected = &templates[i]
			break
		}
	}
	if selected == nil {
		selected = &templates[0]
	}
	
	name := selected.NamePool[p.RNG.Intn(len(selected.NamePool))]
	desc := selected.DescPool[p.RNG.Intn(len(selected.DescPool))]
	
	dealerPrompt := selected.DealerPrompt
	if dealerPrompt == "" {
		dealerPrompt = defaultDealerPromptForEncounter(selected.Type)
	}
	
	enc := &DynamicEncounter{
		ID:          uuid.New().String(),
		Type:        selected.Type,
		Name:        name,
		Description: desc,
		Location:    location,
		Config: struct {
			Weight           int         `json:"weight"`
			IsHostile        bool        `json:"is_hostile"`
			CanCombat        bool        `json:"can_combat"`
			CanNegotiate     bool        `json:"can_negotiate"`
			CanTrade         bool        `json:"can_trade"`
			CanQuest         bool        `json:"can_quest"`
			MinPlayerLevel   int         `json:"min_player_level"`
			MaxPlayerLevel   int         `json:"max_player_level"`
			FactionRequired  string      `json:"faction_required"`
			ElementRequired  ElementType `json:"element_required"`
		}{
			Weight:          selected.Weight,
			IsHostile:       selected.IsHostile,
			CanCombat:       selected.CanCombat,
			CanNegotiate:    selected.CanNegotiate,
			CanTrade:        selected.CanTrade,
			CanQuest:        selected.CanQuest,
			MinPlayerLevel:  selected.MinPlayerLevel,
			MaxPlayerLevel:  selected.MaxPlayerLevel,
		},
		Dealer: Dealer{
			ID:                 uuid.New().String(),
			Type:               DealerDynamicEncounter,
			Name:               name,
			Location:           location,
			Description:        desc,
			InteractionPrompt:  dealerPrompt,
			Weight:             selected.Weight,
		},
		ExpiresAt: time.Now().Add(30 * time.Minute), // 30分钟后消失
		Triggered: false,
	}
	
	return enc
}

// GenerateMultiple 生成多个遭遇
func (p *DynamicEncounterPool) GenerateMultiple(count int, location string, playerLevel int) []*DynamicEncounter {
	encounters := make([]*DynamicEncounter, 0, count)
	usedTypes := make(map[DynamicEncounterType]bool)
	
	for len(encounters) < count {
		enc := p.GenerateEncounter(location, playerLevel)
		if enc != nil && !usedTypes[enc.Type] {
			encounters = append(encounters, enc)
			usedTypes[enc.Type] = true
		}
	}
	return encounters
}

func (p *DynamicEncounterPool) filterByLevel(templates []EncounterTemplate, level int) []EncounterTemplate {
	var filtered []EncounterTemplate
	for _, t := range templates {
		if level < t.MinPlayerLevel {
			continue
		}
		if t.MaxPlayerLevel > 0 && level > t.MaxPlayerLevel {
			continue
		}
		filtered = append(filtered, t)
	}
	return filtered
}

func defaultDealerPromptForEncounter(t DynamicEncounterType) string {
	switch t {
	case EncounterBandits:
		return "前方山路窜出一伙匪人，拦路喝道：此路是我开！"
	case EncounterTraveler:
		return "一位旅人向你拱手：这位壮士，可否结伴同行？"
	case EncounterBeast:
		return "林间一声兽吼，野兽蓄势待发！"
	case EncounterMerchant:
		return "行商招手：这位客官，我这有些货物要不要看看？"
	case EncounterRefugee:
		return "流民颤声：壮士，行行好，给点吃的吧..."
	case EncounterMysterious:
		return "神秘人低声道：此非说话之地，随我来..."
	default:
		return "前方似乎有什么动静..."
	}
}

// getDefaultEncounterTemplates 默认遭遇模板
func getDefaultEncounterTemplates() []EncounterTemplate {
	return []EncounterTemplate{
		{
			Type:         EncounterBandits,
			NamePool:     []string{"山匪甲", "劫道匪徒", "黑风寨喽啰", "拦路贼人"},
			DescPool:     []string{"一伙山匪，手持刀棍，满脸凶相", "匪徒们占据要道，见人就劫", "黑风寨的小喽啰，为首的有些武艺"},
			LocationPool: []string{"山道", "密林", "荒野"},
			Weight:       20,
			IsHostile:    true,
			CanCombat:    true,
			CanNegotiate: true,
			CanQuest:     true,
		},
		{
			Type:         EncounterTraveler,
			NamePool:     []string{"行商", "书生", "侠客", "游方郎中"},
			DescPool:     []string{"一位行路之人，似乎在赶路", "书生模样，背着书箱", "江湖侠客，腰佩长剑"},
			LocationPool: []string{"官道", "茶亭", "渡口"},
			Weight:       25,
			IsHostile:    false,
			CanCombat:    false,
			CanNegotiate: true,
			CanTrade:     true,
			CanQuest:     true,
		},
		{
			Type:         EncounterBeast,
			NamePool:     []string{"野狼", "猛虎", "野猪", "毒蛇"},
			DescPool:     []string{"一头野兽蛰伏林间", "凶猛的野兽盯着你", "野兽蓄势待发，准备扑击"},
			LocationPool: []string{"山林", "密林", "草丛"},
			Weight:       15,
			IsHostile:    true,
			CanCombat:    true,
			CanNegotiate: false,
		},
		{
			Type:         EncounterMerchant,
			NamePool:     []string{"货郎", "行脚商", "马帮商人"},
			DescPool:     []string{"行商赶着驴车，载满货物", "马帮商人，带着一队骡马", "货郎挑着担子，沿途叫卖"},
			LocationPool: []string{"官道", "驿站", "集市"},
			Weight:       20,
			IsHostile:    false,
			CanCombat:    false,
			CanNegotiate: true,
			CanTrade:     true,
		},
		{
			Type:         EncounterRefugee,
			NamePool:     []string{"流民甲", "难民", "逃难的村民"},
			DescPool:     []string{"衣衫褴褛的流民，面带饥色", "逃难的百姓，扶老携幼", "流离失所的村民，眼神惊恐"},
			LocationPool: []string{"路边", "破庙", "废墟"},
			Weight:       10,
			IsHostile:    false,
			CanNegotiate: true,
			CanQuest:     true,
		},
		{
			Type:         EncounterMysterious,
			NamePool:     []string{"黑衣人", "神秘客", "蒙面人"},
			DescPool:     []string{"黑纱遮面，来历不明", "行踪诡秘，似乎有要事相告", "神秘人物，气质不凡"},
			LocationPool: []string{"暗巷", "密林", "古庙"},
			Weight:       5,
			IsHostile:    false,
			CanNegotiate: true,
			CanQuest:     true,
			MinPlayerLevel: 5,
		},
	}
}
