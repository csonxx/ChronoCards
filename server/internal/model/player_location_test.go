package model

import (
	"testing"
)

// TestNewPlayerLocation 测试创建玩家位置
func TestNewPlayerLocation(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	if pl == nil {
		t.Fatal("Expected non-nil player location")
	}
	if pl.PlayerID != "player-001" {
		t.Errorf("Expected PlayerID 'player-001', got '%s'", pl.PlayerID)
	}
	if pl.CurrentLocation != "loc-pingyang" {
		t.Errorf("Expected CurrentLocation 'loc-pingyang', got '%s'", pl.CurrentLocation)
	}
	if pl.CurrentRegion != "region-central-plains" {
		t.Errorf("Expected CurrentRegion 'region-central-plains', got '%s'", pl.CurrentRegion)
	}
	if pl.InBattle {
		t.Error("Expected InBattle to be false initially")
	}
	if len(pl.VisitedLocations) != 1 {
		t.Errorf("Expected 1 visited location initially, got %d", len(pl.VisitedLocations))
	}
	if len(pl.VisitedRegions) != 1 {
		t.Errorf("Expected 1 visited region initially, got %d", len(pl.VisitedRegions))
	}
	if pl.TotalTravelCount != 0 {
		t.Errorf("Expected TotalTravelCount 0, got %d", pl.TotalTravelCount)
	}
}

// TestPlayerLocation_AddVisited_NewLocation 测试添加新访问位置
func TestPlayerLocation_AddVisited_NewLocation(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	pl.AddVisited("loc-wudang", "region-central-plains")
	
	if len(pl.VisitedLocations) != 2 {
		t.Errorf("Expected 2 visited locations, got %d", len(pl.VisitedLocations))
	}
	
	// 检查包含新位置
	found := false
	for _, loc := range pl.VisitedLocations {
		if loc == "loc-wudang" {
			found = true
			break
		}
	}
	if !found {
		t.Error("Expected loc-wudang to be in visited locations")
	}
}

// TestPlayerLocation_AddVisited_Duplicate 测试重复添加位置
func TestPlayerLocation_AddVisited_Duplicate(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	// 添加相同位置两次
	pl.AddVisited("loc-wudang", "region-central-plains")
	pl.AddVisited("loc-wudang", "region-central-plains")
	
	// 不应该重复
	if len(pl.VisitedLocations) != 2 {
		t.Errorf("Expected 2 visited locations, got %d", len(pl.VisitedLocations))
	}
}

// TestPlayerLocation_AddVisited_NewRegion 测试添加新访问区域
func TestPlayerLocation_AddVisited_NewRegion(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	pl.AddVisited("loc-suzhou", "region-jiangnan")
	
	if len(pl.VisitedRegions) != 2 {
		t.Errorf("Expected 2 visited regions, got %d", len(pl.VisitedRegions))
	}
	
	// 检查包含新区域
	found := false
	for _, reg := range pl.VisitedRegions {
		if reg == "region-jiangnan" {
			found = true
			break
		}
	}
	if !found {
		t.Error("Expected region-jiangnan to be in visited regions")
	}
}

// TestPlayerLocation_AddVisited_SameRegion 测试添加相同区域
func TestPlayerLocation_AddVisited_SameRegion(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	// 添加同一区域的不同位置
	pl.AddVisited("loc-wudang", "region-central-plains")
	
	// 区域数不应该增加
	if len(pl.VisitedRegions) != 1 {
		t.Errorf("Expected 1 visited region, got %d", len(pl.VisitedRegions))
	}
}

// TestPlayerLocation_UnlockLocation_New 测试解锁新场景
func TestPlayerLocation_UnlockLocation_New(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	pl.UnlockLocation("loc-wudang")
	
	if len(pl.UnlockedLocations) != 2 {
		t.Errorf("Expected 2 unlocked locations, got %d", len(pl.UnlockedLocations))
	}
	
	// 检查已解锁
	if !pl.IsLocationUnlocked("loc-wudang") {
		t.Error("Expected loc-wudang to be unlocked")
	}
}

// TestPlayerLocation_UnlockLocation_Duplicate 测试重复解锁
func TestPlayerLocation_UnlockLocation_Duplicate(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	pl.UnlockLocation("loc-pingyang")
	pl.UnlockLocation("loc-pingyang")
	
	if len(pl.UnlockedLocations) != 1 {
		t.Errorf("Expected 1 unlocked location, got %d", len(pl.UnlockedLocations))
	}
}

// TestPlayerLocation_IsLocationUnlocked 测试检查场景是否解锁
func TestPlayerLocation_IsLocationUnlocked(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	// 初始位置应该已解锁
	if !pl.IsLocationUnlocked("loc-pingyang") {
		t.Error("Expected loc-pingyang to be unlocked")
	}
	
	// 未解锁的位置
	if pl.IsLocationUnlocked("loc-wudang") {
		t.Error("Expected loc-wudang to be locked")
	}
}

// TestPlayerLocation_IsLocationUnlocked_AfterUnlock 测试解锁后检查
func TestPlayerLocation_IsLocationUnlocked_AfterUnlock(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	pl.UnlockLocation("loc-wudang")
	
	if !pl.IsLocationUnlocked("loc-wudang") {
		t.Error("Expected loc-wudang to be unlocked after UnlockLocation")
	}
}

// TestPlayerLocation_DefaultUnlocked 测试初始解锁列表
func TestPlayerLocation_DefaultUnlocked(t *testing.T) {
	pl := NewPlayerLocation("player-001", "loc-pingyang", "region-central-plains")
	
	// 初始位置应该在解锁列表中
	if !pl.IsLocationUnlocked("loc-pingyang") {
		t.Error("Expected initial location to be in unlocked list")
	}
}
