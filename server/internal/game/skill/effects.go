package skill

import (
	"math/rand"

	"github.com/csonxx/ChronoCards/internal/model"
)

// StatusEffectType 状态效果类型
type StatusEffectType string

const (
	StatusBurn      StatusEffectType = "burn"
	StatusFreeze    StatusEffectType = "freeze"
	StatusPoison   StatusEffectType = "poison"
	StatusParalyze StatusEffectType = "paralyze"
	StatusSlow     StatusEffectType = "slow"
)

// StatusEffect 状态效果
type StatusEffect struct {
	Type     StatusEffectType `json:"type"`
	Duration int              `json:"duration_seconds"`
	DamagePerSecond int       `json:"damage_per_second"`
}

// CalculateSkillDamage 计算技能伤害
func CalculateSkillDamage(skill *model.Skill, player *model.Player) int {
	if skill == nil {
		return 0
	}
	base := skill.BaseDamage

	// 元素精通加成
	if skill.Element != "" && skill.Element != "none" {
		bonus := ApplyElementBonus(string(skill.Element), player.ElementMastery)
		base += bonus
	}

	// 等级修正
	levelBonus := (player.Level - 1) * 2
	base += levelBonus

	// 暴击（10%概率，1.5倍）
	if rand.Float64() < 0.1 {
		base = int(float64(base) * 1.5)
	}

	return base
}

// ApplyElementBonus 应用元素精通加成
func ApplyElementBonus(element string, mastery model.ElementMastery) int {
	var masteryVal int
	switch element {
	case "fire":
		masteryVal = mastery.Fire
	case "wind":
		masteryVal = mastery.Wind
	case "water":
		masteryVal = mastery.Water
	case "thunder":
		masteryVal = mastery.Thunder
	case "ice":
		masteryVal = mastery.Ice
	case "poison":
		masteryVal = mastery.Poison
	default:
		return 0
	}
	// 精通公式：每点精通 +0.5%伤害
	return int(float64(masteryVal) * 0.005 * 100) // 简化：100精 = 50%加成
}

// CalculateStatusEffect 根据技能计算状态效果
func CalculateStatusEffect(skill *model.Skill) []StatusEffect {
	if skill.Type == "E" || skill.Type == "passive" {
		return nil
	}

	// 元素技能附加对应状态
	switch skill.Element {
	case "fire":
		return []StatusEffect{{Type: StatusBurn, Duration: 5, DamagePerSecond: skill.BaseDamage / 5}}
	case "ice":
		return []StatusEffect{{Type: StatusSlow, Duration: 3, DamagePerSecond: 0}}
	case "thunder":
		return []StatusEffect{{Type: StatusParalyze, Duration: 2, DamagePerSecond: 0}}
	case "poison":
		return []StatusEffect{{Type: StatusPoison, Duration: 8, DamagePerSecond: skill.BaseDamage / 10}}
	}
	return nil
}

// IsUltimateSkill 判断是否为终极技能
func IsUltimateSkill(skill *model.Skill) bool {
	return skill.Type == "ultimate"
}
