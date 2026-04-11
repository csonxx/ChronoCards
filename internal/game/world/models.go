package world

import "time"

// Region 大区
type Region struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	DisplayOrder  int      `json:"display_order"`
	Description   string   `json:"description"`
	Climate       string   `json:"climate"`
	Terrain       string   `json:"terrain"`
	DangerLevel   int      `json:"danger_level"`
	Tags          []string `json:"tags"`
	ConnectedRegions []string `json:"connected_regions"`
	ParentWorld   string   `json:"parent_world"`
	StoryIntro    string   `json:"story_intro"`
	CreatedAt     time.Time `json:"created_at"`
}

// Location 场景
type Location struct {
	ID               string   `json:"id"`
	Name             string   `json:"name"`
	DisplayOrder     int      `json:"display_order"`
	RegionID         string   `json:"region_id"`
	LocationType     string   `json:"location_type"`   // city/town/village/wilderness/dungeon/special/inn
	LocationTypeExt  string   `json:"location_type_ext"`
	Description      string   `json:"description"`
	Atmosphere       string   `json:"atmosphere"`
	DangerLevel      int      `json:"danger_level"`
	NPCCount         int      `json:"npc_count"`
	AvailableDealers []string `json:"available_dealers"`
	StoryChapters    []string `json:"story_chapters"`
	Tags             []string `json:"tags"`
	Unlocked         bool     `json:"unlocked"`
	UnlockCondition  string   `json:"unlock_condition,omitempty"`
	SceneBG          string   `json:"scene_bg"`
	MusicTrack       string   `json:"music_track"`
	CreatedAt        time.Time `json:"created_at"`
}

// LocationConnection 场景连通性
type LocationConnection struct {
	ID              string    `json:"id"`
	FromLocation    string    `json:"from_location"`
	ToLocation      string    `json:"to_location"`
	ToLocationData  *Location `json:"to_location_data,omitempty"`
	ConnectionType  string    `json:"connection_type"`  // road/trekking/teleport/story_locked
	TravelTimeMin   int       `json:"travel_time_min"`
	DangerLevel     int       `json:"danger_level"`
	EncounterRate   float64   `json:"encounter_rate"`    // 0.000-1.000
	Description     string    `json:"description"`
	RequiredItems   []string  `json:"required_items"`
	UnlockCondition string    `json:"unlock_condition,omitempty"`
	IsBidirectional bool      `json:"is_bidirectional"`
	Unlocked        bool      `json:"unlocked"`
	CreatedAt       time.Time `json:"created_at"`
}

// WorldOverview 世界概览
type WorldOverview struct {
	WorldArc          string    `json:"world_arc"`
	ActiveEvents      []string  `json:"active_events"`
	Regions           []*Region `json:"regions"`
	TotalLocations    int       `json:"total_locations"`
	AvailableLocations int      `json:"available_locations"`
}

// LocationFilter 场景筛选条件
type LocationFilter struct {
	Type         string `json:"type,omitempty"`
	RegionID     string `json:"region_id,omitempty"`
	UnlockedOnly bool   `json:"unlocked_only"`
}

// NavigateResult 导航结果
type NavigateResult struct {
	Success             bool          `json:"success"`
	FromLocation        *Location     `json:"from_location"`
	ToLocation          *Location     `json:"to_location"`
	EncounterTriggered  bool          `json:"encounter_triggered"`
	EncounterType       string        `json:"encounter_type"`  // enemy/treasure/npc/event/none
	EncounterData       interface{}   `json:"encounter_data,omitempty"`
	TravelTimeMin       int           `json:"travel_time_min"`
	DangerEncountered   bool          `json:"danger_encountered"`
	Message             string        `json:"message"`
	NewLocation         *Location     `json:"new_location"`
	UnlockReward        *UnlockReward `json:"unlock_reward,omitempty"`
}

// UnlockReward 解锁奖励
type UnlockReward struct {
	UnlockedLocationID   string `json:"unlocked_location_id"`
	UnlockedLocationName  string `json:"unlocked_location_name"`
	Message              string `json:"message"`
}
