package world

import (
	"testing"
)

// TestMVPRegions_DataIntegrity 测试MVP Regions数据完整性
func TestMVPRegions_DataIntegrity(t *testing.T) {
	if len(MVPRegions) == 0 {
		t.Fatal("Expected at least one region in MVPRegions")
	}
	
	for _, region := range MVPRegions {
		if region.ID == "" {
			t.Error("Region ID should not be empty")
		}
		if region.Name == "" {
			t.Error("Region Name should not be empty")
		}
		if region.Description == "" {
			t.Error("Region Description should not be empty")
		}
	}
}

// TestMVPLocations_DataIntegrity 测试MVP Locations数据完整性
func TestMVPLocations_DataIntegrity(t *testing.T) {
	if len(MVPLocations) == 0 {
		t.Fatal("Expected at least one location in MVPLocations")
	}
	
	for _, loc := range MVPLocations {
		if loc.ID == "" {
			t.Error("Location ID should not be empty")
		}
		if loc.Name == "" {
			t.Error("Location Name should not be empty")
		}
		if loc.RegionID == "" {
			t.Error("Location RegionID should not be empty")
		}
		if loc.LocationType == "" {
			t.Error("Location LocationType should not be empty")
		}
	}
}

// TestMVPConnections_DataIntegrity 测试MVP Connections数据完整性
func TestMVPConnections_DataIntegrity(t *testing.T) {
	if len(MVPConnections) == 0 {
		t.Fatal("Expected at least one connection in MVPConnections")
	}
	
	for _, conn := range MVPConnections {
		if conn.ID == "" {
			t.Error("Connection ID should not be empty")
		}
		if conn.FromLocation == "" {
			t.Error("Connection FromLocation should not be empty")
		}
		if conn.ToLocation == "" {
			t.Error("Connection ToLocation should not be empty")
		}
	}
}

// TestGetLocationByID 测试根据ID获取Location
func TestGetLocationByID(t *testing.T) {
	loc := GetLocationByID("loc-pingyang")
	if loc == nil {
		t.Fatal("Expected non-nil location for 'loc-pingyang'")
	}
	if loc.Name != "平阳城" {
		t.Errorf("Expected name '平阳城', got '%s'", loc.Name)
	}
	
	// 测试不存在的ID
	loc = GetLocationByID("non-existent")
	if loc != nil {
		t.Error("Expected nil for non-existent location ID")
	}
}

// TestGetRegionByID 测试根据Id获取Region
func TestGetRegionByID(t *testing.T) {
	region := GetRegionByID("region-central-plains")
	if region == nil {
		t.Fatal("Expected non-nil region for 'region-central-plains'")
	}
	if region.Name != "中原武林" {
		t.Errorf("Expected name '中原武林', got '%s'", region.Name)
	}
	
	// 测试不存在的ID
	region = GetRegionByID("non-existent")
	if region != nil {
		t.Error("Expected nil for non-existent region ID")
	}
}

// TestLocation_Unlocked 测试场景解锁状态
func TestLocation_Unlocked(t *testing.T) {
	// 平阳城应该已解锁
	loc := GetLocationByID("loc-pingyang")
	if loc == nil {
		t.Fatal("Expected non-nil location")
	}
	if !loc.Unlocked {
		t.Error("Expected loc-pingyang to be unlocked")
	}
	
	// 武当山应该未解锁
	loc = GetLocationByID("loc-wudang")
	if loc == nil {
		t.Fatal("Expected non-nil location")
	}
	if loc.Unlocked {
		t.Error("Expected loc-wudang to be locked")
	}
}

// TestLocationConnection_Unlocked 测试连接解锁状态
func TestLocationConnection_Unlocked(t *testing.T) {
	// 武当山 <-> 少林寺 路径应该未解锁
	for _, conn := range MVPConnections {
		if conn.FromLocation == "loc-wudang" && conn.ToLocation == "loc-shaolin" {
			if conn.Unlocked {
				t.Error("Expected wudang-shaolin connection to be locked")
			}
		}
	}
}

// TestLocation_AvailableDealers 测试场景可用的发牌员
func TestLocation_AvailableDealers(t *testing.T) {
	loc := GetLocationByID("loc-pingyang")
	if loc == nil {
		t.Fatal("Expected non-nil location")
	}
	
	if len(loc.AvailableDealers) == 0 {
		t.Error("Expected at least one available dealer for loc-pingyang")
	}
	
	// 检查特定发牌员类型存在
	hasTeahouse := false
	for _, dealer := range loc.AvailableDealers {
		if dealer == "teahouse" {
			hasTeahouse = true
			break
		}
	}
	if !hasTeahouse {
		t.Error("Expected teahouse dealer to be available at loc-pingyang")
	}
}

// TestNavigateResult_Structure 测试导航结果结构
func TestNavigateResult_Structure(t *testing.T) {
	result := &NavigateResult{
		Success:            true,
		FromLocationID:     "loc-pingyang",
		ToLocationID:       "loc-inn-anchor",
		EncounterTriggered: false,
		Message:           "抵达平阳客栈",
	}
	
	if !result.Success {
		t.Error("Expected Success to be true")
	}
	if result.FromLocationID != "loc-pingyang" {
		t.Errorf("Expected FromLocationID 'loc-pingyang', got '%s'", result.FromLocationID)
	}
	if result.ToLocationID != "loc-inn-anchor" {
		t.Errorf("Expected ToLocationID 'loc-inn-anchor', got '%s'", result.ToLocationID)
	}
}

// TestLuzheTriggerLocation 测试陆喆触发场景
func TestLuzheTriggerLocation(t *testing.T) {
	triggerLocs := []string{
		"loc-suzhou",
	}
	
	for _, locID := range triggerLocs {
		loc := GetLocationByID(locID)
		if loc == nil {
			t.Errorf("Expected non-nil location for '%s'", locID)
		}
	}
}

// TestMVPLocations_HasDangerLevels 测试场景危险等级
func TestMVPLocations_HasDangerLevels(t *testing.T) {
	for _, loc := range MVPLocations {
		if loc.DangerLevel < 0 || loc.DangerLevel > 5 {
			t.Errorf("Location %s has invalid danger level %d (expected 0-5)",
				loc.ID, loc.DangerLevel)
		}
	}
}

// TestMVPConnections_HasTravelTimes 测试连接有旅行时间
func TestMVPConnections_HasTravelTimes(t *testing.T) {
	for _, conn := range MVPConnections {
		if conn.TravelTimeMin < 0 {
			t.Errorf("Connection %s has invalid travel time %d",
				conn.ID, conn.TravelTimeMin)
		}
	}
}
