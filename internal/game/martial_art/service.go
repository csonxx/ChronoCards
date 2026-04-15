package martial_art

import (
	"github.com/csonxx/ChronoCards/internal/model"
)

// Service 武学系统服务
type Service struct {
	presets []*model.MartialArt
}

// NewService 创建服务
func NewService() *Service {
	return &Service{
		presets: getPresetMartialArts(),
	}
}

// LearnResponse 学习武学结果
type LearnResponse struct {
	Success   bool            `json:"success"`
	MartialArt *model.MartialArt `json:"martial_art,omitempty"`
	Message   string          `json:"message"`
}

// LearnMartialArt 学习武学
func (s *Service) LearnMartialArt(pm *model.PlayerMartialArts, player *model.Player, artID string) *LearnResponse {
	resp := &LearnResponse{}
	
	art := s.GetMartialArt(artID)
	if art == nil {
		resp.Success = false
		resp.Message = "武学不存在"
		return resp
	}
	
	if pm.HasLearned(artID) {
		resp.Success = false
		resp.Message = "已学会该武学"
		return resp
	}
	
	if !pm.CanLearn(art, player) {
		resp.Success = false
		resp.Message = "不满足学习条件"
		return resp
	}
	
	// 检查金币和经验
	if player.Level < art.LearnCost.Exp/100+1 {
		resp.Success = false
		resp.Message = "等级不足"
		return resp
	}
	
	pm.Learn(artID)
	resp.Success = true
	resp.MartialArt = art
	resp.Message = "学会「" + art.Name + "」"
	
	return resp
}

// EquipMartialArt 装备武学
func (s *Service) EquipMartialArt(pm *model.PlayerMartialArts, artID string) *LearnResponse {
	resp := &LearnResponse{}
	
	if !pm.HasLearned(artID) {
		resp.Success = false
		resp.Message = "未学会该武学"
		return resp
	}
	
	art := s.GetMartialArt(artID)
	if art == nil {
		resp.Success = false
		resp.Message = "武学不存在"
		return resp
	}
	
	pm.Equip(art)
	resp.Success = true
	resp.MartialArt = art
	resp.Message = "已装备「" + art.Name + "」"
	
	return resp
}

// GetMartialArt 获取武学定义
func (s *Service) GetMartialArt(id string) *model.MartialArt {
	for _, art := range s.presets {
		if art.ID == id {
			return art
		}
	}
	return nil
}

// GetAllMartialArts 获取所有武学
func (s *Service) GetAllMartialArts() []*model.MartialArt {
	return s.presets
}

// GetSkillTree 获取玩家技能树
func (s *Service) GetSkillTree(pm *model.PlayerMartialArts) map[string]interface{} {
	result := map[string]interface{}{
		"learned": pm.Learned,
		"nodes":   []map[string]interface{}{},
	}
	
	for _, artID := range pm.Learned {
		art := s.GetMartialArt(artID)
		if art == nil {
			continue
		}
		node := map[string]interface{}{
			"id":          art.ID,
			"name":        art.Name,
			"type":        art.Type,
			"rank":        art.Rank,
			"description": art.Description,
			"skills":      art.Skills,
			"is_equipped": s.isCurrentlyEquipped(pm, art),
		}
		result["nodes"] = append(result["nodes"].([]map[string]interface{}), node)
	}
	
	// 添加当前装备信息
	if pm.ActiveExternal != nil {
		result["active_external"] = pm.ActiveExternal.Name
	}
	if pm.ActiveInternal != nil {
		result["active_internal"] = pm.ActiveInternal.Name
	}
	if pm.ActiveLightness != nil {
		result["active_lightness"] = pm.ActiveLightness.Name
	}
	
	return result
}

// isCurrentlyEquipped 检查武学是否当前装备
func (s *Service) isCurrentlyEquipped(pm *model.PlayerMartialArts, art *model.MartialArt) bool {
	switch art.Type {
	case model.MartialArtExternal:
		return pm.ActiveExternal != nil && pm.ActiveExternal.ID == art.ID
	case model.MartialArtInternal:
		return pm.ActiveInternal != nil && pm.ActiveInternal.ID == art.ID
	case model.MartialArtLightness:
		return pm.ActiveLightness != nil && pm.ActiveLightness.ID == art.ID
	}
	return false
}

// GetAvailableMartialArts 获取可学习的武学
func (s *Service) GetAvailableMartialArts(pm *model.PlayerMartialArts, player *model.Player) []*model.MartialArt {
	var available []*model.MartialArt
	for _, art := range s.presets {
		if pm.HasLearned(art.ID) {
			continue
		}
		if pm.CanLearn(art, player) {
			available = append(available, art)
		}
	}
	return available
}

// getPresetMartialArts 预设武学数据
func getPresetMartialArts() []*model.MartialArt {
	return []*model.MartialArt{
		// === 外功 ===
		{
			ID:   "martial_family_blade",
			Name: "家传刀法",
			Type: model.MartialArtExternal,
			Rank: 1,
			Description: "镖局家传刀法，以快制敌，适合新手修习。",
			Skills: []string{"skill_blade_1", "skill_blade_2"},
			Prerequisites: []string{},
			UnlockConditions: []model.UnlockCondition{},
			LearnCost: model.LearnCostInfo{Exp: 0, Gold: 0},
			IsUnlocked: true, // 初始武学
		},
		{
			ID:   "martial_wudang_sword",
			Name: "武当剑法",
			Type: model.MartialArtExternal,
			Rank: 2,
			Description: "武当派入门剑法，剑势连绵，以柔克刚。",
			Skills: []string{"skill_wudang_1", "skill_wudang_2"},
			Prerequisites: []string{"martial_family_blade"},
			UnlockConditions: []model.UnlockCondition{{Type: "level", Value: float64(3)}},
			LearnCost: model.LearnCostInfo{Exp: 200, Gold: 500},
		},
		{
			ID:   "martial_shaolin_fist",
			Name: "少林罗汉拳",
			Type: model.MartialArtExternal,
			Rank: 2,
			Description: "少林入门拳法，刚猛有力，最重根基。",
			Skills: []string{"skill_shaolin_1", "skill_shaolin_2"},
			Prerequisites: []string{},
			UnlockConditions: []model.UnlockCondition{{Type: "faction", Value: "shaolin"}},
			LearnCost: model.LearnCostInfo{Exp: 300, Gold: 800},
		},
		{
			ID:   "martial_mingjian",
			Name: "明教剑法",
			Type: model.MartialArtExternal,
			Rank: 3,
			Element: model.ElementFire,
			Description: "明教秘传剑法，剑走偏锋，狠辣无比。",
			Skills: []string{"skill_mingjian_1", "skill_mingjian_2", "skill_mingjian_3"},
			Prerequisites: []string{"martial_wudang_sword"},
			UnlockConditions: []model.UnlockCondition{{Type: "faction", Value: "mingjiao"}},
			LearnCost: model.LearnCostInfo{Exp: 500, Gold: 1500},
		},
		{
			ID:   "martial_yitian_sword",
			Name: "倚天剑诀",
			Type: model.MartialArtExternal,
			Rank: 4,
			Element: model.ElementThunder,
			Description: "绝学级剑诀，传闻为倚天屠龙之秘技。",
			Skills: []string{"skill_yitian_1", "skill_yitian_2", "skill_yitian_3"},
			Prerequisites: []string{"martial_mingjian", "martial_wudang_sword"},
			UnlockConditions: []model.UnlockCondition{{Type: "level", Value: float64(10)}},
			LearnCost: model.LearnCostInfo{Exp: 1000, Gold: 5000},
		},
		
		// === 内功 ===
		{
			ID:   "martial_qiti",
			Name: "护体真气",
			Type: model.MartialArtInternal,
			Rank: 1,
			Description: "镖局家传内功根基，护体防身，延年益寿。",
			Skills: []string{"skill_qiti_1"},
			Prerequisites: []string{},
			UnlockConditions: []model.UnlockCondition{},
			LearnCost: model.LearnCostInfo{Exp: 0, Gold: 0},
			IsUnlocked: true,
			StatBonus: model.PlayerStatsBonus{MaxHP: 20, MaxMP: 10},
		},
		{
			ID:   "martial_xiayu",
			Name: "虾狱功",
			Type: model.MartialArtInternal,
			Rank: 2,
			Description: "丐帮不传之秘，以静制动，后发制人。",
			Skills: []string{"skill_xiayu_1", "skill_xiayu_2"},
			Prerequisites: []string{"martial_qiti"},
			UnlockConditions: []model.UnlockCondition{{Type: "faction", Value: "gaibang"}},
			LearnCost: model.LearnCostInfo{Exp: 250, Gold: 600},
			StatBonus: model.PlayerStatsBonus{MaxMP: 30, Defense: 5},
		},
		{
			ID:   "martial_jiuyang",
			Name: "九阳神功",
			Type: model.MartialArtInternal,
			Rank: 4,
			Element: model.ElementFire,
			Description: "九阳真经所载，至刚至阳，天下第一内功。",
			Skills: []string{"skill_jiuyang_1", "skill_jiuyang_2", "skill_jiuyang_3"},
			Prerequisites: []string{"martial_xiayu", "martial_qiti"},
			UnlockConditions: []model.UnlockCondition{{Type: "level", Value: float64(8)}},
			LearnCost: model.LearnCostInfo{Exp: 800, Gold: 4000},
			StatBonus: model.PlayerStatsBonus{MaxHP: 100, MaxMP: 50, Fire: 20},
		},
		
		// === 轻功 ===
		{
			ID:   "martial_qinggong_basic",
			Name: "基础轻功",
			Type: model.MartialArtLightness,
			Rank: 1,
			Description: "江湖入门轻功，日行百里不在话下。",
			Skills: []string{"skill_qinggong_1", "skill_qinggong_2"},
			Prerequisites: []string{},
			UnlockConditions: []model.UnlockCondition{},
			LearnCost: model.LearnCostInfo{Exp: 0, Gold: 0},
			IsUnlocked: true,
		},
		{
			ID:   "martial_tianlu",
			Name: "天罗步",
			Type: model.MartialArtLightness,
			Rank: 2,
			Description: "身法轻盈，如履平地，进退自如。",
			Skills: []string{"skill_tianlu_1", "skill_tianlu_2"},
			Prerequisites: []string{"martial_qinggong_basic"},
			UnlockConditions: []model.UnlockCondition{{Type: "level", Value: float64(4)}},
			LearnCost: model.LearnCostInfo{Exp: 200, Gold: 400},
		},
		{
			ID:   "martial_yueying",
			Name: "月影追风",
			Type: model.MartialArtLightness,
			Rank: 3,
			Element: model.ElementWind,
			Description: "绝顶轻功，来去如风，踏月无痕。",
			Skills: []string{"skill_yueying_1", "skill_yueying_2", "skill_yueying_3"},
			Prerequisites: []string{"martial_tianlu"},
			UnlockConditions: []model.UnlockCondition{{Type: "level", Value: float64(7)}},
			LearnCost: model.LearnCostInfo{Exp: 500, Gold: 2000},
			StatBonus: model.PlayerStatsBonus{Wind: 15},
		},
	}
}
