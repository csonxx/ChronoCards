package api

import (
	"encoding/json"
	"net/http"
	"net/url"

	"github.com/csonxx/ChronoCards/internal/game/world"
	"github.com/csonxx/ChronoCards/internal/model"
)

// WorldHandler 世界地图HTTP处理器
type WorldHandler struct {
	worldSvc  *world.Service
	json      func(w http.ResponseWriter, status int, data interface{})
	error     func(w http.ResponseWriter, status int, msg string)
	notFound  func(w http.ResponseWriter)
	badRequest func(w http.ResponseWriter, msg string)
}

// NewWorldHandler 创建世界地图处理器
func NewWorldHandler(worldSvc *world.Service) *WorldHandler {
	h := &WorldHandler{worldSvc: worldSvc}
	// 绑定辅助方法
	h.json = func(w http.ResponseWriter, status int, data interface{}) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		json.NewEncoder(w).Encode(data)
	}
	h.error = func(w http.ResponseWriter, status int, msg string) {
		h.json(w, status, map[string]string{"error": msg})
	}
	h.notFound = func(w http.ResponseWriter) {
		h.error(w, http.StatusNotFound, "not found")
	}
	h.badRequest = func(w http.ResponseWriter, msg string) {
		h.error(w, http.StatusBadRequest, msg)
	}
	return h
}

// GetWorldOverview 获取世界概览
// GET /api/v1/world
func (h *WorldHandler) GetWorldOverview(w http.ResponseWriter, r *http.Request) {
	overview, err := h.worldSvc.GetWorldOverview()
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}
	h.json(w, http.StatusOK, overview)
}

// ListLocations 获取场景列表
// GET /api/v1/world/locations
// Query params: type, region_id, unlocked_only
func (h *WorldHandler) ListLocations(w http.ResponseWriter, r *http.Request) {
	filter := world.LocationFilter{}

	filter.Type = r.URL.Query().Get("type")
	filter.RegionID = r.URL.Query().Get("region_id")
	
	unlockedOnlyStr := r.URL.Query().Get("unlocked_only")
	if unlockedOnlyStr == "true" || unlockedOnlyStr == "1" {
		filter.UnlockedOnly = true
	} else {
		filter.UnlockedOnly = false
	}

	locations, err := h.worldSvc.GetLocations(filter)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"locations": locations,
	})
}

// HandleLocationOrConnections 统一处理 /api/v1/world/locations/{path} 请求
// 根据path决定调用GetLocation还是GetLocationConnections
func (h *WorldHandler) HandleLocationOrConnections(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	// 检查是否是 /connections 结尾
	if len(path) > 13 && path[len(path)-13:] == "/connections" {
		// 提取 location_id
		// path格式: /api/v1/world/locations/{location_id}/connections
		// 我们需要提取 {location_id} 部分
		prefix := "/api/v1/world/locations/"
		if len(path) > len(prefix) {
			locationID := path[len(prefix) : len(path)-13]
			// 创建一个新的请求，修改path
			r2 := *r
			r2.URL = &url.URL{Path: "/api/v1/world/locations/" + locationID}
			// 使用PathValue来获取location_id
			// 手动设置path value
			h.GetLocationConnectionsWithID(w, r, locationID)
			return
		}
	}

	// 否则当作 GetLocation 处理
	// 提取 location_id
	prefix := "/api/v1/world/locations/"
	if len(path) > len(prefix) {
		locationID := path[len(prefix):]
		h.GetLocationWithID(w, r, locationID)
		return
	}

	h.badRequest(w, "invalid path")
}

// GetLocationWithID 获取场景详情（内部使用）
func (h *WorldHandler) GetLocationWithID(w http.ResponseWriter, r *http.Request, locationID string) {
	location, err := h.worldSvc.GetLocation(locationID)
	if err != nil {
		h.notFound(w)
		return
	}

	// 获取连通性数量
	connections, _ := h.worldSvc.GetLocationConnections(locationID)

	response := map[string]interface{}{
		"id":                  location.ID,
		"name":                location.Name,
		"display_order":       location.DisplayOrder,
		"region_id":           location.RegionID,
		"location_type":       location.LocationType,
		"location_type_ext":   location.LocationTypeExt,
		"description":         location.Description,
		"atmosphere":           location.Atmosphere,
		"danger_level":         location.DangerLevel,
		"npc_count":            location.NPCCount,
		"available_dealers":    location.AvailableDealers,
		"story_chapters":       location.StoryChapters,
		"tags":                 location.Tags,
		"unlocked":             location.Unlocked,
		"unlock_condition":     location.UnlockCondition,
		"scene_bg":             location.SceneBG,
		"music_track":          location.MusicTrack,
		"connections_count":    len(connections),
	}

	h.json(w, http.StatusOK, response)
}

// GetLocation 获取场景详情
// GET /api/v1/world/locations/{location_id}
func (h *WorldHandler) GetLocation(w http.ResponseWriter, r *http.Request) {
	locationID := r.PathValue("location_id")
	if locationID == "" {
		h.badRequest(w, "location_id is required")
		return
	}

	location, err := h.worldSvc.GetLocation(locationID)
	if err != nil {
		h.notFound(w)
		return
	}

	// 获取连通性数量
	connections, _ := h.worldSvc.GetLocationConnections(locationID)

	response := map[string]interface{}{
		"id":                  location.ID,
		"name":                location.Name,
		"display_order":       location.DisplayOrder,
		"region_id":           location.RegionID,
		"location_type":       location.LocationType,
		"location_type_ext":   location.LocationTypeExt,
		"description":         location.Description,
		"atmosphere":           location.Atmosphere,
		"danger_level":         location.DangerLevel,
		"npc_count":            location.NPCCount,
		"available_dealers":    location.AvailableDealers,
		"story_chapters":       location.StoryChapters,
		"tags":                 location.Tags,
		"unlocked":             location.Unlocked,
		"unlock_condition":     location.UnlockCondition,
		"scene_bg":             location.SceneBG,
		"music_track":          location.MusicTrack,
		"connections_count":    len(connections),
	}

	h.json(w, http.StatusOK, response)
}

// GetLocationConnectionsWithID 获取场景连通性（内部使用）
func (h *WorldHandler) GetLocationConnectionsWithID(w http.ResponseWriter, r *http.Request, locationID string) {
	// 验证场景存在
	location, err := h.worldSvc.GetLocation(locationID)
	if err != nil {
		h.notFound(w)
		return
	}

	connections, err := h.worldSvc.GetLocationConnections(locationID)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	// 转换为API格式
	connResponse := make([]map[string]interface{}, 0)
	for _, conn := range connections {
		connMap := map[string]interface{}{
			"id":                conn.ID,
			"connection_type":   conn.ConnectionType,
			"travel_time_min":   conn.TravelTimeMin,
			"danger_level":      conn.DangerLevel,
			"encounter_rate":    conn.EncounterRate,
			"description":       conn.Description,
			"required_items":    conn.RequiredItems,
			"unlocked":          conn.Unlocked,
		}

		// 填充目标场景数据
		if conn.ToLocationData != nil {
			connMap["to_location"] = map[string]interface{}{
				"id":           conn.ToLocationData.ID,
				"name":         conn.ToLocationData.Name,
				"location_type": conn.ToLocationData.LocationType,
				"danger_level":  conn.ToLocationData.DangerLevel,
				"unlocked":      conn.ToLocationData.Unlocked,
			}
		} else if location.ID != conn.ToLocation {
			// 如果to_location_data为空，手动填充
			if toLoc, _ := h.worldSvc.GetLocation(conn.ToLocation); toLoc != nil {
				connMap["to_location"] = map[string]interface{}{
					"id":           toLoc.ID,
					"name":         toLoc.Name,
					"location_type": toLoc.LocationType,
					"danger_level":  toLoc.DangerLevel,
					"unlocked":      toLoc.Unlocked,
				}
			}
		} else {
			// 自己到自己
			connMap["to_location"] = map[string]interface{}{
				"id":           location.ID,
				"name":         location.Name,
				"location_type": location.LocationType,
				"danger_level":  location.DangerLevel,
				"unlocked":      location.Unlocked,
			}
		}

		connResponse = append(connResponse, connMap)
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"connections": connResponse,
	})
}

// GetLocationConnections 获取场景连通性
// GET /api/v1/world/locations/{location_id}/connections
func (h *WorldHandler) GetLocationConnections(w http.ResponseWriter, r *http.Request) {
	locationID := r.PathValue("location_id")
	if locationID == "" {
		h.badRequest(w, "location_id is required")
		return
	}

	// 验证场景存在
	location, err := h.worldSvc.GetLocation(locationID)
	if err != nil {
		h.notFound(w)
		return
	}

	connections, err := h.worldSvc.GetLocationConnections(locationID)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	// 转换为API格式
	connResponse := make([]map[string]interface{}, 0)
	for _, conn := range connections {
		connMap := map[string]interface{}{
			"id":                conn.ID,
			"connection_type":   conn.ConnectionType,
			"travel_time_min":   conn.TravelTimeMin,
			"danger_level":      conn.DangerLevel,
			"encounter_rate":    conn.EncounterRate,
			"description":       conn.Description,
			"required_items":    conn.RequiredItems,
			"unlocked":          conn.Unlocked,
		}
		
		// 填充目标场景数据
		if conn.ToLocationData != nil {
			connMap["to_location"] = map[string]interface{}{
				"id":           conn.ToLocationData.ID,
				"name":         conn.ToLocationData.Name,
				"location_type": conn.ToLocationData.LocationType,
				"danger_level":  conn.ToLocationData.DangerLevel,
				"unlocked":      conn.ToLocationData.Unlocked,
			}
		} else if location.ID != conn.ToLocation {
			// 如果to_location_data为空，手动填充
			if toLoc, _ := h.worldSvc.GetLocation(conn.ToLocation); toLoc != nil {
				connMap["to_location"] = map[string]interface{}{
					"id":           toLoc.ID,
					"name":         toLoc.Name,
					"location_type": toLoc.LocationType,
					"danger_level":  toLoc.DangerLevel,
					"unlocked":      toLoc.Unlocked,
				}
			}
		} else {
			// 自己到自己
			connMap["to_location"] = map[string]interface{}{
				"id":           location.ID,
				"name":         location.Name,
				"location_type": location.LocationType,
				"danger_level":  location.DangerLevel,
				"unlocked":      location.Unlocked,
			}
		}

		connResponse = append(connResponse, connMap)
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"connections": connResponse,
	})
}

// GetPlayerLocation 获取玩家当前位置
// GET /api/v1/players/{player_id}/location
func (h *WorldHandler) GetPlayerLocation(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	if playerID == "" {
		h.badRequest(w, "player_id is required")
		return
	}

	playerLoc, err := h.worldSvc.GetPlayerLocation(playerID)
	if err != nil {
		// 如果没有位置记录，返回默认位置（平阳城）
		playerLoc = model.NewPlayerLocation(playerID, "loc-pingyang", "region-central-plains")
	}

	// 获取位置详情
	currentLocation, _ := h.worldSvc.GetLocation(playerLoc.CurrentLocation)
	currentRegion := h.worldSvc.GetRegion(playerLoc.CurrentRegion)

	response := map[string]interface{}{
		"player_id":    playerLoc.PlayerID,
		"in_battle":    playerLoc.InBattle,
		"visited_count": len(playerLoc.VisitedLocations),
		"total_travel_count": playerLoc.TotalTravelCount,
	}

	if currentLocation != nil {
		response["current_location"] = map[string]interface{}{
			"id":            currentLocation.ID,
			"name":          currentLocation.Name,
			"display_order": currentLocation.DisplayOrder,
			"region_id":     currentLocation.RegionID,
			"location_type": currentLocation.LocationType,
			"location_type_ext": currentLocation.LocationTypeExt,
			"description":   currentLocation.Description,
			"atmosphere":     currentLocation.Atmosphere,
			"danger_level":   currentLocation.DangerLevel,
			"npc_count":      currentLocation.NPCCount,
			"available_dealers": currentLocation.AvailableDealers,
			"story_chapters": currentLocation.StoryChapters,
			"tags":           currentLocation.Tags,
			"unlocked":       currentLocation.Unlocked,
			"scene_bg":       currentLocation.SceneBG,
			"music_track":    currentLocation.MusicTrack,
		}
	}

	if currentRegion != nil {
		response["current_region"] = map[string]interface{}{
			"id":           currentRegion.ID,
			"name":         currentRegion.Name,
			"display_order": currentRegion.DisplayOrder,
			"description":  currentRegion.Description,
			"climate":      currentRegion.Climate,
			"terrain":      currentRegion.Terrain,
			"danger_level":  currentRegion.DangerLevel,
			"tags":         currentRegion.Tags,
			"story_intro":  currentRegion.StoryIntro,
		}
	}

	response["visited_locations"] = playerLoc.VisitedLocations
	response["unlocked_locations"] = playerLoc.UnlockedLocations

	h.json(w, http.StatusOK, response)
}

// NavigateRequest 导航请求
type NavigateRequest struct {
	TargetLocationID string `json:"target_location_id"`
	SkipEncounter    bool   `json:"skip_encounter"`
}

// Navigate 处理导航请求
// POST /api/v1/players/{player_id}/location/navigate
func (h *WorldHandler) Navigate(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	if playerID == "" {
		h.badRequest(w, "player_id is required")
		return
	}

	var req NavigateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.TargetLocationID == "" {
		h.badRequest(w, "target_location_id is required")
		return
	}

	result, err := h.worldSvc.ProcessNavigation(playerID, req.TargetLocationID, req.SkipEncounter)
	if err != nil {
		// 根据错误类型返回不同状态码
		errMsg := err.Error()
		if errMsg == "目标场景不存在" {
			h.error(w, http.StatusNotFound, errMsg)
			return
		}
		if errMsg == "目标场景未解锁，需要: "+req.TargetLocationID {
			h.error(w, http.StatusForbidden, errMsg)
			return
		}
		if contains(errMsg, "未解锁") || contains(errMsg, "没有直接路径") {
			h.error(w, http.StatusBadRequest, errMsg)
			return
		}
		h.error(w, http.StatusInternalServerError, errMsg)
		return
	}

	// 构建响应
	response := map[string]interface{}{
		"success": result.Success,
		"message": result.Message,
	}

	if result.FromLocation != nil {
		response["from_location"] = map[string]interface{}{
			"id":           result.FromLocation.ID,
			"name":         result.FromLocation.Name,
			"location_type": result.FromLocation.LocationType,
		}
	}

	if result.ToLocation != nil {
		response["to_location"] = map[string]interface{}{
			"id":           result.ToLocation.ID,
			"name":         result.ToLocation.Name,
			"location_type": result.ToLocation.LocationType,
		}
	}

	response["encounter_triggered"] = result.EncounterTriggered
	response["encounter_type"] = result.EncounterType
	response["travel_time_min"] = result.TravelTimeMin
	response["danger_encountered"] = result.DangerEncountered

	if result.NewLocation != nil {
		response["new_location"] = map[string]interface{}{
			"id":           result.NewLocation.ID,
			"name":         result.NewLocation.Name,
			"location_type": result.NewLocation.LocationType,
			"atmosphere":    result.NewLocation.Atmosphere,
		}
	}

	if result.UnlockReward != nil {
		response["unlock_reward"] = result.UnlockReward
	}

	h.json(w, http.StatusOK, response)
}

// SetLocationRequest 设置位置请求
type SetLocationRequest struct {
	LocationID string `json:"location_id"`
}

// SetPlayerLocation 设置玩家位置（GM/测试用）
// POST /api/v1/players/{player_id}/location/set
func (h *WorldHandler) SetPlayerLocation(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	if playerID == "" {
		h.badRequest(w, "player_id is required")
		return
	}

	var req SetLocationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.LocationID == "" {
		h.badRequest(w, "location_id is required")
		return
	}

	err := h.worldSvc.SetPlayerLocation(playerID, req.LocationID)
	if err != nil {
		h.error(w, http.StatusBadRequest, err.Error())
		return
	}

	// 添加到已访问
	h.worldSvc.GetPlayerLocation(playerID) // 确保playerLoc存在
	playerLoc, _ := h.worldSvc.GetPlayerLocation(playerID)
	if playerLoc != nil {
		playerLoc.AddVisited(req.LocationID, "region-central-plains")
	}

	// 获取位置详情返回
	location, _ := h.worldSvc.GetLocation(req.LocationID)
	region := h.worldSvc.GetRegion("region-central-plains")

	response := map[string]interface{}{
		"player_id": playerID,
		"message":   "位置设置成功",
	}

	if location != nil {
		response["current_location"] = map[string]interface{}{
			"id":            location.ID,
			"name":          location.Name,
			"display_order": location.DisplayOrder,
			"region_id":     location.RegionID,
			"location_type": location.LocationType,
			"location_type_ext": location.LocationTypeExt,
			"description":   location.Description,
			"atmosphere":     location.Atmosphere,
			"danger_level":   location.DangerLevel,
			"npc_count":      location.NPCCount,
			"available_dealers": location.AvailableDealers,
			"story_chapters": location.StoryChapters,
			"tags":           location.Tags,
			"unlocked":       location.Unlocked,
			"scene_bg":       location.SceneBG,
			"music_track":    location.MusicTrack,
		}
	}

	if region != nil {
		response["current_region"] = map[string]interface{}{
			"id":           region.ID,
			"name":         region.Name,
			"display_order": region.DisplayOrder,
			"description":  region.Description,
			"climate":      region.Climate,
			"terrain":      region.Terrain,
			"danger_level":  region.DangerLevel,
			"tags":         region.Tags,
			"story_intro":  region.StoryIntro,
		}
	}

	h.json(w, http.StatusOK, response)
}

// GetPlayerVisited 获取玩家访问历史
// GET /api/v1/players/{player_id}/visited
func (h *WorldHandler) GetPlayerVisited(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("player_id")
	if playerID == "" {
		h.badRequest(w, "player_id is required")
		return
	}

	visited, err := h.worldSvc.GetPlayerVisited(playerID)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	// 转换为API格式
	visitedResponse := make([]map[string]interface{}, 0)
	for _, loc := range visited {
		visitedResponse = append(visitedResponse, map[string]interface{}{
			"id":            loc.ID,
			"name":          loc.Name,
			"display_order": loc.DisplayOrder,
			"region_id":     loc.RegionID,
			"location_type": loc.LocationType,
			"location_type_ext": loc.LocationTypeExt,
			"description":   loc.Description,
			"atmosphere":     loc.Atmosphere,
			"danger_level":   loc.DangerLevel,
			"tags":           loc.Tags,
			"unlocked":       loc.Unlocked,
			"scene_bg":       loc.SceneBG,
		})
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"visited_locations": visitedResponse,
		"total_count":       len(visitedResponse),
	})
}

// HandlePlayerWorldRequest 统一处理 /api/v1/players/{player_id}/... 请求
// 根据path决定调用哪个handler
func (h *WorldHandler) HandlePlayerWorldRequest(w http.ResponseWriter, r *http.Request) {
	// path格式: /api/v1/players/{player_id}/location
	// 或者: /api/v1/players/{player_id}/location/navigate
	// 或者: /api/v1/players/{player_id}/location/set
	// 或者: /api/v1/players/{player_id}/visited

	path := r.URL.Path
	method := r.Method

	// 解析出 player_id 和剩余路径
	prefix := "/api/v1/players/"
	if len(path) <= len(prefix) {
		h.badRequest(w, "invalid path")
		return
	}

	rest := path[len(prefix):]
	// rest格式: {player_id}/location 或 {player_id}/location/navigate 等

	// 找到第一个 / 的位置来分割 player_id
	slashIdx := -1
	for i := 0; i < len(rest); i++ {
		if rest[i] == '/' {
			slashIdx = i
			break
		}
	}

	if slashIdx == -1 {
		h.badRequest(w, "invalid player path")
		return
	}

	playerID := rest[:slashIdx]
	remaining := rest[slashIdx:] // 以 / 开头

	// 路由判断
	switch {
	case remaining == "/location" && method == "GET":
		h.GetPlayerLocationByID(w, r, playerID)
	case remaining == "/location/navigate" && method == "POST":
		h.NavigateByID(w, r, playerID)
	case remaining == "/location/set" && method == "POST":
		h.SetPlayerLocationByID(w, r, playerID)
	case remaining == "/visited" && method == "GET":
		h.GetPlayerVisitedByID(w, r, playerID)
	default:
		h.error(w, http.StatusNotFound, "not found")
	}
}

// GetPlayerLocationByID 获取玩家当前位置（内部使用）
func (h *WorldHandler) GetPlayerLocationByID(w http.ResponseWriter, r *http.Request, playerID string) {
	playerLoc, err := h.worldSvc.GetPlayerLocation(playerID)
	if err != nil {
		// 如果没有位置记录，返回默认位置（平阳城）
		playerLoc = model.NewPlayerLocation(playerID, "loc-pingyang", "region-central-plains")
	}

	// 获取位置详情
	currentLocation, _ := h.worldSvc.GetLocation(playerLoc.CurrentLocation)
	currentRegion := h.worldSvc.GetRegion(playerLoc.CurrentRegion)

	response := map[string]interface{}{
		"player_id":           playerLoc.PlayerID,
		"in_battle":          playerLoc.InBattle,
		"visited_count":       len(playerLoc.VisitedLocations),
		"total_travel_count": playerLoc.TotalTravelCount,
	}

	if currentLocation != nil {
		response["current_location"] = map[string]interface{}{
			"id":            currentLocation.ID,
			"name":          currentLocation.Name,
			"display_order": currentLocation.DisplayOrder,
			"region_id":     currentLocation.RegionID,
			"location_type": currentLocation.LocationType,
			"location_type_ext": currentLocation.LocationTypeExt,
			"description":   currentLocation.Description,
			"atmosphere":     currentLocation.Atmosphere,
			"danger_level":   currentLocation.DangerLevel,
			"npc_count":      currentLocation.NPCCount,
			"available_dealers": currentLocation.AvailableDealers,
			"story_chapters": currentLocation.StoryChapters,
			"tags":           currentLocation.Tags,
			"unlocked":       currentLocation.Unlocked,
			"scene_bg":       currentLocation.SceneBG,
			"music_track":    currentLocation.MusicTrack,
		}
	}

	if currentRegion != nil {
		response["current_region"] = map[string]interface{}{
			"id":           currentRegion.ID,
			"name":         currentRegion.Name,
			"display_order": currentRegion.DisplayOrder,
			"description":  currentRegion.Description,
			"climate":      currentRegion.Climate,
			"terrain":      currentRegion.Terrain,
			"danger_level":  currentRegion.DangerLevel,
			"tags":         currentRegion.Tags,
			"story_intro":  currentRegion.StoryIntro,
		}
	}

	response["visited_locations"] = playerLoc.VisitedLocations
	response["unlocked_locations"] = playerLoc.UnlockedLocations

	h.json(w, http.StatusOK, response)
}

// NavigateByID 处理导航请求（内部使用）
func (h *WorldHandler) NavigateByID(w http.ResponseWriter, r *http.Request, playerID string) {
	var req NavigateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.TargetLocationID == "" {
		h.badRequest(w, "target_location_id is required")
		return
	}

	result, err := h.worldSvc.ProcessNavigation(playerID, req.TargetLocationID, req.SkipEncounter)
	if err != nil {
		// 根据错误类型返回不同状态码
		errMsg := err.Error()
		if errMsg == "目标场景不存在" {
			h.error(w, http.StatusNotFound, errMsg)
			return
		}
		if contains(errMsg, "未解锁") || contains(errMsg, "没有直接路径") {
			h.error(w, http.StatusBadRequest, errMsg)
			return
		}
		h.error(w, http.StatusInternalServerError, errMsg)
		return
	}

	// 构建响应
	response := map[string]interface{}{
		"success": result.Success,
		"message": result.Message,
	}

	if result.FromLocation != nil {
		response["from_location"] = map[string]interface{}{
			"id":           result.FromLocation.ID,
			"name":         result.FromLocation.Name,
			"location_type": result.FromLocation.LocationType,
		}
	}

	if result.ToLocation != nil {
		response["to_location"] = map[string]interface{}{
			"id":           result.ToLocation.ID,
			"name":         result.ToLocation.Name,
			"location_type": result.ToLocation.LocationType,
		}
	}

	response["encounter_triggered"] = result.EncounterTriggered
	response["encounter_type"] = result.EncounterType
	response["travel_time_min"] = result.TravelTimeMin
	response["danger_encountered"] = result.DangerEncountered

	if result.NewLocation != nil {
		response["new_location"] = map[string]interface{}{
			"id":           result.NewLocation.ID,
			"name":         result.NewLocation.Name,
			"location_type": result.NewLocation.LocationType,
			"atmosphere":    result.NewLocation.Atmosphere,
		}
	}

	if result.UnlockReward != nil {
		response["unlock_reward"] = result.UnlockReward
	}

	h.json(w, http.StatusOK, response)
}

// SetPlayerLocationByID 设置玩家位置（内部使用）
func (h *WorldHandler) SetPlayerLocationByID(w http.ResponseWriter, r *http.Request, playerID string) {
	var req SetLocationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.badRequest(w, "invalid request body")
		return
	}

	if req.LocationID == "" {
		h.badRequest(w, "location_id is required")
		return
	}

	err := h.worldSvc.SetPlayerLocation(playerID, req.LocationID)
	if err != nil {
		h.error(w, http.StatusBadRequest, err.Error())
		return
	}

	// 添加到已访问
	playerLoc, _ := h.worldSvc.GetPlayerLocation(playerID)
	if playerLoc != nil {
		playerLoc.AddVisited(req.LocationID, "region-central-plains")
	}

	// 获取位置详情返回
	location, _ := h.worldSvc.GetLocation(req.LocationID)
	region := h.worldSvc.GetRegion("region-central-plains")

	response := map[string]interface{}{
		"player_id": playerID,
		"message":   "位置设置成功",
	}

	if location != nil {
		response["current_location"] = map[string]interface{}{
			"id":            location.ID,
			"name":          location.Name,
			"display_order": location.DisplayOrder,
			"region_id":     location.RegionID,
			"location_type": location.LocationType,
			"location_type_ext": location.LocationTypeExt,
			"description":   location.Description,
			"atmosphere":     location.Atmosphere,
			"danger_level":   location.DangerLevel,
			"npc_count":      location.NPCCount,
			"available_dealers": location.AvailableDealers,
			"story_chapters": location.StoryChapters,
			"tags":           location.Tags,
			"unlocked":       location.Unlocked,
			"scene_bg":       location.SceneBG,
			"music_track":    location.MusicTrack,
		}
	}

	if region != nil {
		response["current_region"] = map[string]interface{}{
			"id":           region.ID,
			"name":         region.Name,
			"display_order": region.DisplayOrder,
			"description":  region.Description,
			"climate":      region.Climate,
			"terrain":      region.Terrain,
			"danger_level":  region.DangerLevel,
			"tags":         region.Tags,
			"story_intro":  region.StoryIntro,
		}
	}

	h.json(w, http.StatusOK, response)
}

// GetPlayerVisitedByID 获取玩家访问历史（内部使用）
func (h *WorldHandler) GetPlayerVisitedByID(w http.ResponseWriter, r *http.Request, playerID string) {
	visited, err := h.worldSvc.GetPlayerVisited(playerID)
	if err != nil {
		h.error(w, http.StatusInternalServerError, err.Error())
		return
	}

	// 转换为API格式
	visitedResponse := make([]map[string]interface{}, 0)
	for _, loc := range visited {
		visitedResponse = append(visitedResponse, map[string]interface{}{
			"id":            loc.ID,
			"name":          loc.Name,
			"display_order": loc.DisplayOrder,
			"region_id":     loc.RegionID,
			"location_type": loc.LocationType,
			"location_type_ext": loc.LocationTypeExt,
			"description":   loc.Description,
			"atmosphere":     loc.Atmosphere,
			"danger_level":   loc.DangerLevel,
			"tags":           loc.Tags,
			"unlocked":       loc.Unlocked,
			"scene_bg":       loc.SceneBG,
		})
	}

	h.json(w, http.StatusOK, map[string]interface{}{
		"visited_locations": visitedResponse,
		"total_count":       len(visitedResponse),
	})
}

// contains 检查字符串是否包含子串
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsHelper(s, substr))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
