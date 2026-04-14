package progress

import (
	"database/sql"
	"time"
)

// Repository handles player progress data persistence.
type Repository struct {
	db *sql.DB
}

// NewRepository creates a new progress repository.
func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// GetByPlayerID retrieves progress for a player.
func (r *Repository) GetByPlayerID(playerID string) (*PlayerProgress, error) {
	var progress PlayerProgress
	var skillsJSON, eventsJSON, locationsJSON string

	err := r.db.QueryRow(`
		SELECT player_id, unlocked_skills, triggered_events, visited_locations,
		       current_region, current_location, created_at, updated_at
		FROM player_progress WHERE player_id = ?`, playerID).Scan(
		&progress.PlayerID,
		&skillsJSON,
		&eventsJSON,
		&locationsJSON,
		&progress.CurrentRegion,
		&progress.CurrentLocation,
		&progress.CreatedAt,
		&progress.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	progress.UnlockedSkills = UnmarshalSkills(skillsJSON)
	progress.TriggeredEvents = UnmarshalSkills(eventsJSON)
	progress.VisitedLocations = UnmarshalLocations(locationsJSON)

	return &progress, nil
}

// Create creates a new player progress record.
func (r *Repository) Create(playerID string) (*PlayerProgress, error) {
	progress := &PlayerProgress{
		PlayerID:         playerID,
		UnlockedSkills:   []string{},
		TriggeredEvents:  []string{},
		VisitedLocations: []Location{},
		CurrentRegion:    "",
		CurrentLocation: "",
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}

	_, err := r.db.Exec(`
		INSERT INTO player_progress 
		(player_id, unlocked_skills, triggered_events, visited_locations, current_region, current_location, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		progress.PlayerID,
		MarshalSkills(progress.UnlockedSkills),
		MarshalSkills(progress.TriggeredEvents),
		MarshalLocations(progress.VisitedLocations),
		progress.CurrentRegion,
		progress.CurrentLocation,
		progress.CreatedAt,
		progress.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return progress, nil
}

// Update updates an existing player progress record.
func (r *Repository) Update(progress *PlayerProgress) error {
	progress.UpdatedAt = time.Now()
	_, err := r.db.Exec(`
		UPDATE player_progress 
		SET unlocked_skills = ?, triggered_events = ?, visited_locations = ?,
		    current_region = ?, current_location = ?, updated_at = ?
		WHERE player_id = ?`,
		MarshalSkills(progress.UnlockedSkills),
		MarshalSkills(progress.TriggeredEvents),
		MarshalLocations(progress.VisitedLocations),
		progress.CurrentRegion,
		progress.CurrentLocation,
		progress.UpdatedAt,
		progress.PlayerID,
	)
	return err
}

// UnlockSkill adds a skill to player's unlocked list.
func (r *Repository) UnlockSkill(playerID, skillID string) error {
	progress, err := r.GetByPlayerID(playerID)
	if err != nil {
		return err
	}

	// Check if already unlocked
	for _, s := range progress.UnlockedSkills {
		if s == skillID {
			return nil
		}
	}

	progress.UnlockedSkills = append(progress.UnlockedSkills, skillID)
	return r.Update(progress)
}

// TriggerEvent adds an event to player's triggered list.
func (r *Repository) TriggerEvent(playerID, eventID string) error {
	progress, err := r.GetByPlayerID(playerID)
	if err != nil {
		return err
	}

	// Check if already triggered
	for _, e := range progress.TriggeredEvents {
		if e == eventID {
			return nil
		}
	}

	progress.TriggeredEvents = append(progress.TriggeredEvents, eventID)
	return r.Update(progress)
}

// VisitLocation records a location visit.
func (r *Repository) VisitLocation(playerID, region, location string) error {
	progress, err := r.GetByPlayerID(playerID)
	if err != nil {
		return err
	}

	// Update current position
	progress.CurrentRegion = region
	progress.CurrentLocation = location

	// Add to visited locations
	loc := Location{
		Region:    region,
		Location:  location,
		VisitedAt: time.Now().Unix(),
	}

	// Avoid duplicates
	for _, l := range progress.VisitedLocations {
		if l.Region == region && l.Location == location {
			return r.Update(progress)
		}
	}

	progress.VisitedLocations = append(progress.VisitedLocations, loc)
	return r.Update(progress)
}

// GetOrCreate gets existing progress or creates new one.
func (r *Repository) GetOrCreate(playerID string) (*PlayerProgress, error) {
	progress, err := r.GetByPlayerID(playerID)
	if err == sql.ErrNoRows {
		return r.Create(playerID)
	}
	return progress, err
}
