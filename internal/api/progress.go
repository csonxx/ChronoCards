// Package api provides HTTP API handlers.
package api

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/aiworld/game/internal/progress"
)

// ProgressHandler handles player progress API requests.
type ProgressHandler struct {
	repo *progress.Repository
}

// NewProgressHandler creates a new progress handler.
func NewProgressHandler(db *sql.DB) *ProgressHandler {
	return &ProgressHandler{
		repo: progress.NewRepository(db),
	}
}

// GetProgress handles GET /players/{id}/progress
func (h *ProgressHandler) GetProgress(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("id")
	if playerID == "" {
		http.Error(w, "player_id required", http.StatusBadRequest)
		return
	}

	progress, err := h.repo.GetOrCreate(playerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(progress.ToResponse())
}

// UpdateProgress handles PUT /players/{id}/progress
func (h *ProgressHandler) UpdateProgress(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("id")
	if playerID == "" {
		http.Error(w, "player_id required", http.StatusBadRequest)
		return
	}

	var req progress.UpdateProgressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	p, err := h.repo.GetOrCreate(playerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if req.UnlockedSkills != nil {
		p.UnlockedSkills = req.UnlockedSkills
	}
	if req.TriggeredEvents != nil {
		p.TriggeredEvents = req.TriggeredEvents
	}
	if req.VisitedLocations != nil {
		p.VisitedLocations = req.VisitedLocations
	}
	if req.CurrentRegion != "" {
		p.CurrentRegion = req.CurrentRegion
	}
	if req.CurrentLocation != "" {
		p.CurrentLocation = req.CurrentLocation
	}

	if err := h.repo.Update(p); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p.ToResponse())
}

// UnlockSkill handles POST /players/{id}/progress/unlock-skill
func (h *ProgressHandler) UnlockSkill(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("id")
	if playerID == "" {
		http.Error(w, "player_id required", http.StatusBadRequest)
		return
	}

	var req progress.UnlockSkillRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.SkillID == "" {
		http.Error(w, "skill_id required", http.StatusBadRequest)
		return
	}

	if err := h.repo.UnlockSkill(playerID, req.SkillID); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	p, _ := h.repo.GetByPlayerID(playerID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p.ToResponse())
}

// TriggerEvent handles POST /players/{id}/progress/trigger-event
func (h *ProgressHandler) TriggerEvent(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("id")
	if playerID == "" {
		http.Error(w, "player_id required", http.StatusBadRequest)
		return
	}

	var req progress.TriggerEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.EventID == "" {
		http.Error(w, "event_id required", http.StatusBadRequest)
		return
	}

	if err := h.repo.TriggerEvent(playerID, req.EventID); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	p, _ := h.repo.GetByPlayerID(playerID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p.ToResponse())
}

// VisitLocation handles POST /players/{id}/progress/visit-location
func (h *ProgressHandler) VisitLocation(w http.ResponseWriter, r *http.Request) {
	playerID := r.PathValue("id")
	if playerID == "" {
		http.Error(w, "player_id required", http.StatusBadRequest)
		return
	}

	var req progress.VisitLocationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.Region == "" || req.Location == "" {
		http.Error(w, "region and location required", http.StatusBadRequest)
		return
	}

	if err := h.repo.VisitLocation(playerID, req.Region, req.Location); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	p, _ := h.repo.GetByPlayerID(playerID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p.ToResponse())
}
