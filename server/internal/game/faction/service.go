package faction

import (
	"errors"
	"sync"

	"github.com/csonxx/ChronoCards/server/internal/model"
	"github.com/csonxx/ChronoCards/server/internal/store"
)

// Service 阵营服务
type Service struct {
	store          store.StoreInterface
	repSystem      *SimpleReputationSystem
	killIntents    map[string]map[FactionID]int // playerID -> factionID -> killIntent
	mu             sync.RWMutex
}

// NewService 创建阵营服务
func NewService(s store.StoreInterface) *Service {
	return &Service{
		store:       s,
		repSystem:   NewSimpleReputationSystem(),
		killIntents: make(map[string]map[FactionID]int),
	}
}

// GetFaction 获取阵营信息
func (s *Service) GetFaction(factionID FactionID) *Faction {
	return GetFactionByID(factionID)
}

// ListAllFactions 获取所有阵营
func (s *Service) ListAllFactions() []Faction {
	return AllFactions
}

// GetRelation 获取两个阵营的关系
func (s *Service) GetRelation(a, b FactionID) RelationType {
	return GetRelation(a, b)
}

// IsHostile 判断是否对立
func (s *Service) IsHostile(a, b FactionID) bool {
	return IsHostile(a, b)
}

// IsAlliance 判断是否联盟
func (s *Service) IsAlliance(a, b FactionID) bool {
	return IsAlliance(a, b)
}

// PlayerFactionInfo 玩家阵营信息
type PlayerFactionInfo struct {
	PlayerID       string            `json:"player_id"`
	CurrentFaction FactionID         `json:"current_faction"`
	Reputations    map[FactionID]int  `json:"reputations"`
	KillIntents    map[FactionID]int  `json:"kill_intents"`
	Relations      map[FactionID]RelationType `json:"relations"` // 与各阵营的关系
}

// GetPlayerFactionInfo 获取玩家阵营信息
func (s *Service) GetPlayerFactionInfo(playerID string) (*PlayerFactionInfo, error) {
	player, ok := s.store.GetPlayer(playerID)
	if !ok {
		return nil, errors.New("player not found")
	}

	factionID := FactionID(player.Faction)
	info := &PlayerFactionInfo{
		PlayerID:       playerID,
		CurrentFaction: factionID,
		Reputations:    make(map[FactionID]int),
		KillIntents:    s.getKillIntents(playerID),
		Relations:      make(map[FactionID]RelationType),
	}

	// 获取声望（从Player模型的Reputation字段）
	info.Reputations[FactionMingjiao] = player.Reputation.Mingjiao
	info.Reputations[FactionShaolin] = player.Reputation.Zhengpai // 少林用zhengpai字段
	info.Reputations[FactionWudang] = 0
	info.Reputations[FactionJinyiwei] = player.Reputation.Jinyiwei
	info.Reputations[FactionWudu] = 0
	info.Reputations[FactionGaibang] = 0

	// 构建与各阵营的关系
	for _, f := range AllFactions {
		info.Relations[f.ID] = GetRelation(factionID, f.ID)
	}

	return info, nil
}

// ReputationInfo 声望信息
type ReputationInfo struct {
	FactionID   FactionID `json:"faction_id"`
	FactionName string    `json:"faction_name"`
	Value       int       `json:"value"`
	Level       ReputationLevel `json:"level"`
	LevelName   string    `json:"level_name"`
	NPCTitle    string    `json:"npc_title"`
	NPCAttitude string    `json:"npc_attitude"`
	CanEnter    bool      `json:"can_enter"`
	Discount    float64   `json:"discount"`
}

// GetPlayerReputations 获取玩家所有阵营声望
func (s *Service) GetPlayerReputations(playerID string) ([]ReputationInfo, error) {
	player, ok := s.store.GetPlayer(playerID)
	if !ok {
		return nil, errors.New("player not found")
	}

	// 从Player模型获取声望
	reps := map[FactionID]int{
		FactionMingjiao:  player.Reputation.Mingjiao,
		FactionShaolin:   player.Reputation.Zhengpai,
		FactionWudang:    0,
		FactionJinyiwei:  player.Reputation.Jinyiwei,
		FactionWudu:      0,
		FactionGaibang:   0,
	}

	var result []ReputationInfo
	for _, f := range AllFactions {
		val := reps[f.ID]
		levelInfo := GetReputationLevelInfo(val)
		result = append(result, ReputationInfo{
			FactionID:    f.ID,
			FactionName:  f.Name,
			Value:        val,
			Level:        levelInfo.Level,
			LevelName:    levelInfo.Name,
			NPCTitle:     levelInfo.NPCTitle,
			NPCAttitude:  levelInfo.NPCAttitude,
			CanEnter:     levelInfo.CanEnter,
			Discount:     levelInfo.Discount,
		})
	}

	return result, nil
}

// UpdateReputationRequest 更新声望请求
type UpdateReputationRequest struct {
	FactionID    FactionID `json:"faction_id"`
	Delta        int       `json:"delta"`
	EventType    string    `json:"event_type,omitempty"` // 可选的事件类型
	Reason       string    `json:"reason,omitempty"`
}

// UpdateReputationResponse 更新声望响应
type UpdateReputationResponse struct {
	FactionID   FactionID `json:"faction_id"`
	OldValue    int       `json:"old_value"`
	NewValue    int       `json:"new_value"`
	Delta       int       `json:"delta"`
	Level       ReputationLevel `json:"level"`
	LevelName   string    `json:"level_name"`
}

// UpdateReputation 更新玩家声望
func (s *Service) UpdateReputation(playerID string, req *UpdateReputationRequest) (*UpdateReputationResponse, error) {
	player, ok := s.store.GetPlayer(playerID)
	if !ok {
		return nil, errors.New("player not found")
	}

	var oldValue int
	// fieldName removed

	switch req.FactionID {
	case FactionMingjiao:
		oldValue = player.Reputation.Mingjiao
	case FactionShaolin:
		oldValue = player.Reputation.Zhengpai
	case FactionWudang:
		// 武当暂时没有独立字段
		oldValue = 0
	case FactionJinyiwei:
		oldValue = player.Reputation.Jinyiwei
	case FactionWudu:
		// 五毒教暂时没有独立字段
		oldValue = 0
	case FactionGaibang:
		// 丐帮暂时没有独立字段
		oldValue = 0
	default:
		return nil, errors.New("invalid faction id")
	}

	// 计算新值
	newValue := ApplyReputationChange(oldValue, req.Delta)

	// 更新Player模型
	switch req.FactionID {
	case FactionMingjiao:
		player.Reputation.Mingjiao = newValue
	case FactionShaolin:
		player.Reputation.Zhengpai = newValue
	case FactionJinyiwei:
		player.Reputation.Jinyiwei = newValue
	}

	s.store.UpdatePlayer(player)

	levelInfo := GetReputationLevelInfo(newValue)

	return &UpdateReputationResponse{
		FactionID: req.FactionID,
		OldValue:  oldValue,
		NewValue:  newValue,
		Delta:     req.Delta,
		Level:     levelInfo.Level,
		LevelName: levelInfo.Name,
	}, nil
}

// JoinFactionRequest 加入阵营请求
type JoinFactionRequest struct {
	FactionID FactionID `json:"faction_id"`
}

// JoinFaction 加入阵营
func (s *Service) JoinFaction(playerID string, req *JoinFactionRequest) (*PlayerFactionInfo, error) {
	player, ok := s.store.GetPlayer(playerID)
	if !ok {
		return nil, errors.New("player not found")
	}

	// 检查是否是有效的阵营
	faction := GetFactionByID(req.FactionID)
	if faction == nil {
		return nil, errors.New("invalid faction id")
	}

	// 更新玩家阵营
	player.Faction = string(req.FactionID)

	// 设置初始声望（加入的阵营100，其他阵营0）
	player.Reputation = model.Reputation{}
	switch req.FactionID {
	case FactionMingjiao:
		player.Reputation.Mingjiao = 100
	case FactionShaolin:
		player.Reputation.Zhengpai = 100
	case FactionJinyiwei:
		player.Reputation.Jinyiwei = 100
	// 其他阵营暂不设置独立字段
	}

	s.store.UpdatePlayer(player)

	// 初始化杀意值
	s.initKillIntents(playerID)

	return s.GetPlayerFactionInfo(playerID)
}

// KillIntentRequest 更新杀意值请求
type KillIntentRequest struct {
	FactionID  FactionID `json:"faction_id"`
	Delta      int       `json:"delta"`
	EventType  string    `json:"event_type,omitempty"` // kill/assist/task/death/surrender
}

// KillIntentResponse 杀意值响应
type KillIntentResponse struct {
	FactionID      FactionID        `json:"faction_id"`
	OldValue       int              `json:"old_value"`
	NewValue       int              `json:"new_value"`
	Delta          int              `json:"delta"`
	Level          KillIntentLevel  `json:"level"`
	AttackBonus    float64          `json:"attack_bonus"`
	DefenseBonus   float64          `json:"defense_bonus"`
	CanAnnihilate  bool             `json:"can_annihilate"` // 是否可灭门
	IsWanted       bool             `json:"is_wanted"`      // 是否被悬赏
}

// getKillIntents 获取玩家杀意值
func (s *Service) getKillIntents(playerID string) map[FactionID]int {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if factionMap, ok := s.killIntents[playerID]; ok {
		return factionMap
	}
	return make(map[FactionID]int)
}

// initKillIntents 初始化杀意值
func (s *Service) initKillIntents(playerID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.killIntents[playerID]; !ok {
		s.killIntents[playerID] = make(map[FactionID]int)
	}
}

// UpdateKillIntent 更新杀意值
func (s *Service) UpdateKillIntent(playerID string, req *KillIntentRequest) (*KillIntentResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// 初始化杀意值映射
	if _, ok := s.killIntents[playerID]; !ok {
		s.killIntents[playerID] = make(map[FactionID]int)
	}

	oldValue := s.killIntents[playerID][req.FactionID]
	newValue := oldValue + req.Delta

	// 杀意值范围限制
	if newValue < 0 {
		newValue = 0
	}
	if newValue > 150 { // 悬赏上限
		newValue = 150
	}

	s.killIntents[playerID][req.FactionID] = newValue

	// 计算加成
	attackBonus, defenseBonus := GetKillIntentBonus(newValue)
	level := GetKillIntentLevel(newValue)

	return &KillIntentResponse{
		FactionID:    req.FactionID,
		OldValue:     oldValue,
		NewValue:     newValue,
		Delta:        req.Delta,
		Level:        level,
		AttackBonus:  attackBonus,
		DefenseBonus: defenseBonus,
		CanAnnihilate: level >= KillIntentExtreme,
		IsWanted:     level >= KillIntentWanted,
	}, nil
}

// GetFactionCards 获取阵营卡牌
func (s *Service) GetFactionCards(factionID FactionID, playerLevel int) []FactionCardDef {
	return GetUnlockedCards(factionID, playerLevel)
}

// FactionEventTrigger 阵营事件触发检查
type FactionEventTrigger struct {
	EventType   string     `json:"event_type"`
	FactionID   FactionID  `json:"faction_id"`
	Triggered  bool       `json:"triggered"`
	Effect     string     `json:"effect"`
	BattleBonus float64   `json:"battle_bonus"`
}

// CheckTrigger 检查是否触发阵营对抗事件
func (s *Service) CheckTrigger(playerID string, eventType string, targetFactionID FactionID) (*FactionEventTrigger, error) {
	player, ok := s.store.GetPlayer(playerID)
	if !ok {
		return nil, errors.New("player not found")
	}

	playerFaction := FactionID(player.Faction)
	relation := GetRelation(playerFaction, targetFactionID)

	result := &FactionEventTrigger{
		EventType:  eventType,
		FactionID:  targetFactionID,
		Triggered:  false,
		BattleBonus: 1.0,
	}

	// 根据事件类型和关系判断是否触发
	switch eventType {
	case "encounter":
		// 遭遇触发：只有对立关系才会触发
		if relation == RelationHostile {
			result.Triggered = true
			result.Effect = "阵营遭遇战"
			result.BattleBonus = 1.1 // 击杀获得额外10%经验
		}
	case "kill":
		// 击杀触发
		if relation == RelationHostile {
			result.Triggered = true
			result.Effect = "击杀对立阵营获得额外杀意值"
			result.BattleBonus = 1.2
		}
	case "task":
		// 任务触发
		result.Triggered = true
		result.Effect = "阵营任务进行中"
		result.BattleBonus = 1.0
	case "area":
		// 区域触发
		result.Triggered = true
		result.Effect = "进入势力范围"
		result.BattleBonus = 1.0
	}

	return result, nil
}

// GetAllianceMembers 获取联盟成员
func (s *Service) GetAllianceMembers(factionID FactionID) []FactionID {
	var members []FactionID
	for _, f := range AllFactions {
		if f.ID != factionID && IsAlliance(factionID, f.ID) {
			members = append(members, f.ID)
		}
	}
	return members
}

// GetHostileFactions 获取敌对阵营
func (s *Service) GetHostileFactions(factionID FactionID) []FactionID {
	var hostiles []FactionID
	for _, f := range AllFactions {
		if f.ID != factionID && IsHostile(factionID, f.ID) {
			hostiles = append(hostiles, f.ID)
		}
	}
	return hostiles
}

// ApplyFactionEvent 应用阵营事件（更新声望、杀意值等）
func (s *Service) ApplyFactionEvent(playerID string, event *FactionReputationEvent) error {
	// 更新声望
	_, err := s.UpdateReputation(playerID, &UpdateReputationRequest{
		FactionID: event.Faction,
		Delta:     event.Delta,
		Reason:    event.Reason,
	})
	if err != nil {
		return err
	}

	// 如果是敌对行为，增加杀意值
	if event.AntiFaction != "" {
		_, err = s.UpdateKillIntent(playerID, &KillIntentRequest{
			FactionID: event.AntiFaction,
			Delta:     10, // 敌对行为增加10点杀意
			EventType: event.Type,
		})
		if err != nil {
			return err
		}
	}

	return nil
}
