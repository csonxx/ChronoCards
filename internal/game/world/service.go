package world

import (
	"fmt"
	"math/rand"

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

// GetWorldOverview 获取世界概览
func (s *Service) GetWorldOverview() *WorldOverview {
	available := 0
	for _, loc := range MVPLocations {
		if loc.Unlocked {
			available++
		}
	}
	return &WorldOverview{
		WorldArc:            "mingjiao_rising",
		ActiveEvents:        []string{},
		Regions:             MVPRegions,
		TotalLocations:      len(MVPLocations),
		AvailableLocations:   available,
	}
}

// GetLocations 获取场景列表
func (s *Service) GetLocations(filter *LocationFilter) []*Location {
	results := make([]*Location, 0)
	for _, loc := range MVPLocations {
		if filter != nil {
			if filter.UnlockedOnly && !loc.Unlocked {
				continue
			}
			if filter.Type != "" && loc.LocationType != filter.Type {
				continue
			}
			if filter.RegionID != "" && loc.RegionID != filter.RegionID {
				continue
			}
		}
		results = append(results, loc)
	}
	return results
}

// GetLocation 获取单个场景
func (s *Service) GetLocation(id string) *Location {
	return GetLocationByID(id)
}

// GetLocationConnections 获取场景连通性
func (s *Service) GetLocationConnections(locationID string) []*LocationConnection {
	results := make([]*LocationConnection, 0)
	for _, conn := range MVPConnections {
		if conn.FromLocation == locationID {
			results = append(results, conn)
		}
	}
	return results
}

// GetPlayerLocation 获取玩家位置数据
func (s *Service) GetPlayerLocation(playerID string) *model.PlayerLocation {
	pl, err := s.store.GetPlayerLocation(playerID)
	if err == nil && pl != nil {
		return pl
	}
	newPl := model.NewPlayerLocation(playerID, "loc-pingyang", "region-central-plains")
	newPl.UnlockedLocations = []string{"loc-pingyang", "loc-zhongyuan-wilds", "loc-inn-anchor"}
	return newPl
}

// CanNavigate 检查是否可导航
func (s *Service) CanNavigate(fromID, toID string) (bool, string) {
	from := GetLocationByID(fromID)
	to := GetLocationByID(toID)
	if from == nil || to == nil {
		return false, "场景不存在"
	}
	if !to.Unlocked {
		return false, fmt.Sprintf("场景未解锁（需：%s）", to.UnlockCondition)
	}
	for _, conn := range MVPConnections {
		if conn.FromLocation == fromID && conn.ToLocation == toID && conn.Unlocked {
			return true, "可达"
		}
	}
	return false, "两场景之间无直接路径"
}

// ProcessNavigation 处理导航请求
func (s *Service) ProcessNavigation(playerID, targetLocationID string) *NavigateResult {
	playerData := s.GetPlayerLocation(playerID)
	fromID := playerData.CurrentLocation

	canNav, reason := s.CanNavigate(fromID, targetLocationID)
	if !canNav {
		return &NavigateResult{Success: false, Message: reason}
	}

	encounterTriggered := false
	encounterType := ""
	for _, conn := range MVPConnections {
		if conn.FromLocation == fromID && conn.ToLocation == targetLocationID {
			if conn.EncounterRate > 0 && rand.Float64() < conn.EncounterRate {
				encounterTriggered = true
				encounterType = pickEncounterType(conn.DangerLevel)
			}
			playerData.TotalTravelCount++
			break
		}
	}

	playerData.CurrentLocation = targetLocationID
	playerData.VisitedLocations = appendVisited(playerData.VisitedLocations, targetLocationID)
	s.store.SetPlayerLocation(playerID, targetLocationID)

	newLoc := GetLocationByID(targetLocationID)
	return &NavigateResult{
		Success:            true,
		FromLocationID:     fromID,
		ToLocationID:       targetLocationID,
		EncounterTriggered:  encounterTriggered,
		EncounterType:      encounterType,
		Message:            fmt.Sprintf("抵达%s", newLoc.Name),
		NewLocation:        newLoc,
	}
}

func pickEncounterType(dangerLevel int) string {
	r := rand.Float64()
	if dangerLevel >= 4 {
		if r < 0.5 {
			return "enemy"
		}
		return "event"
	}
	if r < 0.3 {
		return "enemy"
	}
	if r < 0.6 {
		return "treasure"
	}
	if r < 0.8 {
		return "npc"
	}
	return "event"
}

func appendVisited(list []string, item string) []string {
	for _, v := range list {
		if v == item {
			return list
		}
	}
	return append(list, item)
}
