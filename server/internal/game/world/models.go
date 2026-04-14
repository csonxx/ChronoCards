package world

// Region 大区
type Region struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	DisplayOrder  int      `json:"display_order"`
	Description  string   `json:"description"`
	Climate       string   `json:"climate,omitempty"`
	Terrain      string   `json:"terrain,omitempty"`
	DangerLevel  int      `json:"danger_level"`
	Tags         []string `json:"tags,omitempty"`
	StoryIntro   string   `json:"story_intro,omitempty"`
}

// Location 场景
type Location struct {
	ID               string   `json:"id"`
	Name             string   `json:"name"`
	DisplayOrder     int      `json:"display_order"`
	RegionID         string   `json:"region_id"`
	LocationType     string   `json:"location_type"`
	LocationTypeExt  string   `json:"location_type_ext,omitempty"`
	Description     string   `json:"description"`
	Atmosphere      string   `json:"atmosphere,omitempty"`
	DangerLevel     int      `json:"danger_level"`
	NPCCount        int      `json:"npc_count"`
	AvailableDealers []string `json:"available_dealers,omitempty"`
	StoryChapters   []string `json:"story_chapters,omitempty"`
	Tags            []string `json:"tags,omitempty"`
	Unlocked        bool     `json:"unlocked"`
	UnlockCondition string   `json:"unlock_condition,omitempty"`
	SceneBG         string   `json:"scene_bg,omitempty"`
	MusicTrack      string   `json:"music_track,omitempty"`
}

// LocationConnection 场景连通性
type LocationConnection struct {
	ID             string  `json:"id"`
	FromLocation   string  `json:"from_location"`
	ToLocation     string  `json:"to_location"`
	ConnectionType string  `json:"connection_type"`
	TravelTimeMin  int     `json:"travel_time_min"`
	DangerLevel   int     `json:"danger_level"`
	EncounterRate  float64 `json:"encounter_rate"`
	Description   string  `json:"description,omitempty"`
	Unlocked      bool    `json:"unlocked"`
}

// WorldOverview 世界概览
type WorldOverview struct {
	WorldArc            string     `json:"world_arc"`
	ActiveEvents        []string   `json:"active_events"`
	Regions             []*Region  `json:"regions"`
	TotalLocations      int        `json:"total_locations"`
	AvailableLocations int        `json:"available_locations"`
}

// LocationFilter 场景筛选
type LocationFilter struct {
	Type         string
	RegionID     string
	UnlockedOnly bool
}

// PlayerLocationData 玩家位置数据
type PlayerLocationData struct {
	PlayerID          string   `json:"player_id"`
	CurrentLocationID string   `json:"current_location_id"`
	CurrentRegionID   string   `json:"current_region_id"`
	VisitedLocations  []string `json:"visited_locations"`
	VisitedRegions   []string `json:"visited_regions"`
	UnlockedLocations []string `json:"unlocked_locations"`
	TotalTravelCount int      `json:"total_travel_count"`
}

// NavigateResult 导航结果
type NavigateResult struct {
	Success            bool      `json:"success"`
	FromLocationID     string    `json:"from_location_id"`
	ToLocationID       string    `json:"to_location_id"`
	EncounterTriggered bool      `json:"encounter_triggered"`
	EncounterType      string    `json:"encounter_type,omitempty"`
	Message           string    `json:"message"`
	NewLocation       *Location `json:"new_location,omitempty"`
	UnlockReward      string    `json:"unlock_reward,omitempty"`

	// Luzhe 陆喆角色主导卡触发（Phase 1 新增）
	LuzheTriggered bool   `json:"luzhe_triggered,omitempty"`
	LuzheCardID    string `json:"luzhe_card_id,omitempty"`
	LuzheCardTitle string `json:"luzhe_card_title,omitempty"`
	LuzheReason    string `json:"luzhe_reason,omitempty"`
}
