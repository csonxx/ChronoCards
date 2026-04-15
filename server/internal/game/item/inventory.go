package item

import (
	"errors"

	"github.com/csonxx/ChronoCards/server/internal/model"
	"github.com/csonxx/ChronoCards/server/internal/store"
)

var (
	ErrInventoryFull     = errors.New("inventory is full")
	ErrItemNotFound      = errors.New("item not found")
	ErrInsufficientCount = errors.New("insufficient item count")
	ErrNotStackable      = errors.New("item is not stackable")
	ErrInvalidSlot       = errors.New("invalid slot index")
	ErrSlotEmpty         = errors.New("slot is empty")
	ErrInvalidEquipType  = errors.New("invalid equipment type for this item")
	ErrNotEquipped       = errors.New("item is not equipped")
)

// InventoryService 背包服务
type InventoryService struct {
	store store.StoreInterface
}

// NewInventoryService 创建背包服务
func NewInventoryService(s store.StoreInterface) *InventoryService {
	return &InventoryService{store: s}
}

// GetInventory 获取玩家背包
func (s *InventoryService) GetInventory(playerID string) *model.PlayerInventory {
	inv, ok := s.store.GetInventory(playerID)
	if !ok {
		// 创建默认背包
		inv = &model.PlayerInventory{
			PlayerID: playerID,
			Slots:    make([]model.InventorySlot, 0, 30),
			Capacity: 30,
			Coins:    0,
		}
		// 初始化30个空格子
		for i := 0; i < 30; i++ {
			inv.Slots = append(inv.Slots, model.InventorySlot{})
		}
		s.store.CreateInventory(inv)
	}
	return inv
}

// GetEquipment 获取玩家装备
func (s *InventoryService) GetEquipment(playerID string) *model.Equipment {
	eq, ok := s.store.GetEquipment(playerID)
	if !ok {
		eq = &model.Equipment{PlayerID: playerID}
		s.store.CreateEquipment(eq)
	}
	return eq
}

// AddItem 添加物品到背包
func (s *InventoryService) AddItem(playerID string, item *model.Item, count int) error {
	if count <= 0 {
		return nil
	}

	inv := s.GetInventory(playerID)
	remain := count

	// 优先处理可堆叠物品，尝试合并到已有槽位
	if item.Stackable {
		for i := range inv.Slots {
			slot := &inv.Slots[i]
			if slot.Item != nil && slot.Item.ID == item.ID && !slot.Equipped {
				// 找到相同物品，可以合并
				canAdd := item.MaxStack - slot.Count
				if canAdd > 0 {
					toAdd := min(canAdd, remain)
					slot.Count += toAdd
					remain -= toAdd
				}
				if remain <= 0 {
					s.store.UpdateInventory(inv)
					return nil
				}
			}
		}
	}

	// 剩余物品放入空格子
	for i := range inv.Slots {
		slot := &inv.Slots[i]
		if slot.Item == nil && !slot.Equipped {
			// 空格子
			toAdd := min(item.MaxStack, remain)
			slot.Item = item
			slot.Count = toAdd
			slot.Equipped = false
			remain -= toAdd
			if remain <= 0 {
				s.store.UpdateInventory(inv)
				return nil
			}
			// 如果是可堆叠物品且还有剩余，继续找空格子
			if !item.Stackable {
				// 不可堆叠物品，一个格子只能放一个
				continue
			}
		}
	}

	// 还有剩余说明背包满了
	if remain > 0 {
		return ErrInventoryFull
	}

	s.store.UpdateInventory(inv)
	return nil
}

// RemoveItem 从背包移除物品
func (s *InventoryService) RemoveItem(playerID string, itemID string, count int) error {
	if count <= 0 {
		return nil
	}

	inv := s.GetInventory(playerID)
	totalHave := 0

	// 统计物品总数
	for _, slot := range inv.Slots {
		if slot.Item != nil && slot.Item.ID == itemID && !slot.Equipped {
			totalHave += slot.Count
		}
	}

	if totalHave < count {
		return ErrInsufficientCount
	}

	remain := count

	// 从后往前移除（模拟消耗）
	for i := len(inv.Slots) - 1; i >= 0 && remain > 0; i-- {
		slot := &inv.Slots[i]
		if slot.Item != nil && slot.Item.ID == itemID && !slot.Equipped {
			toRemove := min(slot.Count, remain)
			slot.Count -= toRemove
			remain -= toRemove
			if slot.Count <= 0 {
				slot.Item = nil
			}
		}
	}

	s.store.UpdateInventory(inv)
	return nil
}

// HasItem 检查物品是否足够
func (s *InventoryService) HasItem(playerID string, itemID string, count int) bool {
	inv := s.GetInventory(playerID)
	total := 0
	for _, slot := range inv.Slots {
		if slot.Item != nil && slot.Item.ID == itemID && !slot.Equipped {
			total += slot.Count
		}
	}
	return total >= count
}

// EquipItem 装备物品
func (s *InventoryService) EquipItem(playerID string, slotIndex int) (*model.Equipment, error) {
	inv := s.GetInventory(playerID)

	if slotIndex < 0 || slotIndex >= len(inv.Slots) {
		return nil, ErrInvalidSlot
	}

	targetSlot := &inv.Slots[slotIndex]
	if targetSlot.Item == nil {
		return nil, ErrSlotEmpty
	}
	if targetSlot.Equipped {
		return nil, ErrNotStackable // 已经装备了
	}

	item := targetSlot.Item
	// 检查物品类型
	var equipSlot string
	switch item.Type {
	case model.ItemTypeWeapon:
		equipSlot = "weapon"
	case model.ItemTypeArmor:
		equipSlot = "armor"
	case model.ItemTypeAccessory:
		// 饰品可以装两个，先找空的
		equipSlot = "accessory1" // 默认accessory1
	default:
		return nil, ErrInvalidEquipType
	}

	eq := s.GetEquipment(playerID)

	// 处理饰品槽位选择
	if item.Type == model.ItemTypeAccessory {
		if eq.Accessory1 == nil {
			equipSlot = "accessory1"
		} else if eq.Accessory2 == nil {
			equipSlot = "accessory2"
		} else {
			// 两个饰品槽都满了，替换accessory1
			equipSlot = "accessory1"
		}
	}

	// 检查是否需要卸下现有装备
	switch equipSlot {
	case "weapon":
		if eq.Weapon != nil {
			// 卸下原装备到背包
			s.UnequipItem(playerID, model.ItemTypeWeapon)
		}
		eq.Weapon = item
	case "armor":
		if eq.Armor != nil {
			s.UnequipItem(playerID, model.ItemTypeArmor)
		}
		eq.Armor = item
	case "accessory1":
		if eq.Accessory1 != nil {
			s.UnequipItem(playerID, model.ItemTypeAccessory)
		}
		eq.Accessory1 = item
	case "accessory2":
		if eq.Accessory2 != nil {
			// 卸下原装备到背包（通过accessory1槽位，实际上accessory2无法直接卸到1）
			// 简化处理：accessory2 替换 accessory1，原有移到背包
			oldAcc := eq.Accessory1
			eq.Accessory1 = eq.Accessory2
			eq.Accessory2 = item
			// 把accessory1放回背包
			if oldAcc != nil {
				targetSlot.Item = oldAcc
				targetSlot.Count = 1
				s.store.UpdateInventory(inv)
				s.store.UpdateEquipment(eq)
				return eq, nil
			}
		} else {
			eq.Accessory1 = item
		}
		// 饰品从slotIndex移除
		targetSlot.Item = nil
		targetSlot.Count = 0
		targetSlot.Equipped = true
		s.store.UpdateInventory(inv)
		s.store.UpdateEquipment(eq)
		return eq, nil
	}

	// 标记背包格子中的物品为已装备
	targetSlot.Item = nil
	targetSlot.Count = 0
	targetSlot.Equipped = true

	s.store.UpdateInventory(inv)
	s.store.UpdateEquipment(eq)
	return eq, nil
}

// UnequipItem 卸下装备
func (s *InventoryService) UnequipItem(playerID string, slotType model.ItemType) (*model.InventorySlot, error) {
	eq := s.GetEquipment(playerID)

	var item *model.Item
	var equipSlot string

	switch slotType {
	case model.ItemTypeWeapon:
		item = eq.Weapon
		eq.Weapon = nil
		equipSlot = "weapon"
	case model.ItemTypeArmor:
		item = eq.Armor
		eq.Armor = nil
		equipSlot = "armor"
	case model.ItemTypeAccessory:
		// 优先卸下accessory1
		if eq.Accessory1 != nil {
			item = eq.Accessory1
			eq.Accessory1 = eq.Accessory2
			eq.Accessory2 = nil
			equipSlot = "accessory1"
		} else if eq.Accessory2 != nil {
			item = eq.Accessory2
			eq.Accessory2 = nil
			equipSlot = "accessory2"
		}
	default:
		return nil, ErrInvalidEquipType
	}

	if item == nil {
		return nil, ErrNotEquipped
	}

	s.store.UpdateEquipment(eq)

	// 添加到背包
	if err := s.AddItem(playerID, item, 1); err != nil {
		// 背包满了，装备无法卸下
		// 恢复装备状态
		switch equipSlot {
		case "weapon":
			eq.Weapon = item
		case "armor":
			eq.Armor = item
		case "accessory1":
			eq.Accessory1 = item
		case "accessory2":
			eq.Accessory2 = item
		}
		s.store.UpdateEquipment(eq)
		return nil, ErrInventoryFull
	}

	// 找到放回背包的格子
	inv := s.GetInventory(playerID)
	for i := range inv.Slots {
		if inv.Slots[i].Item != nil && inv.Slots[i].Item.ID == item.ID && !inv.Slots[i].Equipped {
			return &inv.Slots[i], nil
		}
	}

	// 找到空格子
	for i := range inv.Slots {
		if inv.Slots[i].Item == nil {
			inv.Slots[i].Item = item
			inv.Slots[i].Count = 1
			inv.Slots[i].Equipped = false
			s.store.UpdateInventory(inv)
			return &inv.Slots[i], nil
		}
	}

	return nil, ErrInventoryFull
}

// UseItem 使用消耗品
func (s *InventoryService) UseItem(playerID string, itemID string, count int) error {
	if count <= 0 {
		return nil
	}

	// 检查物品是否存在且为消耗品
	item := GetItemByID(itemID)
	if item == nil {
		return ErrItemNotFound
	}
	if item.Type != model.ItemTypeConsumable {
		return ErrInvalidEquipType
	}

	// 检查物品数量
	if !s.HasItem(playerID, itemID, count) {
		return ErrInsufficientCount
	}

	// 移除物品
	if err := s.RemoveItem(playerID, itemID, count); err != nil {
		return err
	}

	// 应用效果
	// 注意：这里只是记录效果，实际应用需要在业务逻辑中处理
	// 例如 hp 效果需要在调用方更新玩家属性

	return nil
}

// CalculateStats 计算玩家（含装备加成）的战斗属性
func (s *InventoryService) CalculateStats(player *model.Player, equipment *model.Equipment) PlayerStats {
	stats := PlayerStats{
		ElementBonus: make(map[string]int),
	}

	if equipment == nil {
		return stats
	}

	// 遍历所有装备槽位
	slots := []*model.Item{
		equipment.Weapon,
		equipment.Armor,
		equipment.Accessory1,
		equipment.Accessory2,
	}

	for _, item := range slots {
		if item == nil {
			continue
		}
		for _, effect := range item.Effects {
			switch effect.Type {
			case "attack":
				stats.AttackBonus += effect.Value
			case "defense":
				stats.DefenseBonus += effect.Value
			case "hp":
				stats.HPBonus += effect.Value
			case "mp":
				stats.MPBonus += effect.Value
			case "wind", "fire", "water", "thunder", "ice", "poison":
				stats.ElementBonus[effect.Type] += effect.Value
			}
		}
	}

	return stats
}

// PlayerStats 玩家战斗属性（含装备加成）
type PlayerStats struct {
	AttackBonus   int            `json:"attack_bonus"`
	DefenseBonus  int            `json:"defense_bonus"`
	HPBonus       int            `json:"hp_bonus"`
	MPBonus       int            `json:"mp_bonus"`
	ElementBonus  map[string]int `json:"element_bonus"`
}
