package faction

import "github.com/csonxx/ChronoCards/server/internal/model"

// FactionReputationEvent 阵营声望事件
type FactionReputationEvent struct {
	Type        string     `json:"type"`    // event type
	Faction     FactionID  `json:"faction"` // target faction to update
	Delta       int        `json:"delta"`   // reputation change
	Reason      string     `json:"reason"`  // reason for change
	AntiFaction FactionID  `json:"anti_faction,omitempty"` // for hostile actions (kill intent target)
}

// reputationGainRules 声望获取规则（明教）
var mingjiaoGainRules = map[string]int{
	"join_ceremony":   15, // 加入光明顶圣火仪式
	"show_tattoo":     10, // 展示明教纹身
	"complete_leader_task": 20, // 完成教主任务
	"help_mingjiao_disciple": 10, // 帮助明教弟子
	"spread_teachings": 10, // 传播明教教义
}

var mingjiaoLoseRules = map[string]int{
	"attack_disciple":    -15, // 攻击明教弟子
	"insult_holy_fire":   -30, // 侮辱圣火
	"ally_with_zhengpai": 10,  // 与正道结盟（反向，正道声望降）
	"reject_task":        -10, // 拒绝明教任务
}

// reputationGainRules 声望获取规则（少林）
var shaolinGainRules = map[string]int{
	"donate_temple":        10, // 捐款修缮寺庙
	"complete_trial":       20, // 完成少林武僧试炼
	"escort_pilgrim":        10, // 护送香客
	"study_buddhism":        5,  // 研读佛经
	"defeat_mingjiao":       15, // 击败明教/五毒教
}

var shaolinLoseRules = map[string]int{
	"kill_monk":     -40, // 杀少林僧人
	"fight_in_temple": -30, // 在寺内动武
	"steal_sutra":   -25, // 偷窃经书
	"disrespect_buddhism": -15, // 轻慢佛法
}

// reputationGainRules 声望获取规则（武当）
var wudangGainRules = map[string]int{
	"join_discussion":       15, // 参与武当论道
	"complete_wudang_task":  20, // 完成武当弟子任务
	"protect_wudang_name":   10, // 维护武当名声
	"learn_taoism":          10, // 学习太极心法
}

var wudangLoseRules = map[string]int{
	"challenge_master_lose":   -20, // 挑战武当掌门落败
	"cause_trouble":           -15, // 在武当地盘制造麻烦
	"use_poison_vs_wudang":    -20, // 使用阴毒武功（针对武当NPC）
}

// reputationGainRules 声望获取规则（锦衣卫）
var jinyiweiGainRules = map[string]int{
	"complete_imperial_task": 20, // 完成朝廷任务
	"provide_intel":          10, // 提供江湖情报
	"capture_criminal":       15, // 抓捕通缉犯
	"obey_decree":            10, // 服从诏令
}

var jinyiweiLoseRules = map[string]int{
	"resist_court":   -50, // 反抗朝廷
	"attack_jinyiwei": -40, // 袭击锦衣卫
	"help_jianghu":   -25, // 帮助江湖门派
	"shield_criminal": -20, // 包庇罪犯
}

// reputationGainRules 声望获取规则（五毒教）
var wuduGainRules = map[string]int{
	"show_poison_knowledge": 15, // 展示毒术知识
	"cure_poisoned":        10, // 救治中毒者
	"help_miao_resident":   10, // 帮助苗疆居民
	"offer_rare_poison":    20, // 献上珍稀毒材
	"defeat_zhengpai":      15, // 击败正派人士
}

var wuduLoseRules = map[string]int{
	"despise_wudu":           -30, // 轻蔑五毒教
	"destroy_gu breeding":    -25, // 破坏蛊虫养殖
	"kill_miao_resident":     -20, // 杀苗疆居民
	"use_antidote_vs_wudu":   -15, // 使用解毒术对付五毒教
}

// reputationGainRules 声望获取规则（丐帮）
var gaibangGainRules = map[string]int{
	"drink_together":     5,  // 与丐帮弟子共饮
	"complete_renyi_task": 20, // 完成仁义任务
	"defend_poor":       10, // 为乞丐仗义执言
	"spread_gaibang_name": 10, // 传播丐帮侠名
	"begging_experience": 5,  // 行乞体验
}

var gaibangLoseRules = map[string]int{
	"bully_beggar":        -30, // 欺负乞丐
	"insult_gaibang_leader": -40, // 侮辱丐帮帮主
	"collude_official":   -25, // 与官府勾结
	"greed_unjust_money": -15, // 贪图不义之财
}

// GetReputationChange 获取声望变化（基于事件）
func GetReputationChange(factionID FactionID, eventType string, isGain bool) int {
	var rules map[string]int

	switch factionID {
	case FactionMingjiao:
		if isGain {
			rules = mingjiaoGainRules
		} else {
			rules = mingjiaoLoseRules
		}
	case FactionShaolin:
		if isGain {
			rules = shaolinGainRules
		} else {
			rules = shaolinLoseRules
		}
	case FactionWudang:
		if isGain {
			rules = wudangGainRules
		} else {
			rules = wudangLoseRules
		}
	case FactionJinyiwei:
		if isGain {
			rules = jinyiweiGainRules
		} else {
			rules = jinyiweiLoseRules
		}
	case FactionWudu:
		if isGain {
			rules = wuduGainRules
		} else {
			rules = wuduLoseRules
		}
	case FactionGaibang:
		if isGain {
			rules = gaibangGainRules
		} else {
			rules = gaibangLoseRules
		}
	default:
		return 0
	}

	if delta, ok := rules[eventType]; ok {
		return delta
	}
	return 0
}

// ApplyReputationChange 应用声望变化并返回新的声望值
func ApplyReputationChange(currentValue, delta int) int {
	newValue := currentValue + delta
	// 声望范围限制
	if newValue < -100 {
		newValue = -100
	}
	if newValue > 200 {
		newValue = 200 // 传说以上上限
	}
	return newValue
}

// CanChangeFaction 检查是否可以转换阵营
func CanChangeFaction(currentFaction, targetFaction FactionID, currentRep, targetRep int) (bool, string) {
	// 目标阵营声望需≥60，原阵营声望需≤20
	if targetRep < 60 {
		return false, "目标阵营声望不足（需要60以上）"
	}
	if currentRep > 20 {
		return false, "当前阵营声望过高（需要20以下才能叛门）"
	}
	// 不能叛门到对立阵营
	if IsHostile(currentFaction, targetFaction) {
		return false, "不能直接叛门到对立阵营"
	}
	return true, ""
}

// ChangeFactionCost 叛门代价
func ChangeFactionCost(originalFaction FactionID) ReputationDelta {
	return ReputationDelta{
		Mingjiao:  -100,
		Shaolin:   -100,
		Wudang:    -100,
		Jinyiwei:  -100,
		Wudu:      -100,
		Gaibang:   -100,
	}
}

// ReputationSystem 声望系统接口
type ReputationSystem interface {
	GetReputation(playerID string, factionID FactionID) int
	UpdateReputation(playerID string, factionID FactionID, delta int) (int, error)
	GetReputationLevel(value int) ReputationLevel
}

// SimpleReputationSystem 简单声望系统实现
type SimpleReputationSystem struct {
	// 玩家阵营声望存储 (playerID -> (factionID -> reputation))
	playerReputations map[string]map[FactionID]int
}

// NewSimpleReputationSystem 创建声望系统
func NewSimpleReputationSystem() *SimpleReputationSystem {
	return &SimpleReputationSystem{
		playerReputations: make(map[string]map[FactionID]int),
	}
}

// GetReputation 获取玩家在某个阵营的声望
func (s *SimpleReputationSystem) GetReputation(playerID string, factionID FactionID) int {
	if playerMap, ok := s.playerReputations[playerID]; ok {
		if rep, ok := playerMap[factionID]; ok {
			return rep
		}
	}
	return 0
}

// UpdateReputation 更新声望
func (s *SimpleReputationSystem) UpdateReputation(playerID string, factionID FactionID, delta int) (int, error) {
	if _, ok := s.playerReputations[playerID]; !ok {
		s.playerReputations[playerID] = make(map[FactionID]int)
	}

	current := s.GetReputation(playerID, factionID)
	newValue := ApplyReputationChange(current, delta)
	s.playerReputations[playerID][factionID] = newValue

	return newValue, nil
}

// GetAllReputations 获取玩家所有阵营声望
func (s *SimpleReputationSystem) GetAllReputations(playerID string) map[FactionID]int {
	result := make(map[FactionID]int)
	for _, f := range AllFactions {
		result[f.ID] = s.GetReputation(playerID, f.ID)
	}
	return result
}

// SetInitialReputation 设置初始声望（玩家加入阵营时）
func (s *SimpleReputationSystem) SetInitialReputation(playerID string, factionID FactionID) {
	if _, ok := s.playerReputations[playerID]; !ok {
		s.playerReputations[playerID] = make(map[FactionID]int)
	}
	// 加入的阵营初始声望100，其他阵营0
	for _, f := range AllFactions {
		if f.ID == factionID {
			s.playerReputations[playerID][f.ID] = 100
		} else {
			s.playerReputations[playerID][f.ID] = 0
		}
	}
}

// PlayerReputationData 玩家声望数据（用于存储到Player模型）
type PlayerReputationData struct {
	Mingjiao  int `json:"mingjiao"`  // 明教
	Shaolin   int `json:"shaolin"`   // 少林
	Wudang    int `json:"wudang"`    // 武当
	Jinyiwei  int `json:"jinyiwei"`  // 锦衣卫
	Wudu      int `json:"wudu"`      // 五毒教
	Gaibang   int `json:"gaibang"`   // 丐帮
}

// ToMap 转换为map
func (p PlayerReputationData) ToMap() map[FactionID]int {
	return map[FactionID]int{
		FactionMingjiao:  p.Mingjiao,
		FactionShaolin:   p.Shaolin,
		FactionWudang:    p.Wudang,
		FactionJinyiwei:  p.Jinyiwei,
		FactionWudu:      p.Wudu,
		FactionGaibang:   p.Gaibang,
	}
}

// FromPlayerModel 从Player模型构建
func FromPlayerModel(rep model.Reputation) PlayerReputationData {
	return PlayerReputationData{
		Mingjiao:  rep.Mingjiao,
		Shaolin:   rep.Zhengpai, // 少林用zhengpai字段
		Wudang:    0,            // 武当需要单独字段或复用
		Jinyiwei:  rep.Jinyiwei,
		Wudu:      0,            // 五毒教需要单独字段
		Gaibang:   0,            // 丐帮需要单独字段
	}
}
