package skill

import (
	"fmt"
	"math/rand"
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/server/internal/model"
	"github.com/csonxx/ChronoCards/server/internal/store"
)

// Service 技能服务
type Service struct {
	store      store.StoreInterface
	cooldowns  map[string]map[string]time.Time
	cooldownMu sync.RWMutex
}

// NewService 创建技能服务
func NewService(s store.StoreInterface) *Service {
	return &Service{
		store:     s,
		cooldowns: make(map[string]map[string]time.Time),
	}
}

// SkillResult 技能使用结果
type SkillResult struct {
	Skill       *model.Skill `json:"skill"`
	Damage      int          `json:"damage"`
	MPUsed      int          `json:"mp_used"`
	SIUsed      int          `json:"si_used"`
	CooldownSec int          `json:"cooldown_seconds"`
	NewHP       int          `json:"target_hp,omitempty"`
	StatusMsg   string       `json:"message"`
}

// SkillAvailable 技能可用状态
type SkillAvailable struct {
	Skill    *model.Skill `json:"skill"`
	Available bool        `json:"available"`
	Reason   string       `json:"reason,omitempty"`
	CooldownRemain int   `json:"cooldown_remaining_sec,omitempty"`
}

// CanUseSkill 检查技能是否可用
func (s *Service) CanUseSkill(playerID string, skill *model.Skill) (bool, string) {
	if skill.CooldownSeconds > 0 {
		if remaining := s.GetSkillCooldownRemaining(playerID, skill.ID); remaining > 0 {
			return false, fmt.Sprintf("冷却中，还剩%d秒", remaining)
		}
	}
	if skill.MPCost > 0 {
		player, _ := s.store.GetPlayer(playerID)
		if player == nil || player.MP < skill.MPCost {
			return false, "内力不足"
		}
	}
	if skill.SwordIntentCost > 0 {
		player, _ := s.store.GetPlayer(playerID)
		if player == nil || player.SwordIntent < skill.SwordIntentCost {
			return false, "剑意不足"
		}
	}
	return true, ""
}

// GetSkillCooldownRemaining 获取技能剩余冷却秒数
func (s *Service) GetSkillCooldownRemaining(playerID, skillID string) int {
	s.cooldownMu.RLock()
	defer s.cooldownMu.RUnlock()
	if playerCooldowns, ok := s.cooldowns[playerID]; ok {
		if lastUsed, ok := playerCooldowns[skillID]; ok {
			return int(time.Since(lastUsed).Seconds())
		}
	}
	return 0
}

// UseSkill 使用技能
func (s *Service) UseSkill(player *model.Player, skill *model.Skill, targetHP *int) (*SkillResult, error) {
	canUse, reason := s.CanUseSkill(player.ID, skill)
	if !canUse {
		return &SkillResult{Skill: skill, StatusMsg: reason}, fmt.Errorf("%s", reason)
	}

	// 消耗资源
	player.MP -= skill.MPCost
	player.SwordIntent -= skill.SwordIntentCost
	s.store.UpdatePlayer(player)

	// 记录冷却
	if skill.CooldownSeconds > 0 {
		s.cooldownMu.Lock()
		if s.cooldowns[player.ID] == nil {
			s.cooldowns[player.ID] = make(map[string]time.Time)
		}
		s.cooldowns[player.ID][skill.ID] = time.Now()
		s.cooldownMu.Unlock()
	}

	// 计算伤害
	damage := CalculateSkillDamage(skill, player)
	if targetHP != nil {
		*targetHP -= damage
		if *targetHP < 0 {
			*targetHP = 0
		}
	}

	result := &SkillResult{
		Skill:       skill,
		Damage:      damage,
		MPUsed:      skill.MPCost,
		SIUsed:      skill.SwordIntentCost,
		CooldownSec: skill.CooldownSeconds,
		NewHP:       0,
		StatusMsg:   fmt.Sprintf("%s 造成 %d 点伤害", skill.Name, damage),
	}
	if targetHP != nil {
		result.NewHP = *targetHP
	}

	return result, nil
}

// GetAvailableSkills 获取玩家可用技能列表
func (s *Service) GetAvailableSkills(player *model.Player, allSkills []*model.Skill) []*SkillAvailable {
	results := make([]*SkillAvailable, 0, len(allSkills))
	for _, skill := range allSkills {
		available := &SkillAvailable{Skill: skill, Available: true}
		if ok, reason := s.CanUseSkill(player.ID, skill); !ok {
			available.Available = false
			available.Reason = reason
			available.CooldownRemain = s.GetSkillCooldownRemaining(player.ID, skill.ID)
		}
		results = append(results, available)
	}
	return results
}

// LearnSkill 玩家学习技能
func (s *Service) LearnSkill(player *model.Player, skillID string) error {
	for _, id := range player.Skills {
		if id == skillID {
			return fmt.Errorf("已学会此技能")
		}
	}
	player.Skills = append(player.Skills, skillID)
	s.store.UpdatePlayer(player)
	return nil
}

// GetSkillByID 根据ID获取预设技能
func GetSkillByID(skillID string) *model.Skill {
	for _, skill := range PresetSkills {
		if skill.ID == skillID {
			return &skill
		}
	}
	return nil
}

// AllPresetSkills 返回所有预设技能
func AllPresetSkills() []*model.Skill {
	result := make([]*model.Skill, len(PresetSkills))
	for i := range PresetSkills {
		result[i] = &PresetSkills[i]
	}
	return result
}

// RandomSkill 随机返回一个可用技能（用于AI）
func RandomSkill() *model.Skill {
	idx := rand.Intn(len(PresetSkills))
	return &PresetSkills[idx]
}
