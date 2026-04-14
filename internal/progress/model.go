// Package progress implements player progress tracking.
package progress

import (
	"encoding/json"
	"time"
)

// PlayerProgress represents a player's game progress.
type PlayerProgress struct {
	PlayerID         string     `json:"player_id"`
	UnlockedSkills   []string   `json:"unlocked_skills"`
	TriggeredEvents  []string   `json:"triggered_events"`
	VisitedLocations []Location `json:"visited_locations"`
	CurrentRegion    string     `json:"current_region"`
	CurrentLocation  string     `json:"current_location"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// Location represents a visited location record.
type Location struct {
	Region   string `json:"region"`
	Location string `json:"location"`
	VisitedAt int64 `json:"visited_at"`
}

// ProgressResponse is the API response for progress queries.
type ProgressResponse struct {
	PlayerID         string     `json:"player_id"`
	UnlockedSkills   []string   `json:"unlocked_skills"`
	TriggeredEvents  []string   `json:"triggered_events"`
	VisitedLocations []Location `json:"visited_locations"`
	CurrentRegion    string     `json:"current_region"`
	CurrentLocation  string     `json:"current_location"`
}

// ToResponse converts PlayerProgress to ProgressResponse.
func (p *PlayerProgress) ToResponse() *ProgressResponse {
	return &ProgressResponse{
		PlayerID:         p.PlayerID,
		UnlockedSkills:   p.UnlockedSkills,
		TriggeredEvents:  p.TriggeredEvents,
		VisitedLocations: p.VisitedLocations,
		CurrentRegion:    p.CurrentRegion,
		CurrentLocation:  p.CurrentLocation,
	}
}

// MarshalSkills converts skills slice to JSON string.
func MarshalSkills(skills []string) string {
	data, _ := json.Marshal(skills)
	return string(data)
}

// UnmarshalSkills parses JSON string to skills slice.
func UnmarshalSkills(data string) []string {
	var skills []string
	json.Unmarshal([]byte(data), &skills)
	return skills
}

// MarshalLocations converts locations slice to JSON string.
func MarshalLocations(locations []Location) string {
	data, _ := json.Marshal(locations)
	return string(data)
}

// UnmarshalLocations parses JSON string to locations slice.
func UnmarshalLocations(data string) []Location {
	var locations []Location
	json.Unmarshal([]byte(data), &locations)
	return locations
}

// UnlockSkillRequest is the request body for unlocking a skill.
type UnlockSkillRequest struct {
	SkillID string `json:"skill_id"`
}

// TriggerEventRequest is the request body for triggering an event.
type TriggerEventRequest struct {
	EventID string `json:"event_id"`
}

// VisitLocationRequest is the request body for visiting a location.
type VisitLocationRequest struct {
	Region   string `json:"region"`
	Location string `json:"location"`
}

// UpdateProgressRequest is the request body for full progress update.
type UpdateProgressRequest struct {
	UnlockedSkills   []string   `json:"unlocked_skills"`
	TriggeredEvents  []string   `json:"triggered_events"`
	VisitedLocations []Location `json:"visited_locations"`
	CurrentRegion    string     `json:"current_region"`
	CurrentLocation  string     `json:"current_location"`
}
