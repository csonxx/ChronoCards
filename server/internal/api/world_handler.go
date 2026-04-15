package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/csonxx/ChronoCards/server/internal/game/world"
)

// WorldHandler 世界地图HTTP处理器
type WorldHandler struct {
	worldSvc *world.Service
}

// NewWorldHandler 创建世界地图处理器
func NewWorldHandler(ws *world.Service) *WorldHandler {
	return &WorldHandler{worldSvc: ws}
}

func (h *WorldHandler) json(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *WorldHandler) error(w http.ResponseWriter, status int, msg string) {
	h.json(w, status, map[string]string{"error": msg})
}

// GetWorldOverview GET /api/v1/world
func (h *WorldHandler) GetWorldOverview(w http.ResponseWriter, r *http.Request) {
	overview := h.worldSvc.GetWorldOverview()
	h.json(w, http.StatusOK, overview)
}

// ListLocations GET /api/v1/world/locations
func (h *WorldHandler) ListLocations(w http.ResponseWriter, r *http.Request) {
	filter := &world.LocationFilter{
		Type:         r.URL.Query().Get("type"),
		RegionID:     r.URL.Query().Get("region_id"),
		UnlockedOnly: r.URL.Query().Get("unlocked_only") == "true",
	}
	locations := h.worldSvc.GetLocations(filter)
	h.json(w, http.StatusOK, map[string]interface{}{"locations": locations, "total": len(locations)})
}

// GetLocation GET /api/v1/world/locations/{id}
func (h *WorldHandler) GetLocation(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/api/v1/world/locations/")
	loc := h.worldSvc.GetLocation(id)
	if loc == nil {
		h.error(w, 404, "场景不存在")
		return
	}
	region := world.GetRegionByID(loc.RegionID)
	h.json(w, http.StatusOK, map[string]interface{}{"location": loc, "region": region})
}

// GetLocationConnections GET /api/v1/world/locations/{id}/connections
func (h *WorldHandler) GetLocationConnections(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/api/v1/world/locations/")
	id = strings.TrimSuffix(id, "/connections")
	connections := h.worldSvc.GetLocationConnections(id)
	h.json(w, http.StatusOK, map[string]interface{}{"connections": connections})
}

// GetPlayerLocation GET /api/v1/players/{id}/location
func (h *WorldHandler) GetPlayerLocation(w http.ResponseWriter, r *http.Request) {
	id := extractPlayerID(r.URL.Path)
	playerData := h.worldSvc.GetPlayerLocation(id)
	loc := world.GetLocationByID(playerData.CurrentLocation)
	region := world.GetRegionByID(playerData.CurrentRegion)
	h.json(w, http.StatusOK, map[string]interface{}{
		"player_id":        playerData.PlayerID,
		"current_location": loc,
		"current_region":    region,
		"visited_count":    len(playerData.VisitedLocations),
	})
}

// Navigate POST /api/v1/players/{id}/location/navigate
func (h *WorldHandler) Navigate(w http.ResponseWriter, r *http.Request) {
	id := extractPlayerID(r.URL.Path)
	var req struct {
		TargetLocationID string `json:"target_location_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TargetLocationID == "" {
		h.error(w, 400, "缺少 target_location_id")
		return
	}
	result := h.worldSvc.ProcessNavigation(id, req.TargetLocationID)
	if !result.Success {
		h.error(w, 400, result.Message)
		return
	}
	h.json(w, http.StatusOK, result)
}

// SetPlayerLocation POST /api/v1/players/{id}/location/set
func (h *WorldHandler) SetPlayerLocation(w http.ResponseWriter, r *http.Request) {
	id := extractPlayerID(r.URL.Path)
	var req struct {
		LocationID string `json:"location_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.LocationID == "" {
		h.error(w, 400, "缺少 location_id")
		return
	}
	loc := world.GetLocationByID(req.LocationID)
	if loc == nil {
		h.error(w, 404, "场景不存在")
		return
	}
	h.worldSvc.GetPlayerLocation(id).CurrentLocation = req.LocationID
	h.json(w, http.StatusOK, map[string]interface{}{"player_id": id, "current_location": loc})
}

// GetPlayerVisited GET /api/v1/players/{id}/visited
func (h *WorldHandler) GetPlayerVisited(w http.ResponseWriter, r *http.Request) {
	id := extractPlayerID(r.URL.Path)
	playerData := h.worldSvc.GetPlayerLocation(id)
	locations := make([]*world.Location, 0)
	for _, locID := range playerData.VisitedLocations {
		if loc := world.GetLocationByID(locID); loc != nil {
			locations = append(locations, loc)
		}
	}
	h.json(w, http.StatusOK, map[string]interface{}{"visited_locations": locations, "total_count": len(locations)})
}

// extractPlayerID 从路径中提取玩家ID
func extractPlayerID(path string) string {
	parts := strings.Split(path, "/players/")
	if len(parts) < 2 {
		return ""
	}
	return strings.Split(parts[1], "/")[0]
}
