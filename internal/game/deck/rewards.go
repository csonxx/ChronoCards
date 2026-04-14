package deck

import (
	"github.com/csonxx/ChronoCards/internal/model"
)

// ApplyCardRewards 应用卡牌奖励到玩家
func ApplyCardRewards(player *model.Player, card *model.Card) *CardRewardResult {
	if card == nil || card.Rewards == nil {
		return &CardRewardResult{}
	}

	result := &CardRewardResult{}

	// 处理经验奖励
	if card.Rewards.Exp > 0 {
		leveledUp, times, newLevel := player.AddExp(card.Rewards.Exp)
		result.ExpGained = card.Rewards.Exp
		result.LeveledUp = leveledUp
		result.LevelUpTimes = times
		result.NewLevel = newLevel
	}

	// 处理HP增长（直接增加最大HP和当前HP）
	if card.Rewards.HPUP > 0 {
		player.MaxHP += card.Rewards.HPUP
		player.HP += card.Rewards.HPUP
		result.HPGained = card.Rewards.HPUP
	}

	// 处理MP增长（直接增加最大MP和当前MP）
	if card.Rewards.MPUP > 0 {
		player.MaxMP += card.Rewards.MPUP
		player.MP += card.Rewards.MPUP
		result.MPGained = card.Rewards.MPUP
	}

	// 处理声望变化
	if card.Rewards.Reputation != nil {
		player.Reputation.Mingjiao += card.Rewards.Reputation.Mingjiao
		player.Reputation.Zhengpai += card.Rewards.Reputation.Zhengpai
		player.Reputation.Jinyiwei += card.Rewards.Reputation.Jinyiwei
		result.ReputationGained = card.Rewards.Reputation
	}

	// 处理技能解锁
	if card.Rewards.SkillID != "" {
		hasSkill := false
		for _, s := range player.Skills {
			if s == card.Rewards.SkillID {
				hasSkill = true
				break
			}
		}
		if !hasSkill {
			player.Skills = append(player.Skills, card.Rewards.SkillID)
			result.SkillUnlocked = card.Rewards.SkillID
		}
	}

	return result
}

// CardRewardResult 卡牌奖励应用结果
type CardRewardResult struct {
	ExpGained         int                    `json:"exp_gained,omitempty"`
	HPGained          int                    `json:"hp_gained,omitempty"`
	MPGained          int                    `json:"mp_gained,omitempty"`
	ReputationGained  *model.Reputation      `json:"reputation_gained,omitempty"`
	SkillUnlocked     string                 `json:"skill_unlocked,omitempty"`
	LeveledUp         bool                   `json:"leveled_up"`
	LevelUpTimes      int                    `json:"level_up_times"`
	NewLevel          int                    `json:"new_level"`
}
