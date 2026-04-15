package model

// MartialArtType 武学类型
type MartialArtType string

const (
	MartialArtExternal MartialArtType = "external" // 外功：攻击输出
	MartialArtInternal MartialArtType = "internal" // 内功：防御/元素
	MartialArtLightness MartialArtType = "lightness" // 轻功：机动位移
)

// MartialArt 武学定义
type MartialArt struct {
	ID          string         `json:"id"`
	Name        string         `json:"name"`
	Type        MartialArtType `json:"type"`           // 外功/内功/轻功
	Element     ElementType    `json:"element,omitempty"` // 元素属性（可选）
	Rank        int            `json:"rank"`          // 品阶 1-5（1=入门，5=绝学）
	Description string         `json:"description"`
	Icon        string         `json:"icon,omitempty"`
	
	// 技能列表（武学包含多个技能）
	Skills []string `json:"skills"` // 关联的Skill ID列表
	
	// 解锁条件
	UnlockConditions []UnlockCondition `json:"unlock_conditions"`
	
	// 前置武学（技能树）
	Prerequisites []string `json:"prerequisites"` // 需要先学习的武学ID
	
	// 数值加成
	StatBonus PlayerStatsBonus `json:"stat_bonus"`
	
	// 学习消耗
	LearnCost LearnCostInfo `json:"learn_cost"`
	
	// 是否已解锁
	IsUnlocked bool `json:"is_unlocked"`
}

// LearnCostInfo 学习消耗
type LearnCostInfo struct {
	Exp  int `json:"exp"`  // 消耗经验
	Gold int `json:"gold"` // 消耗金币
}

// UnlockCondition 解锁条件
type UnlockCondition struct {
	Type  string `json:"type"`  // level/quest/item/faction/reputation
	Value any    `json:"value"` // 条件值
}

// SkillTreeNode 技能树节点
type SkillTreeNode struct {
	MartialArtID string   `json:"martial_art_id"`
	Unlocked     bool     `json:"unlocked"`
	Position     struct { // 技能树中的位置（用于UI显示）
		X int `json:"x"`
		Y int `json:"y"`
	} `json:"position"`
}

// PlayerMartialArts 玩家武学数据
type PlayerMartialArts struct {
	PlayerID      string                   `json:"player_id"`
	Learned       []string                 `json:"learned"`        // 已学会的武学ID列表
	SkillTree     map[string]*SkillTreeNode `json:"skill_tree"`    // 技能树节点
	ActiveExternal *MartialArt              `json:"active_external"` // 当前装备的外功
	ActiveInternal *MartialArt              `json:"active_internal"` // 当前装备的内功
	ActiveLightness *MartialArt             `json:"active_lightness"` // 当前装备的轻功
}

// NewPlayerMartialArts 创建新玩家武学数据
func NewPlayerMartialArts(playerID string) *PlayerMartialArts {
	return &PlayerMartialArts{
		PlayerID:  playerID,
		Learned:   []string{},
		SkillTree: make(map[string]*SkillTreeNode),
	}
}

// CanLearn 检查玩家是否满足武学学习条件
func (p *PlayerMartialArts) CanLearn(art *MartialArt, player *Player) bool {
	if p.HasLearned(art.ID) {
		return false
	}
	// 检查前置武学
	for _, prereq := range art.Prerequisites {
		if !p.HasLearned(prereq) {
			return false
		}
	}
	// 检查解锁条件
	for _, cond := range art.UnlockConditions {
		if !checkCondition(cond, player) {
			return false
		}
	}
	return true
}

// HasLearned 检查是否已学会该武学
func (p *PlayerMartialArts) HasLearned(artID string) bool {
	for _, id := range p.Learned {
		if id == artID {
			return true
		}
	}
	return false
}

// Learn 添加武学到已学会列表
func (p *PlayerMartialArts) Learn(artID string) {
	if !p.HasLearned(artID) {
		p.Learned = append(p.Learned, artID)
	}
}

// Equip 装备武学
func (p *PlayerMartialArts) Equip(art *MartialArt) {
	switch art.Type {
	case MartialArtExternal:
		p.ActiveExternal = art
	case MartialArtInternal:
		p.ActiveInternal = art
	case MartialArtLightness:
		p.ActiveLightness = art
	}
}

// checkCondition 检查单个解锁条件（简化实现）
func checkCondition(cond UnlockCondition, player *Player) bool {
	switch cond.Type {
	case "level":
		if v, ok := cond.Value.(float64); ok {
			return player.Level >= int(v)
		}
	case "faction":
		if v, ok := cond.Value.(string); ok {
			return player.Faction == v
		}
	}
	return true
}
