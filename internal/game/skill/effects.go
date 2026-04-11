package skill

import (
	"math"

	"github.com/csonxx/ChronoCards/internal/model"
)

// CalculateSkillDamage 计算技能伤害
// 公式: base_damage + 元素精通加成 + 等级修正
func CalculateSkillDamage(skill *model.Skill, player *model.Player) int {
	baseDamage := skill.BaseDamage

	// 元素精通加成
	bonus := ApplyElementBonus(baseDamage, skill.Element, player.ElementMastery)

	// 等级修正: 每级 +2 基础伤害
	levelBonus := (player.Level - 1) * 2

	return baseDamage + bonus + levelBonus
}

// ApplyElementBonus 应用元素精通加成
// 火+10% 风+8% 水+5% 雷+12% 冰+6% 毒+7%
func ApplyElementBonus(baseDamage int, element model.ElementType, mastery model.ElementMastery) int {
	bonus := 0
	switch element {
	case model.ElementFire:
		bonus = mastery.Fire * 2 // 每点火精通 +2 伤害
	case model.ElementWind:
		bonus = mastery.Wind * 2
	case model.ElementWater:
		bonus = mastery.Water * 1
	case model.ElementThunder:
		bonus = mastery.Thunder * 3 // 雷精通加成高
	case model.ElementIce:
		bonus = mastery.Ice * 2
	case model.ElementPoison:
		bonus = mastery.Poison * 2
	}
	return int(math.Round(float64(baseDamage) * float64(bonus) / 100.0))
}

// StatusEffect 状态效果
type StatusEffect struct {
	Type     string // "burn"|"freeze"|"poison"|"paralyze"|"slow"
	Duration int    // 秒
	Damage   int    // 每秒伤害
}

// CalculateStatusEffect 根据技能type和element计算状态效果
func CalculateStatusEffect(skill *model.Skill) []StatusEffect {
	var effects []StatusEffect

	// Q技能: 附加元素状态
	if skill.Type == model.SkillQ {
		switch skill.Element {
		case model.ElementFire:
			effects = append(effects, StatusEffect{
				Type:     "burn",
				Duration: 3,
				Damage:   5,
			})
		case model.ElementIce:
			effects = append(effects, StatusEffect{
				Type:     "slow",
				Duration: 4,
				Damage:   0,
			})
		case model.ElementPoison:
			effects = append(effects, StatusEffect{
				Type:     "poison",
				Duration: 5,
				Damage:   3,
			})
		case model.ElementThunder:
			effects = append(effects, StatusEffect{
				Type:     "paralyze",
				Duration: 2,
				Damage:   0,
			})
		}
	}

	// 终极技能: 强力状态
	if skill.Type == model.SkillUltimate {
		switch skill.Element {
		case model.ElementThunder:
			effects = append(effects, StatusEffect{
				Type:     "paralyze",
				Duration: 4,
				Damage:   10,
			})
		case model.ElementWind:
			// 击退效果通过 narrative 返回，这里只给减速
			effects = append(effects, StatusEffect{
				Type:     "slow",
				Duration: 6,
				Damage:   0,
			})
		case model.ElementFire:
			effects = append(effects, StatusEffect{
				Type:     "burn",
				Duration: 6,
				Damage:   15,
			})
		case model.ElementIce:
			effects = append(effects, StatusEffect{
				Type:     "freeze",
				Duration: 3,
				Damage:   0,
			})
		}
	}

	return effects
}
