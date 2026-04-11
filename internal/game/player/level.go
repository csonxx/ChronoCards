package player

import "math"

// LevelConfig 升级配置
type LevelConfig struct {
	BaseExpCost int     // 每级基础经验需求，默认100
	ExpGrowth   float64 // 经验增长系数，默认1.2
}

// DefaultLevelConfig 默认升级配置
var DefaultLevelConfig = LevelConfig{
	BaseExpCost: 100,
	ExpGrowth:   1.2,
}

// CalcExpForLevel 计算升到指定等级所需总经验
// 1->2级需要100exp，2->3级需要120exp，3->4级需要144exp...
// 即 sum(100 * 1.2^(i-1)) for i=1 to level-1
// 几何级数求和公式: base * (r^(n-1) - 1) / (r - 1)
func CalcExpForLevel(level int) int {
	if level <= 1 {
		return 0
	}
	cfg := DefaultLevelConfig
	n := level - 1
	// 几何级数: base * (r^n - 1) / (r - 1)
	total := float64(cfg.BaseExpCost) * (math.Pow(cfg.ExpGrowth, float64(n)) - 1) / (cfg.ExpGrowth - 1)
	return int(total)
}

// CalcExpToNextLevel 计算升到下一级还需要的经验
func CalcExpToNextLevel(level int) int {
	return CalcExpForLevel(level + 1)
}

// CanLevelUp 判断当前经验是否可以升级
func CanLevelUp(level, exp int) bool {
	return exp >= CalcExpToNextLevel(level)
}

// StatGrowth 升级时属性增长
type StatGrowth struct {
	HPPerLevel      int // 每级HP增长，默认10
	MPPerLevel      int // 每级MP增长，默认5
	StaminaPerLevel int // 每级体力增长，默认0
	AttackPerLevel  int // 每级攻击增长，默认2
}

// DefaultStatGrowth 默认属性增长配置
var DefaultStatGrowth = StatGrowth{
	HPPerLevel:      10,
	MPPerLevel:      5,
	StaminaPerLevel: 0,
	AttackPerLevel:  2,
}

// GetStatGrowthForLevel 获取升级时的属性增长
// 目前所有等级使用相同的增长值，后续可扩展为根据等级段差异化增长
func GetStatGrowthForLevel(level int) StatGrowth {
	return DefaultStatGrowth
}
