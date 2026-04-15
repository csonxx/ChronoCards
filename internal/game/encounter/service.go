package encounter

import (
	"math/rand"
	"sync"
	"time"

	"github.com/csonxx/ChronoCards/internal/model"
)

// Service 动态遭遇服务（程序化发牌员生成）
type Service struct {
	pool   *model.DynamicEncounterPool
	active map[string][]*model.DynamicEncounter // location -> encounters
	mu     sync.RWMutex
}

// NewService 创建服务
func NewService(seed int64) *Service {
	s := &Service{
		pool:   model.NewDynamicEncounterPool(seed),
		active: make(map[string][]*model.DynamicEncounter),
	}
	// 启动过期清理
	go s.cleanupLoop()
	return s
}

// GenerateEncounter 生成一个遭遇
func (s *Service) GenerateEncounter(location string, playerLevel int) *model.DynamicEncounter {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	enc := s.pool.GenerateEncounter(location, playerLevel)
	if enc == nil {
		return nil
	}
	
	// 添加到活跃列表
	s.active[location] = append(s.active[location], enc)
	
	return enc
}

// GenerateMultiple 生成多个遭遇
func (s *Service) GenerateMultiple(count int, location string, playerLevel int) []*model.DynamicEncounter {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	encounters := s.pool.GenerateMultiple(count, location, playerLevel)
	for _, enc := range encounters {
		s.active[location] = append(s.active[location], enc)
	}
	
	return encounters
}

// GetActiveEncounters 获取地点的活跃遭遇
func (s *Service) GetActiveEncounters(location string) []*model.DynamicEncounter {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	encounters := s.active[location]
	var valid []*model.DynamicEncounter
	now := time.Now()
	
	for _, enc := range encounters {
		// 过滤已过期和已触发的
		if !enc.Triggered && enc.ExpiresAt.After(now) {
			valid = append(valid, enc)
		}
	}
	
	return valid
}

// MarkTriggered 标记遭遇已触发
func (s *Service) MarkTriggered(encounterID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	for _, encounters := range s.active {
		for _, enc := range encounters {
			if enc.ID == encounterID {
				enc.Triggered = true
				return
			}
		}
	}
}

// RemoveEncounter 移除遭遇
func (s *Service) RemoveEncounter(location string, encounterID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	encounters := s.active[location]
	for i, enc := range encounters {
		if enc.ID == encounterID {
			// 使用append删除元素
			s.active[location] = append(encounters[:i], encounters[i+1:]...)
			return
		}
	}
}

// cleanupLoop 定期清理过期遭遇
func (s *Service) cleanupLoop() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	
	for range ticker.C {
		s.cleanup()
	}
}

// cleanup 清理过期遭遇
func (s *Service) cleanup() {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	now := time.Now()
	for location, encounters := range s.active {
		var valid []*model.DynamicEncounter
		for _, enc := range encounters {
			if enc.ExpiresAt.After(now) {
				valid = append(valid, enc)
			}
		}
		s.active[location] = valid
	}
}

// GetPoolStats 获取遭遇池统计
func (s *Service) GetPoolStats() map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	stats := map[string]interface{}{
		"active_count": 0,
		"by_type":      map[string]int{},
		"by_location":  map[string]int{},
	}
	
	now := time.Now()
	total := 0
	typeCount := map[string]int{}
	locCount := map[string]int{}
	
	for location, encounters := range s.active {
		for _, enc := range encounters {
			if !enc.Triggered && enc.ExpiresAt.After(now) {
				total++
				typeCount[string(enc.Type)]++
				locCount[location]++
			}
		}
	}
	
	stats["active_count"] = total
	stats["by_type"] = typeCount
	stats["by_location"] = locCount
	
	return stats
}

// DealerResponse 发牌员交互响应
type DealerResponse struct {
	Encounter *model.DynamicEncounter `json:"encounter"`
	Dealer    *model.Dealer          `json:"dealer"`
	CanCombat bool                   `json:"can_combat"`
	CanTrade bool                    `json:"can_trade"`
	CanQuest bool                    `json:"can_quest"`
	Message  string                  `json:"message"`
}

// InteractWithEncounter 与遭遇交互
func (s *Service) InteractWithEncounter(location string, encounterID string) *DealerResponse {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	var target *model.DynamicEncounter
	for _, enc := range s.active[location] {
		if enc.ID == encounterID {
			target = enc
			break
		}
	}
	
	if target == nil {
		return &DealerResponse{
			Message: "遭遇不存在或已过期",
		}
	}
	
	// 标记为已触发
	target.Triggered = true
	
	return &DealerResponse{
		Encounter: target,
		Dealer:    &target.Dealer,
		CanCombat: target.Config.CanCombat,
		CanTrade:  target.Config.CanTrade,
		CanQuest:  target.Config.CanQuest,
		Message:   target.Dealer.InteractionPrompt,
	}
}

// RandomEncounterType 随机遭遇类型（用于快速选择）
func RandomEncounterType(rng *rand.Rand) model.DynamicEncounterType {
	types := []model.DynamicEncounterType{
		model.EncounterBandits,
		model.EncounterTraveler,
		model.EncounterBeast,
		model.EncounterMerchant,
		model.EncounterRefugee,
		model.EncounterMysterious,
	}
	return types[rng.Intn(len(types))]
}
