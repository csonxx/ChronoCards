-- Player Progress Tracking System
-- Migration 003: PlayerProgress table

-- PlayerProgress stores persistent player progress data
CREATE TABLE IF NOT EXISTS player_progress (
    player_id          TEXT PRIMARY KEY,
    unlocked_skills    TEXT NOT NULL DEFAULT '[]',  -- JSON array of skill IDs
    triggered_events   TEXT NOT NULL DEFAULT '[]',  -- JSON array of event IDs
    visited_locations  TEXT NOT NULL DEFAULT '[]',  -- JSON array of location objects
    current_region     TEXT NOT NULL DEFAULT '',
    current_location   TEXT NOT NULL DEFAULT '',
    created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster region queries
CREATE INDEX IF NOT EXISTS idx_player_progress_region ON player_progress(current_region);

-- Function to update timestamp
CREATE TRIGGER IF NOT EXISTS update_player_progress_timestamp 
AFTER UPDATE ON player_progress
BEGIN
    UPDATE player_progress SET updated_at = CURRENT_TIMESTAMP WHERE player_id = NEW.player_id;
END;
