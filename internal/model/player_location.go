package model

import "time"

// PlayerLocation 玩家位置追踪
type PlayerLocation struct {
	PlayerID         string   `json:"player_id"`
	CurrentLocation  string   `json:"current_location"`  // location ID
	CurrentRegion    string   `json:"current_region"`   // region ID
	InBattle         bool     `json:"in_battle"`
	VisitedLocations []string `json:"visited_locations"` // 已访问的场景ID
	VisitedRegions   []string `json:"visited_regions"`  // 已访问的大区ID
	TotalTravelCount int      `json:"total_travel_count"`
	UnlockedLocations []string `json:"unlocked_locations"` // 已解锁的场景ID
	StoryProgress    map[string]int `json:"story_progress"` // 章节进度
	UpdatedAt        time.Time `json:"updated_at"`
	CreatedAt        time.Time `json:"created_at"`
}

// NewPlayerLocation 创建玩家位置记录
func NewPlayerLocation(playerID, locationID, regionID string) *PlayerLocation {
	return &PlayerLocation{
		PlayerID:          playerID,
		CurrentLocation:   locationID,
		CurrentRegion:     regionID,
		InBattle:          false,
		VisitedLocations:  []string{locationID},
		VisitedRegions:    []string{regionID},
		TotalTravelCount:  0,
		UnlockedLocations: []string{locationID},
		StoryProgress:     make(map[string]int),
		UpdatedAt:         time.Now(),
		CreatedAt:         time.Now(),
	}
}

// AddVisited 添加已访问记录
func (p *PlayerLocation) AddVisited(locationID, regionID string) {
	for _, loc := range p.VisitedLocations {
		if loc == locationID {
			return
		}
	}
	p.VisitedLocations = append(p.VisitedLocations, locationID)

	for _, reg := range p.VisitedRegions {
		if reg == regionID {
			return
		}
	}
	p.VisitedRegions = append(p.VisitedRegions, regionID)
}

// UnlockLocation 解锁场景
func (p *PlayerLocation) UnlockLocation(locationID string) {
	for _, loc := range p.UnlockedLocations {
		if loc == locationID {
			return
		}
	}
	p.UnlockedLocations = append(p.UnlockedLocations, locationID)
}

// IsLocationUnlocked 检查场景是否已解锁
func (p *PlayerLocation) IsLocationUnlocked(locationID string) bool {
	for _, loc := range p.UnlockedLocations {
		if loc == locationID {
			return true
		}
	}
	return false
}
