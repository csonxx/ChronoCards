package deck

import (
	"testing"
)

// TestLuzheStateMachine_NewPlayerState 测试创建新玩家状态
func TestLuzheStateMachine_NewPlayerState(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	state := sm.NewPlayerState("player-001")
	
	if state == nil {
		t.Fatal("Expected non-nil state")
	}
	if state.PlayerID != "player-001" {
		t.Errorf("Expected PlayerID 'player-001', got '%s'", state.PlayerID)
	}
	if state.CharacterID != "luzhe" {
		t.Errorf("Expected CharacterID 'luzhe', got '%s'", state.CharacterID)
	}
	if state.CurrentPhase != LuzhePhaseIdle {
		t.Errorf("Expected CurrentPhase 'idle', got '%s'", state.CurrentPhase)
	}
	if state.TrialCount != 0 {
		t.Errorf("Expected TrialCount 0, got %d", state.TrialCount)
	}
	if state.TrustLevel != 0 {
		t.Errorf("Expected TrustLevel 0, got %d", state.TrustLevel)
	}
}

// TestLuzheStateMachine_ShouldTriggerEncounter_FirstJiangnanEntry 测试首次进入江南触发
func TestLuzheStateMachine_ShouldTriggerEncounter_FirstJiangnanEntry(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	// 创建首次进入江南的玩家上下文
	ctx := NewPlayerLocationContext(
		"player-001",
		"loc-suzhou",
		"region-jiangnan",
		[]string{"loc-suzhou", "loc-gaibang"}, // 两个地点都标记为已访问
		[]string{}, // 从未访问过任何区域
		nil,
	)
	
	// 初始状态为空
	existingState := sm.NewPlayerState("player-001")
	
	shouldTrigger, reason := sm.ShouldTriggerEncounter(ctx, existingState)
	
	if !shouldTrigger {
		t.Error("Expected ShouldTriggerEncounter to return true for first Jiangnan entry")
	}
	if reason != "first_jiangnan_entry" {
		t.Errorf("Expected reason 'first_jiangnan_entry', got '%s'", reason)
	}
}

// TestLuzheStateMachine_ShouldTriggerEncounter_AlreadyTriggered 测试重复触发不触发
func TestLuzheStateMachine_ShouldTriggerEncounter_AlreadyTriggered(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	ctx := NewPlayerLocationContext(
		"player-001",
		"loc-suzhou",
		"region-jiangnan",
		[]string{},
		[]string{},
		nil,
	)
	
	// 已有非idle状态
	existingState := &LuzhePlayerState{
		PlayerID:    "player-001",
		CurrentPhase: LuzhePhaseTrialStarted,
	}
	
	shouldTrigger, reason := sm.ShouldTriggerEncounter(ctx, existingState)
	
	if shouldTrigger {
		t.Error("Expected ShouldTriggerEncounter to return false when already triggered")
	}
	if reason != "" {
		t.Errorf("Expected empty reason, got '%s'", reason)
	}
}

// TestLuzheStateMachine_ShouldTriggerEncounter_FirstSuzhou 测试首次进入苏州触发
func TestLuzheStateMachine_ShouldTriggerEncounter_FirstSuzhou(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	// 苏州城上下文
	ctx := NewPlayerLocationContext(
		"player-001",
		"loc-suzhou",
		"region-central-plains",
		[]string{}, // 从未访问过苏州
		[]string{"region-central-plains"},
		nil,
	)
	
	existingState := sm.NewPlayerState("player-001")
	
	shouldTrigger, reason := sm.ShouldTriggerEncounter(ctx, existingState)
	
	if !shouldTrigger {
		t.Error("Expected ShouldTriggerEncounter to return true for first Suzhou entry")
	}
	if reason != "first_suzhou_entry" {
		t.Errorf("Expected reason 'first_gaibang_entry', got '%s'", reason)
	}
}

// TestLuzheStateMachine_ShouldTriggerEncounter_FirstGaibang 测试首次进入丐帮触发
func TestLuzheStateMachine_ShouldTriggerEncounter_FirstGaibang(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	ctx := NewPlayerLocationContext(
		"player-001",
		"loc-gaibang",
		"region-central-plains",
		[]string{},
		[]string{"region-central-plains"},
		nil,
	)
	
	existingState := sm.NewPlayerState("player-001")
	
	shouldTrigger, reason := sm.ShouldTriggerEncounter(ctx, existingState)
	
	if !shouldTrigger {
		t.Error("Expected ShouldTriggerEncounter to return true for first Gaibang entry")
	}
	if reason != "first_gaibang_entry" {
		t.Errorf("Expected reason 'first_gaibang_entry', got '%s'", reason)
	}
}

// TestLuzheStateMachine_EvaluateTrial 测试考验评估
func TestLuzheStateMachine_EvaluateTrial(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	tests := []struct {
		scores    *LuzheTrialScores
		expected  bool
		name      string
	}{
		{&LuzheTrialScores{YiQi: 2, YongQi: 2, ZhiHui: 0}, true, "通过义气和勇气"},
		{&LuzheTrialScores{YiQi: 2, YongQi: 0, ZhiHui: 2}, true, "通过义气和智谋"},
		{&LuzheTrialScores{YiQi: 0, YongQi: 2, ZhiHui: 2}, true, "通过勇气和智谋"},
		{&LuzheTrialScores{YiQi: 1, YongQi: 1, ZhiHui: 1}, false, "各1分不通过"},
		{&LuzheTrialScores{YiQi: 2, YongQi: 1, ZhiHui: 1}, false, "只通过义气"},
		{&LuzheTrialScores{YiQi: 0, YongQi: 0, ZhiHui: 0}, false, "全0分"},
	}
	
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			result := sm.EvaluateTrial(tc.scores)
			if result != tc.expected {
				t.Errorf("Expected %v, got %v", tc.expected, result)
			}
		})
	}
}

// TestLuzheStateMachine_AdvancePhase_IdleToTrialStarted 测试阶段转换：idle到trial_started
func TestLuzheStateMachine_AdvancePhase_IdleToTrialStarted(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	state := &LuzhePlayerState{
		PlayerID:    "player-001",
		CurrentPhase: LuzhePhaseIdle,
		TrustLevel:  0,
		CardHistory: []string{},
	}
	
	newState := sm.AdvancePhase(state, "encounter_triggered")
	
	if newState.CurrentPhase != LuzhePhaseTrialStarted {
		t.Errorf("Expected phase 'trial_started', got '%s'", newState.CurrentPhase)
	}
	if newState.TrustLevel != 10 {
		t.Errorf("Expected TrustLevel 10, got %d", newState.TrustLevel)
	}
	if len(newState.CardHistory) != 1 {
		t.Errorf("Expected 1 card in history, got %d", len(newState.CardHistory))
	}
}

// TestLuzheStateMachine_AdvancePhase_TrialPassed 测试阶段转换：trial_started到trial_passed
func TestLuzheStateMachine_AdvancePhase_TrialPassed(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	state := &LuzhePlayerState{
		PlayerID:    "player-001",
		CurrentPhase: LuzhePhaseTrialStarted,
		TrustLevel:  10,
		CardHistory: []string{"char-luzhe-001"},
	}
	
	newState := sm.AdvancePhase(state, "trial_passed")
	
	if newState.CurrentPhase != LuzhePhaseTrialPassed {
		t.Errorf("Expected phase 'trial_passed', got '%s'", newState.CurrentPhase)
	}
	if newState.TrustLevel != 30 {
		t.Errorf("Expected TrustLevel 30, got %d", newState.TrustLevel)
	}
}

// TestLuzheStateMachine_AdvancePhase_TrialFailed 测试阶段转换：trial_started到trial_failed
func TestLuzheStateMachine_AdvancePhase_TrialFailed(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	state := &LuzhePlayerState{
		PlayerID:    "player-001",
		CurrentPhase: LuzhePhaseTrialStarted,
		TrialCount:   0,
		CardHistory: []string{"char-luzhe-001"},
	}
	
	newState := sm.AdvancePhase(state, "trial_failed")
	
	if newState.CurrentPhase != LuzhePhaseTrialFailed {
		t.Errorf("Expected phase 'trial_failed', got '%s'", newState.CurrentPhase)
	}
	if newState.TrialCount != 1 {
		t.Errorf("Expected TrialCount 1, got %d", newState.TrialCount)
	}
}

// TestLuzheStateMachine_AdvancePhase_TrialRetry 测试考验重试
func TestLuzheStateMachine_AdvancePhase_TrialRetry(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	state := &LuzhePlayerState{
		PlayerID:    "player-001",
		CurrentPhase: LuzhePhaseTrialFailed,
		TrialCount:   2, // 少于3次，可以重试
	}
	
	newState := sm.AdvancePhase(state, "trial_retry")
	
	if newState.CurrentPhase != LuzhePhaseTrialStarted {
		t.Errorf("Expected phase 'trial_started' after retry, got '%s'", newState.CurrentPhase)
	}
}

// TestLuzheStateMachine_IsEventLineComplete 测试事件线完成判断
func TestLuzheStateMachine_IsEventLineComplete(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	tests := []struct {
		phase    LuzhePhase
		expected bool
	}{
		{LuzhePhaseIdle, false},
		{LuzhePhaseTrialStarted, false},
		{LuzhePhaseTrialPassed, false},
		{LuzhePhaseTrialFailed, false},
		{LuzhePhaseRevealed, false},
		{LuzhePhaseClimax, false},
		{LuzhePhaseEnding, true},
	}
	
	for _, tc := range tests {
		state := &LuzhePlayerState{CurrentPhase: tc.phase}
		result := sm.IsEventLineComplete(state)
		if result != tc.expected {
			t.Errorf("Phase %s: expected %v, got %v", tc.phase, tc.expected, result)
		}
	}
}

// TestLuzheStateMachine_CanShowNegotiationOption 测试协商选项显示判断
func TestLuzheStateMachine_CanShowNegotiationOption(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	tests := []struct {
		trustLevel int
		phase      LuzhePhase
		expected   bool
	}{
		{80, LuzhePhaseClimax, true},
		{79, LuzhePhaseClimax, false},
		{80, LuzhePhaseRevealed, false},
		{100, LuzhePhaseEnding, false},
	}
	
	for _, tc := range tests {
		state := &LuzhePlayerState{
			TrustLevel:  tc.trustLevel,
			CurrentPhase: tc.phase,
		}
		result := sm.CanShowNegotiationOption(state)
		if result != tc.expected {
			t.Errorf("TrustLevel %d, Phase %s: expected %v, got %v",
				tc.trustLevel, tc.phase, tc.expected, result)
		}
	}
}

// TestLuzheStateMachine_CheckTrigger 测试完整触发检查
func TestLuzheStateMachine_CheckTrigger(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	// 首次进入江南
	ctx := NewPlayerLocationContext(
		"player-001",
		"loc-suzhou",
		"region-jiangnan",
		[]string{},
		[]string{},
		nil,
	)
	
	existingState := sm.NewPlayerState("player-001")
	
	result := sm.CheckTrigger(ctx, existingState)
	
	if !result.ShouldTrigger {
		t.Error("Expected ShouldTrigger to be true for first Jiangnan entry")
	}
	if result.Card == nil {
		t.Error("Expected Card to be non-nil")
	}
	if result.Reason == "" {
		t.Error("Expected non-empty Reason")
	}
}

// TestLuzheStateMachine_TrialScoresJSON 测试考验分数序列化
func TestLuzheStateMachine_TrialScoresJSON(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	scores := &LuzheTrialScores{
		YiQi:   2,
		YongQi: 3,
		ZhiHui: 1,
	}
	
	jsonStr := sm.TrialScoresJSON(scores)
	
	if jsonStr == "" {
		t.Error("Expected non-empty JSON string")
	}
	
	// 反序列化验证
	parsed := sm.ParseTrialScores(jsonStr)
	if parsed == nil {
		t.Fatal("Expected non-nil parsed scores")
	}
	if parsed.YiQi != 2 {
		t.Errorf("Expected YiQi 2, got %d", parsed.YiQi)
	}
	if parsed.YongQi != 3 {
		t.Errorf("Expected YongQi 3, got %d", parsed.YongQi)
	}
	if parsed.ZhiHui != 1 {
		t.Errorf("Expected ZhiHui 1, got %d", parsed.ZhiHui)
	}
}

// TestLuzheStateMachine_ParseTrialScores_Empty 测试空JSON解析
func TestLuzheStateMachine_ParseTrialScores_Empty(t *testing.T) {
	sm := NewLuzheStateMachine()
	
	result := sm.ParseTrialScores("")
	if result != nil {
		t.Error("Expected nil for empty string")
	}
	
	result = sm.ParseTrialScores("{}")
	if result != nil {
		t.Error("Expected nil for empty object")
	}
}
