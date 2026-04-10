package element

import (
	"github.com/csonxx/ChronoCards/backend/internal/model"
)

// ReactionType 元素反应类型
type ReactionType string

const (
	ReactionNone        ReactionType = "none"
	ReactionVaporize    ReactionType = "vaporize"    // 水+火 蒸发
	ReactionBurning     ReactionType = "burning"      // 火+风 燃烧
	ReactionSuperconduct ReactionType = "superconduct" // 雷+冰 超导
	ReactionElectrophys ReactionType = "electrophys"  // 雷+水 感电
	ReactionShatter     ReactionType = "shatter"      // 冰+火/雷 碎冰
	ReactionSpread      ReactionType = "spread"       // 风+任意 扩散
	ReactionToxicExplode ReactionType = "toxic_explode" // 毒+火 毒爆
	ReactionCongeal     ReactionType = "congeal"     // 水+冰 凝结
	ReactionErosion     ReactionType = "erosion"     // 毒+风 蚀骨
	ReactionSuppression ReactionType = "suppression"  // 元素压制
)

// ElementSuppressionMap 元素压制关系：风>火>雷>水>冰>毒>风
var ElementSuppressionMap = map[model.ElementType]model.ElementType{
	model.ElementWind:    model.ElementFire,    // 风克火
	model.ElementFire:   model.ElementThunder,  // 火克雷
	model.ElementThunder: model.ElementWater,   // 雷克水
	model.ElementWater:  model.ElementIce,       // 水克冰
	model.ElementIce:    model.ElementPoison,    // 冰克毒
	model.ElementPoison: model.ElementWind,      // 毒克风
}

// ReactionPairs 元素组合反应映射
var ReactionPairs = map[model.ElementType]map[model.ElementType]ReactionType{
	model.ElementFire: {
		model.ElementWind:    ReactionBurning,
		model.ElementWater:   ReactionVaporize,
		model.ElementIce:     ReactionShatter,
	},
	model.ElementWind: {
		model.ElementFire:    ReactionBurning,
		model.ElementWater:   ReactionSpread,
		model.ElementThunder: ReactionSpread,
		model.ElementIce:     ReactionSpread,
		model.ElementPoison:  ReactionErosion,
	},
	model.ElementThunder: {
		model.ElementWater:  ReactionElectrophys,
		model.ElementIce:    ReactionSuperconduct,
		model.ElementFire:   ReactionSpread,
	},
	model.ElementWater: {
		model.ElementFire:    ReactionVaporize,
		model.ElementIce:     ReactionCongeal,
		model.ElementThunder: ReactionElectrophys,
	},
	model.ElementIce: {
		model.ElementFire:    ReactionShatter,
		model.ElementThunder: ReactionShatter,
		model.ElementWater:   ReactionCongeal,
	},
	model.ElementPoison: {
		model.ElementFire:  ReactionToxicExplode,
		model.ElementWind:  ReactionErosion,
	},
}

// Calculator 元素反应计算器
type Calculator struct{}

// NewCalculator 创建计算器
func NewCalculator() *Calculator {
	return &Calculator{}
}

// CalculateReaction 计算元素反应
func (c *Calculator) CalculateReaction(attackerElem, defenderElem model.ElementType, baseDamage float64, attackerMastery, defenderLevel int) *model.ElementReactionResponse {
	resp := &model.ElementReactionResponse{
		SuppressionApplied:   false,
		SuppressionMultiplier: 1.0,
		FinalDamage:          baseDamage,
		StatusEffectsTriggered: []*model.StatusEffect{},
	}

	// 1. 检查元素压制（风>火>雷>水>冰>毒>风）
	if suppressor, ok := ElementSuppressionMap[attackerElem]; ok && suppressor == defenderElem {
		resp.SuppressionApplied = true
		resp.SuppressionMultiplier = 1.15
		resp.ReactionType = string(ReactionSuppression)
		resp.ReactionDescription = describeSuppression(attackerElem, defenderElem)
	}

	// 2. 检查元素反应
	reactionType, reactionMult, statusEffects := c.checkReaction(attackerElem, defenderElem, baseDamage, attackerMastery)
	resp.ReactionType = string(reactionType)
	resp.ReactionDescription = describeReaction(reactionType)

	if reactionMult > 0 {
		resp.FinalDamage = baseDamage * resp.SuppressionMultiplier * reactionMult
		resp.StatusEffectsTriggered = statusEffects
	}

	return resp
}

// checkReaction 检查具体元素反应
func (c *Calculator) checkReaction(elem1, elem2 model.ElementType, baseDamage float64, mastery int) (ReactionType, float64, []*model.StatusEffect) {
	// 双向检查（元素附着顺序不影响反应类型）
	if reactions, ok := ReactionPairs[elem1]; ok {
		if rt, ok := reactions[elem2]; ok {
			return c.resolveReaction(rt, elem1, elem2, baseDamage, mastery)
		}
	}
	if reactions, ok := ReactionPairs[elem2]; ok {
		if rt, ok := reactions[elem1]; ok {
			return c.resolveReaction(rt, elem1, elem2, baseDamage, mastery)
		}
	}
	return ReactionNone, 0, nil
}

// resolveReaction 解析具体反应
func (c *Calculator) resolveReaction(rt ReactionType, elem1, elem2 model.ElementType, baseDamage float64, mastery int) (ReactionType, float64, []*model.StatusEffect) {
	effects := []*model.StatusEffect{}
	mult := 1.0

	switch rt {
	case ReactionVaporize:
		// 水+火：伤害×1.5，下次攻击额外灼烧
		mult = 1.5
		burn := &model.StatusEffect{
			Type:            model.StatusBurn,
			Stacks:          1,
			DamagePerSecond: baseDamage * 0.05,
			DurationSeconds: 3,
			Effects:         model.StatusEffectDetails{},
		}
		effects = append(effects, burn)

	case ReactionBurning:
		// 火+风：持续灼烧范围扩散，伤害每秒叠加
		// 每层伤害 = 基础伤害的5%/秒，最大5层
		mult = 1.0
		burn := &model.StatusEffect{
			Type:            model.StatusBurn,
			Stacks:          1,
			DamagePerSecond: baseDamage * 0.05,
			DurationSeconds: 2, // 每新增一层刷新所有层+2秒
			Effects:         model.StatusEffectDetails{},
		}
		effects = append(effects, burn)

	case ReactionSuperconduct:
		// 雷+冰：大范围冻结条清空，对冻结目标伤害×2
		mult = 2.0
		// 注意：这里不直接添加freeze状态，而是清空冻结条

	case ReactionElectrophys:
		// 雷+水：目标持续麻痹，附近带电敌人受到连锁伤害
		mult = 1.2
		paralyze := &model.StatusEffect{
			Type:            model.StatusParalyze,
			Stacks:          1,
			DurationSeconds: 2,
			Effects:         model.StatusEffectDetails{Paralyzing: true},
		}
		effects = append(effects, paralyze)

	case ReactionShatter:
		// 冰+火/雷：冻结状态被打断，碎冰伤害 = 冻结时长×基础伤害
		// 实际碎冰伤害在战斗系统中单独处理，这里仅标记
		mult = 1.3

	case ReactionSpread:
		// 风+任意：元素效果扩散至周围敌人
		mult = 1.0
		// 扩散效果由战斗系统处理，这里仅记录

	case ReactionToxicExplode:
		// 毒+火：中毒层数清空，叠加层数×基础伤害立即结算
		mult = 1.5

	case ReactionCongeal:
		// 水+冰：形成冰墙，可阻挡移动和投射物
		mult = 0.9 // 略微减伤，因为目标是冰墙

	case ReactionErosion:
		// 毒+风：减速效果增强，毒素扩散速度提升
		// 每层 -15% 移动速度，最高5层，上限 -70%
		mult = 1.0
		slow := &model.StatusEffect{
			Type:            model.StatusSlow,
			Stacks:          1,
			DurationSeconds: 4,
			Effects: model.StatusEffectDetails{
				MoveSpeedReduction: 0.15,
			},
		}
		effects = append(effects, slow)
		// 蚀骨可与中毒叠加
		poison := &model.StatusEffect{
			Type:            model.StatusPoison,
			Stacks:          1,
			DamagePerSecond: baseDamage * 0.03,
			DurationSeconds: 3,
			Effects: model.StatusEffectDetails{
				HealReduction: 0.10,
			},
		}
		effects = append(effects, poison)
	}

	return rt, mult, effects
}

// ApplyElementalMastery 应用元素精通加成
// 精通加成率 = 元素精通 / (元素精通 + 目标等级×10 + 100)
func (c *Calculator) ApplyElementalMastery(baseDamage float64, mastery, defenderLevel int) float64 {
	if mastery <= 0 {
		return baseDamage
	}
	bonusRate := float64(mastery) / (float64(mastery) + float64(defenderLevel)*10.0 + 100.0)
	return baseDamage * (1.0 + bonusRate)
}

// CalculateFreezeDuration 计算冻结时长
// 冻结时长 = 2秒 × (1 - 韧性)，最多-50%韧性
func (c *Calculator) CalculateFreezeDuration(toughness float64) float64 {
	if toughness > 0.5 {
		toughness = 0.5
	}
	return 2.0 * (1.0 - toughness)
}

// CalculatePoisonDPS 计算中毒每秒伤害
// 每层伤害 = 基础伤害的3%/秒
func (c *Calculator) CalculatePoisonDPS(baseDamage float64, stacks int) float64 {
	if stacks > 5 {
		stacks = 5
	}
	return baseDamage * 0.03 * float64(stacks)
}

// CalculateBurnDPS 计算燃烧每秒伤害
// 每层伤害 = 基础伤害的5%/秒，最大5层
func (c *Calculator) CalculateBurnDPS(baseDamage float64, stacks int) float64 {
	if stacks > 5 {
		stacks = 5
	}
	return baseDamage * 0.05 * float64(stacks)
}

// GetSuppressionMultiplier 获取压制倍率
func (c *Calculator) GetSuppressionMultiplier(attackerElem, defenderElem model.ElementType) (bool, float64) {
	if suppressor, ok := ElementSuppressionMap[attackerElem]; ok && suppressor == defenderElem {
		return true, 1.15
	}
	return false, 1.0
}

// describeSuppression 描述压制关系
func describeSuppression(attacker, defender model.ElementType) string {
	return string(attacker) + " 压制 " + string(defender)
}

// describeReaction 描述元素反应
func describeReaction(rt ReactionType) string {
	switch rt {
	case ReactionVaporize:
		return "蒸发！水火相激，伤害激增"
	case ReactionBurning:
		return "燃烧！火焰随风扩散，持续灼烧"
	case ReactionSuperconduct:
		return "超导！冰雷交加，冻结断裂，伤害翻倍"
	case ReactionElectrophys:
		return "感电！雷水交融，目标陷入麻痹"
	case ReactionShatter:
		return "碎冰！冻结被打破，造成额外碎冰伤害"
	case ReactionSpread:
		return "扩散！风元素将效果扩散至周围敌人"
	case ReactionToxicExplode:
		return "毒爆！毒火相触，毒素瞬间引爆"
	case ReactionCongeal:
		return "凝结！水冰相会，冰墙拔地而起"
	case ReactionErosion:
		return "蚀骨！风毒交织，减速加剧"
	case ReactionSuppression:
		return "元素压制！造成额外伤害"
	default:
		return "无元素反应"
	}
}
