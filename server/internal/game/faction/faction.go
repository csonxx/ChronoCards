package faction

import "github.com/csonxx/ChronoCards/server/internal/model"

// FactionID 阵营ID
type FactionID string

const (
	FactionMingjiao  FactionID = "mingjiao"  // 明教
	FactionShaolin   FactionID = "shaolin"   // 少林
	FactionWudang    FactionID = "wudang"    // 武当
	FactionJinyiwei  FactionID = "jinyiwei"  // 锦衣卫
	FactionWudu      FactionID = "wudu"      // 五毒教
	FactionGaibang   FactionID = "gaibang"   // 丐帮
)

// Faction 阵营
type Faction struct {
	ID          FactionID           `json:"id"`
	Name        string              `json:"name"`
	Description string              `json:"description"`
	Color       string              `json:"color"`       // 阵营代表色
	Relations   map[FactionID]RelationType `json:"relations"` // 与其他阵营的关系
}

// FactionRelation 阵营关系
type FactionRelation struct {
	FactionA   FactionID      `json:"faction_a"`
	FactionB   FactionID      `json:"faction_b"`
	Relation   RelationType   `json:"relation"`
}

// RelationType 关系类型
type RelationType string

const (
	RelationAlliance RelationType = "alliance" // 联盟
	RelationCoop     RelationType = "coop"     // 合作
	RelationNeutral  RelationType = "neutral"  // 中立
	RelationHostile  RelationType = "hostile" // 对立
)

// ReputationLevel 声望等级
type ReputationLevel int

const (
	RepLevelHatred     ReputationLevel = -3 // 仇恨 (≤ -50)
	RepLevelHostile    ReputationLevel = -2 // 敌视 (-49 ~ -20)
	RepLevelCold       ReputationLevel = -1 // 冷淡 (-19 ~ -5)
	RepLevelNeutral    ReputationLevel = 0  // 中立 (-4 ~ +20)
	RepLevelFriendly   ReputationLevel = 1  // 友好 (+21 ~ +50)
	RepLevelClose      ReputationLevel = 2  // 亲近 (+51 ~ +80)
	RepLevelBrother    ReputationLevel = 3  // 挚友 (+81 ~ +100)
	RepLevelLegend     ReputationLevel = 4  // 传说 (> +100)
)

// ReputationLevelInfo 声望等级信息
type ReputationLevelInfo struct {
	Level          ReputationLevel `json:"level"`
	Name           string          `json:"name"`
	MinValue       int             `json:"min_value"`
	MaxValue       int             `json:"max_value"`
	NPCTitle       string          `json:"npc_title"`       // NPC称呼
	NPCAttitude    string          `json:"npc_attitude"`    // NPC态度
	CanEnter       bool            `json:"can_enter"`       // 能否进入
	Discount       float64         `json:"discount"`        // 商店折扣
	TaskUnlock     string          `json:"task_unlock"`    // 可接任务类型
}

// GetReputationLevel 获取声望等级
func GetReputationLevel(value int) ReputationLevel {
	switch {
	case value <= -50:
		return RepLevelHatred
	case value <= -20:
		return RepLevelHostile
	case value <= -5:
		return RepLevelCold
	case value <= 20:
		return RepLevelNeutral
	case value <= 50:
		return RepLevelFriendly
	case value <= 80:
		return RepLevelClose
	case value <= 100:
		return RepLevelBrother
	default:
		return RepLevelLegend
	}
}

// GetReputationLevelInfo 获取声望等级详细信息
func GetReputationLevelInfo(value int) ReputationLevelInfo {
	level := GetReputationLevel(value)

	infoMap := map[ReputationLevel]ReputationLevelInfo{
		RepLevelHatred: {
			Level:       RepLevelHatred,
			Name:        "仇恨",
			MinValue:    -1000,
			MaxValue:    -50,
			NPCTitle:    "宿敌/魔头",
			NPCAttitude: "主动攻击（无视距离）",
			CanEnter:    false,
			Discount:    0,
			TaskUnlock:  "无法接取",
		},
		RepLevelHostile: {
			Level:       RepLevelHostile,
			Name:        "敌视",
			MinValue:    -49,
			MaxValue:    -20,
			NPCTitle:    "仇人",
			NPCAttitude: "敌意，攻击",
			CanEnter:    true,
			Discount:    0,
			TaskUnlock:  "无法接取",
		},
		RepLevelCold: {
			Level:       RepLevelCold,
			Name:        "冷淡",
			MinValue:    -19,
			MaxValue:    -5,
			NPCTitle:    "外人",
			NPCAttitude: "警惕，保持距离",
			CanEnter:    true,
			Discount:    0,
			TaskUnlock:  "只能交易，禁止深入对话",
		},
		RepLevelNeutral: {
			Level:       RepLevelNeutral,
			Name:        "中立",
			MinValue:    -4,
			MaxValue:    20,
			NPCTitle:    "路人",
			NPCAttitude: "礼貌，无特别态度",
			CanEnter:    true,
			Discount:    1.0,
			TaskUnlock:  "基础任务",
		},
		RepLevelFriendly: {
			Level:       RepLevelFriendly,
			Name:        "友好",
			MinValue:    21,
			MaxValue:    50,
			NPCTitle:    "熟客",
			NPCAttitude: "愿意帮忙",
			CanEnter:    true,
			Discount:    0.9,
			TaskUnlock:  "进阶任务",
		},
		RepLevelClose: {
			Level:       RepLevelClose,
			Name:        "亲近",
			MinValue:    51,
			MaxValue:    80,
			NPCTitle:    "盟友",
			NPCAttitude: "主动协助",
			CanEnter:    true,
			Discount:    0.8,
			TaskUnlock:  "核心任务线",
		},
		RepLevelBrother: {
			Level:       RepLevelBrother,
			Name:        "挚友",
			MinValue:    81,
			MaxValue:    100,
			NPCTitle:    "同道",
			NPCAttitude: "完全信任",
			CanEnter:    true,
			Discount:    0,
			TaskUnlock:  "隐藏任务线",
		},
		RepLevelLegend: {
			Level:       RepLevelLegend,
			Name:        "传说",
			MinValue:    101,
			MaxValue:    9999,
			NPCTitle:    "传说",
			NPCAttitude: "全阵营歌颂",
			CanEnter:    true,
			Discount:    0,
			TaskUnlock:  "专属结局线",
		},
	}

	return infoMap[level]
}

// AllFactions 所有阵营
var AllFactions = []Faction{
	{
		ID:          FactionMingjiao,
		Name:        "明教",
		Description: "异端·革命者，圣火燃尽旧秩序",
		Color:       "#8B0000",
		Relations: map[FactionID]RelationType{
			FactionShaolin: RelationHostile,
			FactionWudang:  RelationHostile,
			FactionJinyiwei: RelationHostile,
			FactionWudu:    RelationCoop,
			FactionGaibang: RelationCoop,
		},
	},
	{
		ID:          FactionShaolin,
		Name:        "少林",
		Description: "正道·守护者，铜人铁壁，佛门慈悲",
		Color:       "#DAA520",
		Relations: map[FactionID]RelationType{
			FactionMingjiao:  RelationHostile,
			FactionWudang:    RelationAlliance,
			FactionJinyiwei:  RelationHostile,
			FactionWudu:      RelationHostile,
			FactionGaibang:   RelationNeutral,
		},
	},
	{
		ID:          FactionWudang,
		Name:        "武当",
		Description: "正道·哲武者，阴阳无形，以柔克刚",
		Color:       "#4A90D9",
		Relations: map[FactionID]RelationType{
			FactionMingjiao:  RelationHostile,
			FactionShaolin:   RelationAlliance,
			FactionJinyiwei:  RelationHostile,
			FactionWudu:      RelationHostile,
			FactionGaibang:   RelationNeutral,
		},
	},
	{
		ID:          FactionJinyiwei,
		Name:        "锦衣卫",
		Description: "庙堂·利刃，天子鹰犬，铁血法度",
		Color:       "#1C1C1C",
		Relations: map[FactionID]RelationType{
			FactionMingjiao:  RelationHostile,
			FactionShaolin:   RelationHostile,
			FactionWudang:    RelationHostile,
			FactionWudu:      RelationNeutral,
			FactionGaibang:   RelationHostile,
		},
	},
	{
		ID:          FactionWudu,
		Name:        "五毒教",
		Description: "异端·隐世者，蛊虫通灵，阴毒诡谲",
		Color:       "#6B238E",
		Relations: map[FactionID]RelationType{
			FactionMingjiao:  RelationCoop,
			FactionShaolin:   RelationHostile,
			FactionWudang:    RelationHostile,
			FactionJinyiwei:  RelationNeutral,
			FactionGaibang:   RelationNeutral,
		},
	},
	{
		ID:          FactionGaibang,
		Name:        "丐帮",
		Description: "草根·义侠，人数即正义，底层江湖",
		Color:       "#8B4513",
		Relations: map[FactionID]RelationType{
			FactionMingjiao:  RelationCoop,
			FactionShaolin:   RelationNeutral,
			FactionWudang:    RelationNeutral,
			FactionJinyiwei:  RelationHostile,
			FactionWudu:      RelationNeutral,
		},
	},
}

// GetFactionByID 根据ID获取阵营
func GetFactionByID(id FactionID) *Faction {
	for _, f := range AllFactions {
		if f.ID == id {
			return &f
		}
	}
	return nil
}

// GetRelation 获取两个阵营的关系
func GetRelation(a, b FactionID) RelationType {
	factionA := GetFactionByID(a)
	if factionA == nil {
		return RelationNeutral
	}
	rel, ok := factionA.Relations[b]
	if !ok {
		return RelationNeutral
	}
	return rel
}

// IsHostile 判断两个阵营是否对立
func IsHostile(a, b FactionID) bool {
	return GetRelation(a, b) == RelationHostile
}

// IsAlliance 判断两个阵营是否联盟
func IsAlliance(a, b FactionID) bool {
	return GetRelation(a, b) == RelationAlliance
}

// IsCoop 判断两个阵营是否合作关系
func IsCoop(a, b FactionID) bool {
	return GetRelation(a, b) == RelationCoop
}

// ReputationDelta 声望变化
type ReputationDelta struct {
	Mingjiao int `json:"mingjiao,omitempty"`
	Shaolin  int `json:"shaolin,omitempty"`
	Wudang   int `json:"wudang,omitempty"`
	Jinyiwei int `json:"jinyiwei,omitempty"`
	Wudu     int `json:"wudu,omitempty"`
	Gaibang  int `json:"gaibang,omitempty"`
}

// FactionCard 阵营卡牌
type FactionCard struct {
	ID          string        `json:"id"`
	FactionID   FactionID     `json:"faction_id"`
	Name        string        `json:"name"`
	Type        model.CardType `json:"type"` // burst/defensive/control/gain/summon/strategy/end/chain/counter/trap/stealth/range
	Description string        `json:"description"`
	Effect      string        `json:"effect"`       // 效果描述
	Cost        int           `json:"cost"`         // 消耗
	Cooldown    int           `json:"cooldown"`     // 冷却秒数
}

// KillIntentLevel 杀意值等级
type KillIntentLevel int

const (
	KillIntentNormal     KillIntentLevel = 0  // 0-20 正常
	KillIntentHostile    KillIntentLevel = 1  // 21-50 对立
	KillIntentExtreme    KillIntentLevel = 2  // 51-100 可灭门
	KillIntentWanted     KillIntentLevel = 3  // 100+ 悬赏
)

// GetKillIntentLevel 获取杀意值等级
func GetKillIntentLevel(value int) KillIntentLevel {
	switch {
	case value <= 20:
		return KillIntentNormal
	case value <= 50:
		return KillIntentHostile
	case value <= 100:
		return KillIntentExtreme
	default:
		return KillIntentWanted
	}
}

// GetKillIntentBonus 获取杀意值战斗加成
func GetKillIntentBonus(value int) (attackBonus float64, defenseBonus float64) {
	level := GetKillIntentLevel(value)
	switch level {
	case KillIntentNormal:
		return 1.0, 1.0
	case KillIntentHostile:
		return 1.1, 0.9 // 攻击+10%，伤害-10%
	case KillIntentExtreme:
		return 1.2, 0.8 // 可解锁灭门
	case KillIntentWanted:
		return 1.3, 0.7 // 阵营悬赏
	}
	return 1.0, 1.0
}
