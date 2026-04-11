package skill

import "github.com/csonxx/ChronoCards/internal/model"

// PresetSkills 预设武侠技能表（MVP版本）
var PresetSkills = []model.Skill{
	// --- 通用技能 ---
	{
		ID:              "skill_strike",
		Name:            "基础攻击",
		Type:            model.SkillE,
		Element:         "",
		CooldownSeconds: 0,
		MPCost:          0,
		SwordIntentCost: 0,
		BaseDamage:      10,
		Description:     "最基础的剑招，无任何特殊效果。",
	},
	{
		ID:              "skill_fireball",
		Name:            "火焰掌",
		Type:            model.SkillQ,
		Element:         model.ElementFire,
		CooldownSeconds: 8,
		MPCost:          20,
		SwordIntentCost: 0,
		BaseDamage:      40,
		Description:     "聚气成焰，隔空击出。命中附加灼烧状态。",
	},
	{
		ID:              "skill_windslash",
		Name:            "疾风剑",
		Type:            model.SkillQ,
		Element:         model.ElementWind,
		CooldownSeconds: 6,
		MPCost:          15,
		SwordIntentCost: 0,
		BaseDamage:      30,
		Description:     "以极速剑气切割目标。",
	},
	{
		ID:              "skill_icethrust",
		Name:            "寒冰刺",
		Type:            model.SkillQ,
		Element:         model.ElementIce,
		CooldownSeconds: 10,
		MPCost:          25,
		SwordIntentCost: 0,
		BaseDamage:      50,
		Description:     "寒气凝于剑尖直刺。命中附加冰冻减速。",
	},
	// --- 终极技能 ---
	{
		ID:              "skill_ult_thunder",
		Name:            "天雷破",
		Type:            model.SkillUltimate,
		Element:         model.ElementThunder,
		CooldownSeconds: 60,
		MPCost:          50,
		SwordIntentCost: 30,
		BaseDamage:      120,
		Description:     "汇聚全身剑意，引天雷一击。伤害极高。",
	},
	{
		ID:              "skill_ult_void",
		Name:            "虚空剑",
		Type:            model.SkillUltimate,
		Element:         model.ElementWind,
		CooldownSeconds: 90,
		MPCost:          80,
		SwordIntentCost: 50,
		BaseDamage:      200,
		Description:     "传说中无影无形的至高剑招。附带击退效果。",
	},
}

// GetPresetSkillByID 根据ID获取预设技能
func GetPresetSkillByID(skillID string) *model.Skill {
	for i := range PresetSkills {
		if PresetSkills[i].ID == skillID {
			return &PresetSkills[i]
		}
	}
	return nil
}

// AllPresetSkills 返回所有预设技能
func AllPresetSkills() []model.Skill {
	return PresetSkills
}
