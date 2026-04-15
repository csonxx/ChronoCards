package skill

import "github.com/csonxx/ChronoCards/server/internal/model"

// PresetSkills 预设武侠技能（MVP版本）
var PresetSkills = []model.Skill{
	// --- 通用技能 ---
	{
		ID:                "skill_strike",
		Name:              "基础攻击",
		Type:              "E",
		Element:           "none",
		CooldownSeconds:   0,
		MPCost:            0,
		SwordIntentCost:   0,
		BaseDamage:        10,
		Description:       "最基础的剑招，无任何特殊效果。",
	},
	// --- Q技能 ---
	{
		ID:                "skill_fireball",
		Name:              "火焰掌",
		Type:              "Q",
		Element:           "fire",
		CooldownSeconds:   8,
		MPCost:            20,
		SwordIntentCost:   0,
		BaseDamage:        40,
		Description:       "聚气成焰，隔空击出。命中附加灼烧状态，每秒流失生命。",
	},
	{
		ID:                "skill_windslash",
		Name:              "疾风剑",
		Type:              "Q",
		Element:           "wind",
		CooldownSeconds:   6,
		MPCost:            15,
		SwordIntentCost:   0,
		BaseDamage:        30,
		Description:       "以极速剑气切割目标，来去如风。",
	},
	{
		ID:                "skill_icethrust",
		Name:              "寒冰刺",
		Type:              "Q",
		Element:           "ice",
		CooldownSeconds:   10,
		MPCost:            25,
		SwordIntentCost:   0,
		BaseDamage:        50,
		Description:       "寒气凝于剑尖直刺，命中后减速敌人。",
	},
	{
		ID:                "skill_thunder_fist",
		Name:              "雷霆一击",
		Type:              "Q",
		Element:           "thunder",
		CooldownSeconds:   12,
		MPCost:            30,
		SwordIntentCost:   0,
		BaseDamage:        60,
		Description:       "电光火石间击出，雷声轰鸣，附麻痹效果。",
	},
	// --- 终极技能 ---
	{
		ID:                "skill_ult_thunder",
		Name:              "天雷破",
		Type:              "ultimate",
		Element:           "thunder",
		CooldownSeconds:   60,
		MPCost:            50,
		SwordIntentCost:   30,
		BaseDamage:        120,
		Description:       "汇聚全身剑意，引天雷一击。伤害极高，附带群体麻痹。",
	},
	{
		ID:                "skill_ult_void",
		Name:              "虚空剑",
		Type:              "ultimate",
		Element:           "wind",
		CooldownSeconds:   90,
		MPCost:            80,
		SwordIntentCost:   50,
		BaseDamage:        200,
		Description:       "传说中无影无形的至高剑招。伤害惊人，附带击退效果。",
	},
	{
		ID:                "skill_ult_fire_dragon",
		Name:              "烈焰火龙",
		Type:              "ultimate",
		Element:           "fire",
		CooldownSeconds:   75,
		MPCost:            70,
		SwordIntentCost:   40,
		BaseDamage:        180,
		Description:       "召唤火龙盘旋而出，灼烧一切。伤害爆炸性高。",
	},
}

// SkillCategories 技能分类展示
var SkillCategories = map[string][]model.Skill{
	"通用": {},
	"Q技能": {},
	"终极": {},
}

func init() {
	for _, s := range PresetSkills {
		switch s.Type {
		case "E", "passive":
			SkillCategories["通用"] = append(SkillCategories["通用"], s)
		case "Q":
			SkillCategories["Q技能"] = append(SkillCategories["Q技能"], s)
		case "ultimate":
			SkillCategories["终极"] = append(SkillCategories["终极"], s)
		}
	}
}
