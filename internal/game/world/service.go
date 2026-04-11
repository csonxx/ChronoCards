package world

import (
	"errors"
	"math/rand"
	"time"

	"github.com/csonxx/ChronoCards/internal/model"
	"github.com/csonxx/ChronoCards/internal/store"
)

// Service 世界地图服务
type Service struct {
	store store.StoreInterface
}

// NewService 创建世界地图服务
func NewService(s store.StoreInterface) *Service {
	return &Service{store: s}
}

// GetWorldOverview 返回世界概览
func (s *Service) GetWorldOverview() (*WorldOverview, error) {
	overview := &WorldOverview{
		WorldArc:     "mingjiao_rising",
		ActiveEvents: []string{},
		Regions:      make([]*Region, 0),
	}

	for i := range MVPRegions {
		overview.Regions = append(overview.Regions, &MVPRegions[i])
	}

	totalLocations := len(MVPLocations)
	availableLocations := 0
	for _, loc := range MVPLocations {
		if loc.Unlocked {
			availableLocations++
		}
	}

	overview.TotalLocations = totalLocations
	overview.AvailableLocations = availableLocations

	return overview, nil
}

// GetLocations 筛选获取场景列表
func (s *Service) GetLocations(filter LocationFilter) ([]*Location, error) {
	result := make([]*Location, 0)

	for i := range MVPLocations {
		loc := &MVPLocations[i]

		// 筛选类型
		if filter.Type != "" && loc.LocationType != filter.Type {
			continue
		}

		// 筛选大区
		if filter.RegionID != "" && loc.RegionID != filter.RegionID {
			continue
		}

		// 筛选已解锁
		if filter.UnlockedOnly && !loc.Unlocked {
			// 进一步检查玩家是否解锁
			// 注意：这里需要玩家上下文，但筛选时不依赖玩家
			continue
		}

		result = append(result, loc)
	}

	return result, nil
}

// GetLocation 获取单个场景
func (s *Service) GetLocation(id string) (*Location, error) {
	for i := range MVPLocations {
		if MVPLocations[i].ID == id {
			return &MVPLocations[i], nil
		}
	}
	return nil, errors.New("location not found")
}

// GetLocationByID 根据ID获取场景（内部使用）
func (s *Service) GetLocationByID(id string) *Location {
	for i := range MVPLocations {
		if MVPLocations[i].ID == id {
			return &MVPLocations[i]
		}
	}
	return nil
}

// GetRegion 获取大区
func (s *Service) GetRegion(id string) *Region {
	for i := range MVPRegions {
		if MVPRegions[i].ID == id {
			return &MVPRegions[i]
		}
	}
	return nil
}

// GetLocationConnections 获取场景连通性
func (s *Service) GetLocationConnections(locationID string) ([]*LocationConnection, error) {
	connections := make([]*LocationConnection, 0)

	for i := range MVPConnections {
		conn := &MVPConnections[i]
		
		// 检查是否匹配from_location或to_location（双向）
		if conn.FromLocation == locationID || conn.ToLocation == locationID {
			// 填充目标场景数据
			toLocID := conn.ToLocation
			if conn.FromLocation == locationID {
				toLocID = conn.ToLocation
			} else {
				toLocID = conn.FromLocation
			}
			conn.ToLocationData = s.GetLocationByID(toLocID)
			connections = append(connections, conn)
		}
	}

	return connections, nil
}

// CanNavigate 验证两个场景是否连通
func (s *Service) CanNavigate(from, to string) (bool, string) {
	// 目标场景必须存在
	targetLoc := s.GetLocationByID(to)
	if targetLoc == nil {
		return false, "目标场景不存在"
	}

	// 目标场景必须已解锁
	if !targetLoc.Unlocked {
		return false, "目标场景未解锁，需要: " + targetLoc.UnlockCondition
	}

	// 查找连通性
	for i := range MVPConnections {
		conn := &MVPConnections[i]
		
		// 检查连接是否从from出发
		if conn.FromLocation != from {
			continue
		}

		// 检查目标是否匹配
		if conn.ToLocation != to {
			continue
		}

		// 检查连接是否解锁
		if !conn.Unlocked {
			return false, "该路径未解锁，需要: " + conn.UnlockCondition
		}

		// teleport类型无需路径验证
		if conn.ConnectionType == "teleport" {
			return true, "快速旅行"
		}

		return true, "路径可达"
	}

	return false, "两个场景之间没有直接路径"
}

// ProcessNavigation 处理导航请求
func (s *Service) ProcessNavigation(playerID, targetLocationID string, skipEncounter bool) (*NavigateResult, error) {
	result := &NavigateResult{}

	// 获取玩家当前位置
	playerLoc, err := s.store.GetPlayerLocation(playerID)
	if err != nil {
		// 如果玩家没有位置记录，初始化为平阳城
		playerLoc = model.NewPlayerLocation(playerID, "loc-pingyang", "region-central-plains")
		s.store.SetPlayerLocation(playerID, "loc-pingyang")
	}

	currentLocationID := playerLoc.CurrentLocation
	currentLocation := s.GetLocationByID(currentLocationID)
	if currentLocation == nil {
		return nil, errors.New("玩家当前位置数据异常")
	}

	targetLocation := s.GetLocationByID(targetLocationID)
	if targetLocation == nil {
		return nil, errors.New("目标场景不存在")
	}

	// 验证连通性
	canNav, reason := s.CanNavigate(currentLocationID, targetLocationID)
	if !canNav {
		return nil, errors.New(reason)
	}

	// 查找连接信息获取travel_time和encounter_rate
	var connection *LocationConnection
	for i := range MVPConnections {
		conn := &MVPConnections[i]
		if conn.FromLocation == currentLocationID && conn.ToLocation == targetLocationID {
			connection = conn
			break
		}
	}

	if connection == nil {
		return nil, errors.New("无法找到连接信息")
	}

	// 随机遭遇判定
	encounterTriggered := false
	encounterType := "none"
	
	if !skipEncounter && connection.EncounterRate > 0 {
		r := rand.Float64()
		if r < connection.EncounterRate {
			encounterTriggered = true
			// 随机决定遭遇类型
			encounterRoll := rand.Float64()
			if encounterRoll < 0.5 {
				encounterType = "enemy"
			} else if encounterRoll < 0.7 {
				encounterType = "treasure"
			} else if encounterRoll < 0.9 {
				encounterType = "npc"
			} else {
				encounterType = "event"
			}
		}
	}

	// 更新玩家位置
	err = s.store.SetPlayerLocation(playerID, targetLocationID)
	if err != nil {
		return nil, err
	}

	// 添加到已访问
	s.store.AddVisited(playerID, targetLocationID)

	// 检查是否解锁了新场景
	var unlockReward *UnlockReward
	// 根据解锁条件检查
	switch targetLocation.UnlockCondition {
	case "unlock_ch1_complete":
		// ch1完成后解锁武当山
		if !s.GetLocationByID("loc-wudang").Unlocked {
			s.UnlockLocation("loc-wudang")
			unlockReward = &UnlockReward{
				UnlockedLocationID:   "loc-wudang",
				UnlockedLocationName:  "武当山",
				Message:              "完成第一章！武当山已解锁",
			}
		}
	case "unlock_ch2_complete":
		// ch2完成后解锁少林寺
		if !s.GetLocationByID("loc-shaolin").Unlocked {
			s.UnlockLocation("loc-shaolin")
			unlockReward = &UnlockReward{
				UnlockedLocationID:   "loc-shaolin",
				UnlockedLocationName:  "少林寺",
				Message:              "完成第二章！少林寺已解锁",
			}
		}
	case "unlock_final_battle":
		// 最终战解锁光明顶
		if !s.GetLocationByID("loc-guangming").Unlocked {
			s.UnlockLocation("loc-guangming")
			unlockReward = &UnlockReward{
				UnlockedLocationID:   "loc-guangming",
				UnlockedLocationName:  "光明顶",
				Message:              "触发最终剧情！光明顶已解锁",
			}
		}
	}

	// 构建结果
	result.Success = true
	result.FromLocation = currentLocation
	result.ToLocation = targetLocation
	result.EncounterTriggered = encounterTriggered
	result.EncounterType = encounterType
	result.TravelTimeMin = connection.TravelTimeMin
	result.DangerEncountered = connection.DangerLevel >= 3
	result.Message = "导航成功"
	result.NewLocation = targetLocation
	result.UnlockReward = unlockReward

	return result, nil
}

// UnlockLocation 解锁场景（内部使用）
func (s *Service) UnlockLocation(locationID string) {
	for i := range MVPLocations {
		if MVPLocations[i].ID == locationID {
			MVPLocations[i].Unlocked = true
			break
		}
	}
	// 同时解锁相关连接
	for i := range MVPConnections {
		if MVPConnections[i].ToLocation == locationID {
			MVPConnections[i].Unlocked = true
		}
		if MVPConnections[i].FromLocation == locationID && MVPConnections[i].IsBidirectional {
			MVPConnections[i].Unlocked = true
		}
	}
}

// GetPlayerLocation 获取玩家位置
func (s *Service) GetPlayerLocation(playerID string) (*model.PlayerLocation, error) {
	return s.store.GetPlayerLocation(playerID)
}

// SetPlayerLocation 直接设置玩家位置（GM用）
func (s *Service) SetPlayerLocation(playerID, locationID string) error {
	loc := s.GetLocationByID(locationID)
	if loc == nil {
		return errors.New("location not found")
	}
	return s.store.SetPlayerLocation(playerID, locationID)
}

// GetPlayerVisited 获取玩家已访问的场景
func (s *Service) GetPlayerVisited(playerID string) ([]*Location, error) {
	playerLoc, err := s.store.GetPlayerLocation(playerID)
	if err != nil {
		// 如果没有记录，返回空
		return []*Location{}, nil
	}

	result := make([]*Location, 0)
	for _, locID := range playerLoc.VisitedLocations {
		loc := s.GetLocationByID(locID)
		if loc != nil {
			result = append(result, loc)
		}
	}

	return result, nil
}

// GetPlayerUnlockedLocations 获取玩家已解锁的场景
func (s *Service) GetPlayerUnlockedLocations(playerID string) ([]*Location, error) {
	playerLoc, err := s.store.GetPlayerLocation(playerID)
	if err != nil {
		// 如果没有记录，只返回默认解锁的场景
		result := make([]*Location, 0)
		for i := range MVPLocations {
			if MVPLocations[i].Unlocked {
				result = append(result, &MVPLocations[i])
			}
		}
		return result, nil
	}

	result := make([]*Location, 0)
	for _, locID := range playerLoc.UnlockedLocations {
		loc := s.GetLocationByID(locID)
		if loc != nil {
			result = append(result, loc)
		}
	}

	return result, nil
}

// GetLocationsByType 根据类型获取场景
func (s *Service) GetLocationsByType(locationType string) []*Location {
	result := make([]*Location, 0)
	for i := range MVPLocations {
		if MVPLocations[i].LocationType == locationType {
			result = append(result, &MVPLocations[i])
		}
	}
	return result
}

// GetInnLocations 获取所有客栈场景
func (s *Service) GetInnLocations() []*Location {
	return s.GetLocationsByType("inn")
}

func init() {
	rand.Seed(time.Now().UnixNano())
}
