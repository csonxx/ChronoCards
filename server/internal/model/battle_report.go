package model

import "time"

// BattleReport 战斗报告
type BattleReport struct {
	ID          string    `json:"id"`
	PlayerID    string    `json:"player_id"`
	PlayerName  string    `json:"player_name"`
	EnemyID     string    `json:"enemy_id"`
	EnemyName   string    `json:"enemy_name"`
	Result      string    `json:"result"` // win/lose/draw
	DamageDealt int       `json:"damage_dealt"`
	DamageTaken int       `json:"damage_taken"`
	HealingDone int       `json:"healing_done"`
	KillCount   int       `json:"kill_count"`
	DurationSec int       `json:"duration_sec"` // 战斗持续秒数
	Timestamp   time.Time `json:"timestamp"`
}

// LeaderboardEntry 排行榜条目
type LeaderboardEntry struct {
	Rank      int    `json:"rank"`
	PlayerID  string `json:"player_id"`
	PlayerName string `json:"player_name"`
	Level     int    `json:"level"`
	Score     int    `json:"score"` // 战斗力/积分
	GuildName string `json:"guild_name,omitempty"`
}

// LeaderboardType 排行榜类型
type LeaderboardType string

const (
	LeaderboardPower  LeaderboardType = "power"  // 战力榜
	LeaderboardLevel  LeaderboardType = "level"  // 等级榜
	LeaderboardPVP    LeaderboardType = "pvp"    // PVP榜
	LeaderboardGuild  LeaderboardType = "guild"  // 公会榜
)

// Talent 天赋
type Talent struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Tier        int    `json:"tier"` // 1-5
	Effects     []TalentEffect `json:"effects"`
}

// TalentEffect 天赋效果
type TalentEffect struct {
	Type  string `json:"type"`  // hp/mp/attack/defense/element
	Value int    `json:"value"`
}

// Friend 好友关系
type Friend struct {
	PlayerID    string    `json:"player_id"`
	FriendID    string    `json:"friend_id"`
	FriendName  string    `json:"friend_name"`
	Status      string    `json:"status"` // online/offline/in_game
	Level       int       `json:"level"`
	CreatedAt   time.Time `json:"created_at"`
}

// Guild 工会/门派
type Guild struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	LeaderID    string    `json:"leader_id"`
	MemberCount int       `json:"member_count"`
	MaxMembers  int       `json:"max_members"`
	Level       int       `json:"level"`
	Exp         int       `json:"exp"`
	Faction     string    `json:"faction"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

// GuildMember 工会成员
type GuildMember struct {
	PlayerID   string    `json:"player_id"`
	PlayerName string    `json:"player_name"`
	GuildID    string    `json:"guild_id"`
	Rank       string    `json:"rank"` // leader/officer/member
	Contrib    int       `json:"contribution"`
	JoinedAt   time.Time `json:"joined_at"`
}
