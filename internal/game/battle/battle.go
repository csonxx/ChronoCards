package battle

// DodgeResult 闪避结果
type DodgeResult struct {
	Dodged              bool   `json:"dodged"`
	PerfectDodge        bool   `json:"perfect_dodge"`
	SwordIntentGained   int    `json:"sword_intent_gained"`
	StaminaCost         int    `json:"stamina_cost"`
	StaminaRemaining    int    `json:"stamina_remaining"`
	InvincibleDurationMs int   `json:"invincible_duration_ms"`
	Description         string `json:"description"`
}

// BlockResult 格挡结果
type BlockResult struct {
	Blocked             bool   `json:"blocked"`
	PerfectBlock        bool   `json:"perfect_block"`
	DamageReduction     float64 `json:"damage_reduction"`
	StaminaCost         int     `json:"stamina_cost"`
	StaminaRemaining    int     `json:"stamina_remaining"`
	CounterAvailable    bool   `json:"counter_available"`
	SwordIntentGained   int    `json:"sword_intent_gained"`
	MPCost              int    `json:"mp_cost"`
	Description         string `json:"description"`
}

// BattleCalculator 战斗伤害计算器
type BattleCalculator struct {
	perfectBlockWindowMs int // 完美格挡窗口（毫秒）
	invincibleFrameMs    int // 闪避无敌帧（毫秒）
	perfectDodgeBonusSI  int // 完美闪避获得剑意值
	perfectBlockBonusSI  int // 完美格挡获得剑意值
	consecutiveDodgeSI   int // 每连续闪避一次获得剑意值
	skillDodgeSI         int // 无伤闪避敌方技能获得剑意值
	staminaCostPerDodge  int // 每次闪避消耗体力
	counterDamageMult    float64 // 反击伤害倍率
}

// NewBattleCalculator 创建战斗计算器
func NewBattleCalculator() *BattleCalculator {
	return &BattleCalculator{
		perfectBlockWindowMs: 150,  // 0.15秒 = 150毫秒
		invincibleFrameMs:    400,  // 0.4秒无敌帧
		perfectDodgeBonusSI:   15,  // 无伤闪避敌方技能
		perfectBlockBonusSI:   20,  // 完美格挡
		consecutiveDodgeSI:    5,  // 每连续闪避一次
		skillDodgeSI:          15,  // 无伤闪避技能
		staminaCostPerDodge:  20,  // 闪避消耗体力
		counterDamageMult:    1.5, // 反击伤害×1.5
	}
}

// Dodge 闪避判定
// attackTimingMs: 攻击命中时机（相对于攻击开始的毫秒）
// dodgeTimingMs: 玩家闪避输入时机
func (b *BattleCalculator) Dodge(attackTimingMs, dodgeTimingMs, staminaAvailable int) *DodgeResult {
	result := &DodgeResult{
		StaminaCost:      b.staminaCostPerDodge,
		StaminaRemaining: staminaAvailable,
		Description:      "闪避失败",
	}

	// 检查体力是否足够
	if staminaAvailable < b.staminaCostPerDodge {
		result.Dodged = false
		result.PerfectDodge = false
		return result
	}

	// 计算时间差
	timeDiff := dodgeTimingMs - attackTimingMs
	if timeDiff < 0 {
		timeDiff = -timeDiff
	}

	// 无敌帧判定
	if timeDiff <= b.invincibleFrameMs {
		result.Dodged = true
		result.InvincibleDurationMs = b.invincibleFrameMs
		result.StaminaCost = b.staminaCostPerDodge
		result.StaminaRemaining = staminaAvailable - b.staminaCostPerDodge

		// 判断是否完美闪避（闪避输入在攻击到达前）
		if dodgeTimingMs < attackTimingMs {
			result.PerfectDodge = true
			result.SwordIntentGained = b.perfectDodgeBonusSI
			result.Description = "完美闪避！无敌帧内躲过攻击，获得剑意+" + itoa(b.perfectDodgeBonusSI)
		} else {
			result.SwordIntentGained = b.consecutiveDodgeSI
			result.Description = "闪避成功！获得剑意+" + itoa(b.consecutiveDodgeSI)
		}
	} else {
		result.Dodged = false
		result.PerfectDodge = false
	}

	return result
}

// Block 格挡判定
// perfectBlockWindow: 是否在完美格挡窗口内（0.15秒内）
func (b *BattleCalculator) Block(attackTimingMs, blockTimingMs, staminaAvailable int, isPerfectWindow bool) *BlockResult {
	result := &BlockResult{
		Blocked:          true,
		DamageReduction:  1.0, // 默认完全格挡（物理伤害）
		StaminaCost:      10, // 普通格挡消耗体力
		StaminaRemaining: staminaAvailable,
		MPCost:           0,
		Description:      "格挡成功",
	}

	// 检查体力
	if staminaAvailable < result.StaminaCost {
		result.Blocked = false
		return result
	}

	if isPerfectWindow {
		// 完美格挡
		result.PerfectBlock = true
		result.DamageReduction = 1.0 // 完全免伤
		result.StaminaCost = 0       // 完美格挡不消耗体力
		result.StaminaRemaining = staminaAvailable // 体力不变
		result.MPCost = 0
		result.CounterAvailable = true // 可触发反击
		result.SwordIntentGained = b.perfectBlockBonusSI
		result.Description = "完美格挡！免伤+积累剑意+" + itoa(b.perfectBlockBonusSI) + "+反击机会"
	} else {
		// 普通格挡
		result.PerfectBlock = false
		result.DamageReduction = 0.5 // 减免50%伤害
		result.StaminaCost = 10
		result.StaminaRemaining = staminaAvailable - result.StaminaCost
		result.CounterAvailable = false
		result.SwordIntentGained = 0
		result.Description = "格挡成功，伤害减半"
	}

	return result
}

// CounterDamage 计算反击伤害
func (b *BattleCalculator) CounterDamage(baseDamage float64) float64 {
	return baseDamage * b.counterDamageMult
}

// CalculateDamage 计算最终伤害
// 公式：最终伤害 = 基础伤害 × (1 + 精通加成率) × 反应倍率 × 暴击倍率
func (b *BattleCalculator) CalculateDamage(baseDamage float64, elementalMultiplier, reactionMultiplier float64, isCritical bool, masteryBonusRate float64) float64 {
	critMult := 1.0
	if isCritical {
		critMult = 1.5
	}

	finalDamage := baseDamage * (1.0 + masteryBonusRate) * reactionMultiplier * critMult * elementalMultiplier
	return finalDamage
}

// ApplyDamageReduction 应用伤害减免
func (b *BattleCalculator) ApplyDamageReduction(damage float64, reductionRate float64) float64 {
	return damage * (1.0 - reductionRate)
}

// CalculateElementalMasteryBonus 计算元素精通加成
// 加成率 = 元素精通 / (元素精通 + 目标等级×10 + 100)
func (b *BattleCalculator) CalculateElementalMasteryBonus(mastery, defenderLevel int) float64 {
	if mastery <= 0 {
		return 0.0
	}
	return float64(mastery) / (float64(mastery) + float64(defenderLevel)*10.0 + 100.0)
}

// StaminaRecoveryRate 体力回复速度（战斗中每秒5%）
func (b *BattleCalculator) StaminaRecoveryRate() float64 {
	return 0.05
}

// MPRecoveryRate 内力回复速度（受内功等级影响）
// 每秒内力回复 = 2 + (内功等级 × 0.2)
func (b *BattleCalculator) MPRecoveryRate(neigongLevel int) float64 {
	return 2.0 + float64(neigongLevel)*0.2
}

func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	s := ""
	for i > 0 {
		s = string(rune('0'+i%10)) + s
		i /= 10
	}
	return s
}
