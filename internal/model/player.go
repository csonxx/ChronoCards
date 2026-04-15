package model

import (
	"math"
	"time"

	"github.com/google/uuid"
)

// ElementType 六元素
type ElementType string

const (
	ElementWind    ElementType = "wind"
	ElementFire    ElementType = "fire"
	ElementWater   ElementType = "water"
	ElementThunder ElementType = "thunder"
	ElementIce     ElementType = "ice"
	ElementPoison  ElementType = "poison"
)

// CardType 卡牌类型（v2.2 扩展：十类卡牌）
type CardType string

const (
	CardMainStory     CardType = "main_story"      // 主线剧情卡
	CardSideStory     CardType = "side_story"      // 支线故事卡
	CardCharacter     CardType = "character"       // 角色主导卡
	CardSkillUnlock   CardType = "skill_unlock"    // 机制体验卡（武学/装备解锁）
	CardStatUp        CardType = "stat_up"        // 数值提升卡
	CardEmotion       CardType = "emotion"         // 情感联结卡
	CardEconomy       CardType = "economy"         // 经济系统卡
	CardWorldFragment CardType = "world_fragment"  // 世界碎片卡
	CardBlank         CardType = "blank"          // 空白卡
)

// SkillType 技能类型
type SkillType string

const (
	SkillE        SkillType = "E"
	SkillQ        SkillType = "Q"
	SkillPassive  SkillType = "passive"
	SkillUltimate SkillType = "ultimate"
)

// StatusEffectType 状态效果类型
type StatusEffectType string

const (
	StatusBurn     StatusEffectType = "burn"
	StatusFreeze   StatusEffectType = "freeze"
	StatusPoison   StatusEffectType = "poison"
	StatusParalyze StatusEffectType = "paralyze"
	StatusSlow     StatusEffectType = "slow"
)

// Reputation 阵营声望
type Reputation struct {
	Mingjiao  int `json:"mingjiao"`  // 明教
	Zhengpai  int `json:"zhengpai"`  // 正派
	Jinyiwei  int `json:"jinyiwei"`  // 锦衣卫
}

// ElementMastery 元素精通
type ElementMastery struct {
	Wind    int `json:"wind"`
	Fire    int `json:"fire"`
	Water   int `json:"water"`
	Thunder int `json:"thunder"`
	Ice     int `json:"ice"`
	Poison  int `json:"poison"`
}

// Player 玩家
type Player struct {
	ID               string           `json:"id"`
	Name             string           `json:"name"`
	Level            int              `json:"level"`
	Exp              int              `json:"exp"`
	HP               int              `json:"hp"`
	MaxHP            int              `json:"max_hp"`
	MP               int              `json:"mp"`
	MaxMP            int              `json:"max_mp"`
	SwordIntent      int              `json:"sword_intent"` // 0-100
	Stamina          int              `json:"stamina"`
	MaxStamina       int              `json:"max_stamina"`
	ElementMastery   ElementMastery   `json:"element_mastery"`
	Faction          string           `json:"faction"`
	Reputation       Reputation       `json:"reputation"`
	Skills           []string         `json:"skills"` // 技能ID列表
	Decks            []string         `json:"decks"`  // 卡组ID列表
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

// NewPlayer 创建新玩家
func NewPlayer(name, faction string) *Player {
	now := time.Now()
	return &Player{
		ID:         uuid.New().String(),
		Name:       name,
		Level:      1,
		Exp:        0,
		HP:         100,
		MaxHP:      100,
		MP:         100,
		MaxMP:      100,
		SwordIntent: 0,
		Stamina:    100,
		MaxStamina: 100,
		ElementMastery: ElementMastery{
			Wind: 0, Fire: 0, Water: 0, Thunder: 0, Ice: 0, Poison: 0,
		},
		Faction: faction,
		Reputation: Reputation{
			Mingjiao: 0, Zhengpai: 0, Jinyiwei: 0,
		},
		Skills:    []string{},
		Decks:     []string{},
		CreatedAt: now,
		UpdatedAt: now,
	}
}

// Heal 回复生命
func (p *Player) Heal(amount int) {
	p.HP = min(p.HP+amount, p.MaxHP)
}

// ConsumeMP 消耗内力
func (p *Player) ConsumeMP(amount int) bool {
	if p.MP < amount {
		return false
	}
	p.MP -= amount
	return true
}

// AddSwordIntent 增加剑意值
func (p *Player) AddSwordIntent(amount int) {
	p.SwordIntent = min(p.SwordIntent+amount, 100)
}

// ConsumeSwordIntent 消耗剑意值
func (p *Player) ConsumeSwordIntent(amount int) bool {
	if p.SwordIntent < amount {
		return false
	}
	p.SwordIntent -= amount
	return true
}

// ConsumeStamina 消耗体力
func (p *Player) ConsumeStamina(amount int) bool {
	if p.Stamina < amount {
		return false
	}
	p.Stamina -= amount
	return true
}

// AddExp 增加经验值，返回是否升级以及升级次数
func (p *Player) AddExp(amount int) (leveledUp bool, times int, newLevel int) {
	if amount <= 0 {
		return false, 0, p.Level
	}
	p.Exp += amount
	times = 0
	for playerCanLevelUp(p.Level, p.Exp) {
		p.LevelUp()
		times++
	}
	return times > 0, times, p.Level
}

// LevelUp 执行升级，更新属性
func (p *Player) LevelUp() {
	growth := getPlayerStatGrowthForLevel(p.Level)
	p.Level++
	// 升级时 HP/MP 自动恢复满，并应用属性增长
	p.MaxHP += growth.HPPerLevel
	p.HP = p.MaxHP
	p.MaxMP += growth.MPPerLevel
	p.MP = p.MaxMP
	p.MaxStamina += growth.StaminaPerLevel
	p.Stamina = p.MaxStamina
}

// ---- 内部辅助（避免循环引用 level.go） ----

// playerCanLevelUp 判断玩家当前经验是否足够升级（内部用）
func playerCanLevelUp(level, exp int) bool {
	// 几何级数: 100 * (1.2^(level) - 1) / 0.2
	// 当 exp >= required 时可以升级
	n := level // 升到 level+1 需要的经验项数
	required := int(float64(100) * (math.Pow(1.2, float64(n)) - 1) / 0.2)
	return exp >= required
}

// getPlayerStatGrowthForLevel 获取属性增长（内部用）
func getPlayerStatGrowthForLevel(level int) playerStatGrowth {
	return playerStatGrowth{
		HPPerLevel:      10,
		MPPerLevel:      5,
		StaminaPerLevel: 0,
		AttackPerLevel:  2,
	}
}

type playerStatGrowth struct {
	HPPerLevel      int
	MPPerLevel      int
	StaminaPerLevel int
	AttackPerLevel  int
}

