package skill

import (
	"fmt"
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/internal/model"
	"github.com/csonxx/ChronoCards/internal/store"
)

// SkillResult 技能使用结果
type SkillResult struct {
	Skill         *model.Skill    `json:"skill"`
	Damage        int             `json:"damage"`
	MPUsed        int             `json:"mp_used"`
	SIUsed        int             `json:"si_used"`
	CooldownSec   int             `json:"cooldown_seconds"`
	StatusEffects []StatusEffect  `json:"status_effects"`
	Narrative     string          `json:"narrative"`
	Message       string          `json:"message"`
}

// SkillAvailable 技能可用状态
type SkillAvailable struct {
	Skill     *model.Skill `json:"skill"`
	Available bool         `json:"available"`
	Reason    string       `json:"reason"` // "cooldown"|"no_mp"|"no_si"|""
}

// Service 技能服务
type Service struct {
	store      store.StoreInterface
	cooldowns  map[string]map[string]time.Time // playerID -> skillID -> lastUsed
	mu         sync.RWMutex
}

// NewService 创建技能服务
func NewService(s store.StoreInterface) *Service {
	return &Service{
		store:     s,
		cooldowns: make(map[string]map[string]time.Time),
	}
}

// CanUseSkill 检查技能是否可用（冷却/资源够不够）
// 返回 (是否可用, 不可用原因)
func (s *Service) CanUseSkill(playerID, skillID string) (bool, string) {
	// 获取技能定义
	skill := GetPresetSkillByID(skillID)
	if skill == nil {
		return false, "skill_not_found"
	}

	// 检查冷却
	if s.isInCooldown(playerID, skillID, skill.CooldownSeconds) {
		return false, "cooldown"
	}

	// 检查MP（cost > 0时才检查）
	if skill.MPCost > 0 {
		player, ok := s.store.GetPlayer(playerID)
		if !ok {
			return false, "player_not_found"
		}
		if player.MP < skill.MPCost {
			return false, "no_mp"
		}
	}

	// 检查剑意值（cost > 0时才检查）
	if skill.SwordIntentCost > 0 {
		player, ok := s.store.GetPlayer(playerID)
		if !ok {
			return false, "player_not_found"
		}
		if player.SwordIntent < skill.SwordIntentCost {
			return false, "no_si"
		}
	}

	return true, ""
}

// isInCooldown 检查技能是否在冷却中
func (s *Service) isInCooldown(playerID, skillID string, cooldownSeconds int) bool {
	if cooldownSeconds <= 0 {
		return false
	}
	s.mu.RLock()
	defer s.mu.RUnlock()

	lastUsed, ok := s.cooldowns[playerID][skillID]
	if !ok {
		return false
	}
	elapsed := time.Since(lastUsed)
	return elapsed < time.Duration(cooldownSeconds)*time.Second
}

// UseSkill 使用技能
func (s *Service) UseSkill(player *model.Player, skill *model.Skill, target interface{}) (*SkillResult, error) {
	// 检查技能是否可用
	canUse, reason := s.CanUseSkill(player.ID, skill.ID)
	if !canUse {
		return nil, fmt.Errorf("cannot use skill: %s", reason)
	}

	// 消耗MP
	mpUsed := 0
	if skill.MPCost > 0 {
		if !player.ConsumeMP(skill.MPCost) {
			return nil, fmt.Errorf("not enough MP")
		}
		mpUsed = skill.MPCost
	}

	// 消耗剑意值
	siUsed := 0
	if skill.SwordIntentCost > 0 {
		if !player.ConsumeSwordIntent(skill.SwordIntentCost) {
			return nil, fmt.Errorf("not enough SwordIntent")
		}
		siUsed = skill.SwordIntentCost
	}

	// 更新玩家状态
	s.store.UpdatePlayer(player)

	// 记录冷却
	if skill.CooldownSeconds > 0 {
		s.setCooldown(player.ID, skill.ID)
	}

	// 计算伤害
	damage := CalculateSkillDamage(skill, player)

	// 计算状态效果
	statusEffects := CalculateStatusEffect(skill)

	// 生成叙事描述
	narrative := s.generateNarrative(skill, player, damage, statusEffects)

	result := &SkillResult{
		Skill:         skill,
		Damage:        damage,
		MPUsed:        mpUsed,
		SIUsed:        siUsed,
		CooldownSec:   skill.CooldownSeconds,
		StatusEffects: statusEffects,
		Narrative:     narrative,
		Message:       fmt.Sprintf("%s 造成 %d 点伤害", skill.Name, damage),
	}

	return result, nil
}

// setCooldown 设置技能冷却
func (s *Service) setCooldown(playerID, skillID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.cooldowns[playerID] == nil {
		s.cooldowns[playerID] = make(map[string]time.Time)
	}
	s.cooldowns[playerID][skillID] = time.Now()
}

// GetSkillCooldown 获取技能剩余冷却时间
func (s *Service) GetSkillCooldown(playerID, skillID string) time.Duration {
	skill := GetPresetSkillByID(skillID)
	if skill == nil {
		return 0
	}

	s.mu.RLock()
	defer s.mu.RUnlock()

	lastUsed, ok := s.cooldowns[playerID][skillID]
	if !ok {
		return 0
	}

	elapsed := time.Since(lastUsed)
	remaining := time.Duration(skill.CooldownSeconds)*time.Second - elapsed
	if remaining < 0 {
		return 0
	}
	return remaining
}

// GetAvailableSkills 获取玩家当前可用的技能列表
func (s *Service) GetAvailableSkills(player *model.Player) []*SkillAvailable {
	var result []*SkillAvailable

	for _, skillID := range player.Skills {
		skill := GetPresetSkillByID(skillID)
		if skill == nil {
			continue
		}

		available, reason := s.CanUseSkill(player.ID, skillID)
		result = append(result, &SkillAvailable{
			Skill:     skill,
			Available: available,
			Reason:    reason,
		})
	}

	return result
}

// LearnSkill 玩家学习新技能
func (s *Service) LearnSkill(playerID, skillID string) error {
	// 检查技能是否存在
	skill := GetPresetSkillByID(skillID)
	if skill == nil {
		return fmt.Errorf("skill not found: %s", skillID)
	}

	player, ok := s.store.GetPlayer(playerID)
	if !ok {
		return fmt.Errorf("player not found")
	}

	// 检查是否已学会
	for _, id := range player.Skills {
		if id == skillID {
			return fmt.Errorf("skill already learned")
		}
	}

	// 添加技能
	player.Skills = append(player.Skills, skillID)
	s.store.UpdatePlayer(player)

	return nil
}

// GetPlayerSkills 获取玩家已学会的所有技能（带冷却状态）
func (s *Service) GetPlayerSkills(player *model.Player) []*SkillAvailable {
	return s.GetAvailableSkills(player)
}

// generateNarrative 生成技能叙事描述
func (s *Service) generateNarrative(skill *model.Skill, player *model.Player, damage int, effects []StatusEffect) string {
	// 基础叙事
	narratives := map[string]string{
		"skill_strike":       fmt.Sprintf("%s挥剑直刺，干净利落。", player.Name),
		"skill_fireball":     fmt.Sprintf("%s双掌运劲，火焰掌热浪滚滚，直逼对手！", player.Name),
		"skill_windslash":    fmt.Sprintf("%s身形一闪，疾风剑如风卷残云般划过！", player.Name),
		"skill_icethrust":    fmt.Sprintf("%s剑尖寒芒一闪，寒冰刺直刺而出！", player.Name),
		"skill_ult_thunder":  fmt.Sprintf("%s全身剑意汇聚，天雷破引动九天雷罚！", player.Name),
		"skill_ult_void":     fmt.Sprintf("%s剑意如虚空般无影无形，虚空剑已然降临！", player.Name),
	}

	if narrative, ok := narratives[skill.ID]; ok {
		return narrative
	}

	return fmt.Sprintf("%s施展了%s，造成了%d点伤害。", player.Name, skill.Name, damage)
}
