package model

import (
	"time"
)

// BattlePlayerState 战斗状态快照
type BattlePlayerState struct {
	PlayerID           string               `json:"player_id"`
	HP                 int                  `json:"hp"`
	MaxHP              int                  `json:"max_hp"`
	MP                 int                  `json:"mp"`
	MaxMP              int                  `json:"max_mp"`
	Stamina            int                  `json:"stamina"`
	MaxStamina         int                  `json:"max_stamina"`
	SwordIntent        int                  `json:"sword_intent"`
	ElementAttachments []*ElementAttachment `json:"element_attachments"` // 当前附着的元素（最多2个）
	StatusEffects      []*StatusEffect      `json:"status_effects"`
	ActiveSkills       []*Skill             `json:"active_skills"`
}

// ElementAttachment 元素附着
type ElementAttachment struct {
	Element   ElementType `json:"element"`
	Stacks    int         `json:"stacks"`    // 1-5层
	ExpiresAt time.Time   `json:"expires_at"`
}

// StatusEffect 状态效果
type StatusEffect struct {
	Type            StatusEffectType    `json:"type"`
	Stacks          int                  `json:"stacks"`
	DamagePerSecond float64              `json:"damage_per_second"`
	DurationSeconds float64              `json:"duration_seconds"`
	Effects         StatusEffectDetails  `json:"effects"`
}

// StatusEffectDetails 状态效果详情
type StatusEffectDetails struct {
	HealReduction      float64 `json:"heal_reduction,omitempty"`      // 生命恢复降低率（中毒）
	MoveSpeedReduction float64 `json:"move_speed_reduction,omitempty"` // 移动速度降低率（蚀骨）
	Freezing           bool    `json:"freezing,omitempty"`           // 是否正在冻结
	Paralyzing         bool    `json:"paralyzing,omitempty"`         // 是否正在麻痹
}

// Skill 技能
type Skill struct {
	ID              string      `json:"id"`
	Name            string      `json:"name"`
	Type            SkillType   `json:"type"` // E/Q/passive/ultimate
	Element         ElementType `json:"element,omitempty"`
	CooldownSeconds int         `json:"cooldown_seconds"`
	MPCost          int         `json:"mp_cost"`
	SwordIntentCost int         `json:"sword_intent_cost"`
	BaseDamage      int         `json:"base_damage"`
	Description     string      `json:"description"`
}

// Dealer 发牌员
type Dealer struct {
	ID                 string     `json:"id"`
	Type               DealerType `json:"type"`
	Name               string     `json:"name"`
	Location           string     `json:"location"`
	Description        string     `json:"description"`
	InteractionPrompt  string     `json:"interaction_prompt"`
	Weight             int        `json:"weight"` // 触发权重
}

// DealerType 发牌员类型
type DealerType string

const (
	DealerTeahouse         DealerType = "teahouse"         // 茶馆说书人
	DealerBountyBoard      DealerType = "bounty_board"     // 悬赏公告栏
	DealerEnemy            DealerType = "enemy"            // 可审问的敌人
	DealerInn              DealerType = "inn"               // 客栈
	DealerMerchant         DealerType = "merchant"        // 商贩
	DealerDynamicEncounter DealerType = "dynamic_encounter" // 动态遭遇
	DealerEnvironment      DealerType = "environment"      // 环境线索
)

// NewDealer 创建发牌员
func NewDealer(dealerType DealerType, name, location, description string) *Dealer {
	return &Dealer{
		ID:                 name + "-" + location,
		Type:               dealerType,
		Name:               name,
		Location:           location,
		Description:        description,
		InteractionPrompt:  defaultInteractionPrompt(dealerType),
		Weight:             1,
	}
}

func defaultInteractionPrompt(t DealerType) string {
	switch t {
	case DealerTeahouse:
		return "说书人轻敲桌面：客官，可想听一段江湖旧事？"
	case DealerBountyBoard:
		return "悬赏公告栏上贴满了江湖悬赏令"
	case DealerEnemy:
		return "敌人跪地求饶：饶命！我说！我什么都说！"
	case DealerInn:
		return "客栈掌柜笑迎：客官，楼上雅间请"
	case DealerMerchant:
		return "商贩神秘兮兮：客官，我这有些稀罕物件..."
	case DealerDynamicEncounter:
		return "前方似乎有什么动静..."
	case DealerEnvironment:
		return "炊烟袅袅升起，似乎有人居住"
	default:
		return "这里似乎可以触发事件..."
	}
}
