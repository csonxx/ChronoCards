package equipment

import (
	"github.com/csonxx/ChronoCards/internal/game/item"
	"github.com/csonxx/ChronoCards/internal/model"
)

// Service 装备系统服务
type Service struct{}

// NewService 创建服务
func NewService() *Service {
	return &Service{}
}

// EquipResponse 装备操作结果
type EquipResponse struct {
	Success   bool                  `json:"success"`
	Slot      model.EquipmentSlotType `json:"slot"`
	Item      *model.Item           `json:"item,omitempty"`
	OldItem   *model.Item           `json:"old_item,omitempty"`
	StatsBonus model.PlayerStatsBonus `json:"stats_bonus"`
	Message   string                `json:"message"`
}

// EquipItem 装备物品
func (s *Service) EquipItem(eq *model.PlayerEquipment, inv *model.PlayerInventory, slotType model.EquipmentSlotType, itemID string) *EquipResponse {
	resp := &EquipResponse{Slot: slotType}
	
	// 获取物品
	presetItem := item.GetPresetItem(itemID)
	if presetItem == nil {
		resp.Success = false
		resp.Message = "物品不存在"
		return resp
	}
	
	// 检查物品类型是否匹配槽位
	if !s.isItemValidForSlot(presetItem.Type, slotType) {
		resp.Success = false
		resp.Message = "该物品无法装备到此槽位"
		return resp
	}
	
	// 获取背包中的物品实例
	found := s.findItemInInventory(inv, itemID)
	if found == nil {
		resp.Success = false
		resp.Message = "背包中没有该物品"
		return resp
	}
	
	// 获取当前槽位装备
	currentItemID := eq.Slots[slotType].ItemID
	var oldItem *model.Item
	if currentItemID != "" {
		oldItem = item.GetPresetItem(currentItemID)
		// 卸载旧装备放回背包
		if oldItem != nil {
			inv.AddItem(oldItem, 1)
		}
	}
	
	// 装备新物品
	eq.EquipItem(slotType, itemID)
	
	// 从背包移除
	inv.RemoveItem(itemID, 1)
	
	// 重新计算属性加成
	eq.StatsBonus = s.calculateStatsBonus(eq, inv)
	
	resp.Success = true
	resp.Item = presetItem
	resp.OldItem = oldItem
	resp.StatsBonus = eq.StatsBonus
	resp.Message = "装备成功"
	
	return resp
}

// UnequipItem 卸下装备
func (s *Service) UnequipItem(eq *model.PlayerEquipment, inv *model.PlayerInventory, slotType model.EquipmentSlotType) *EquipResponse {
	resp := &EquipResponse{Slot: slotType}
	
	currentItemID := eq.Slots[slotType].ItemID
	if currentItemID == "" {
		resp.Success = false
		resp.Message = "该槽位没有装备"
		return resp
	}
	
	item := item.GetPresetItem(currentItemID)
	if item != nil {
		// 放回背包
		if inv.AddItem(item, 1) {
			eq.UnequipItem(slotType)
			eq.StatsBonus = s.calculateStatsBonus(eq, inv)
			resp.Success = true
			resp.OldItem = item
			resp.StatsBonus = eq.StatsBonus
			resp.Message = "已卸下"
		} else {
			resp.Success = false
			resp.Message = "背包已满"
		}
		return resp
	}
	
	resp.Success = false
	resp.Message = "物品不存在"
	return resp
}

// GetEquipmentInfo 获取完整装备信息
func (s *Service) GetEquipmentInfo(eq *model.PlayerEquipment) map[string]interface{} {
	result := make(map[string]interface{})
	
	for slotType, slot := range eq.Slots {
		slotInfo := map[string]interface{}{
			"empty": slot.ItemID == "",
		}
		if slot.ItemID != "" {
			if item := item.GetPresetItem(slot.ItemID); item != nil {
				slotInfo["item"] = item
			}
		}
		result[string(slotType)] = slotInfo
	}
	
	result["stats_bonus"] = eq.StatsBonus
	return result
}

// isItemValidForSlot 检查物品类型是否匹配槽位
func (s *Service) isItemValidForSlot(itemType model.ItemType, slotType model.EquipmentSlotType) bool {
	switch slotType {
	case model.EquipSlotWeapon:
		return itemType == model.ItemTypeWeapon
	case model.EquipSlotArmor:
		return itemType == model.ItemTypeArmor
	case model.EquipSlotAccessory1, model.EquipSlotAccessory2:
		return itemType == model.ItemTypeAccessory
	}
	return false
}

// findItemInInventory 在背包中查找物品
func (s *Service) findItemInInventory(inv *model.PlayerInventory, itemID string) *model.Item {
	for _, slot := range inv.Slots {
		if slot.Item != nil && slot.Item.ID == itemID && !slot.Equipped {
			return slot.Item
		}
	}
	return nil
}

// calculateStatsBonus 计算装备属性加成
func (s *Service) calculateStatsBonus(eq *model.PlayerEquipment, inv *model.PlayerInventory) model.PlayerStatsBonus {
	var bonus model.PlayerStatsBonus
	
	// 遍历所有装备槽位
	for _, slot := range eq.Slots {
		if slot.ItemID == "" {
			continue
		}
		
		presetItem := item.GetPresetItem(slot.ItemID)
		if presetItem == nil {
			continue
		}
		
		// 累加物品效果
		for _, effect := range presetItem.Effects {
			switch effect.Type {
			case "attack":
				bonus.Attack += effect.Value
			case "defense":
				bonus.Defense += effect.Value
			case "hp":
				bonus.MaxHP += effect.Value
			case "mp":
				bonus.MaxMP += effect.Value
			case "wind":
				bonus.Wind += effect.Value
			case "fire":
				bonus.Fire += effect.Value
			case "water":
				bonus.Water += effect.Value
			case "thunder":
				bonus.Thunder += effect.Value
			case "ice":
				bonus.Ice += effect.Value
			case "poison":
				bonus.Poison += effect.Value
			}
		}
	}
	
	return bonus
}
