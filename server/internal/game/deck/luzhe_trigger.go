package deck

// LuzheTriggerContext 陆喆事件触发检查的上下文
// 从 PlayerLocation 和 StoryProgress 中提取，供 LuzheStateMachine 使用
type PlayerLocationContext struct {
	PlayerID          string
	CurrentLocation   string
	CurrentRegion     string
	VisitedLocations  []string
	VisitedRegions    []string
	StoryProgress     map[string]int // chapterID -> progress (0-100)
}

// NewPlayerLocationContext 从 model.PlayerLocation 构建触发上下文
func NewPlayerLocationContext(
	playerID, currentLocation, currentRegion string,
	visitedLocations, visitedRegions []string,
	storyProgress map[string]int,
) *PlayerLocationContext {
	return &PlayerLocationContext{
		PlayerID:         playerID,
		CurrentLocation:  currentLocation,
		CurrentRegion:    currentRegion,
		VisitedLocations: visitedLocations,
		VisitedRegions:   visitedRegions,
		StoryProgress:    storyProgress,
	}
}

// IsFirstVisitToLocation 检查是否首次访问某场景
func (c *PlayerLocationContext) IsFirstVisitToLocation(locationID string) bool {
	for _, loc := range c.VisitedLocations {
		if loc == locationID {
			return false
		}
	}
	return true
}

// IsFirstVisitToRegion 检查是否首次访问某大区
func (c *PlayerLocationContext) IsFirstVisitToRegion(regionID string) bool {
	for _, reg := range c.VisitedRegions {
		if reg == regionID {
			return false
		}
	}
	return true
}

// GetMainStoryProgress 获取主线进度百分比（0-100）
func (c *PlayerLocationContext) GetMainStoryProgress() int {
	if c.StoryProgress == nil {
		return 0
	}
	// 取所有章节的平均进度
	if len(c.StoryProgress) == 0 {
		return 0
	}
	total := 0
	for _, p := range c.StoryProgress {
		total += p
	}
	return total / len(c.StoryProgress)
}
