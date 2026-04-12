package item

import (
	"fmt"

	"github.com/csonxx/ChronoCards/internal/model"
	"github.com/csonxx/ChronoCards/internal/store"
)

// Service 物品服务
type Service struct {
	store store.StoreInterface
}

// NewService 创建物品服务
func NewService(s store.StoreInterface) *Service {
	return &Service{store: s}
}

// GetInventory 获取玩家背包
func (s *Service) GetInventory(playerID string) *model.PlayerInventory {
	inv, _ := s.store.GetInventory(playerID)
	if inv != nil {
		return inv
	}
	inv = model.NewInventory(playerID)
	s.store.CreateInventory(inv)
	return inv
}

// AddItem 添加物品
func (s *Service) AddItem(playerID string, itemID string, count int) error {
	item := GetPresetItem(itemID)
	if item == nil {
		return fmt.Errorf("物品不存在: %s", itemID)
	}
	inv := s.GetInventory(playerID)
	if !inv.AddItem(item, count) {
		return fmt.Errorf("背包已满")
	}
	s.store.UpdateInventory(inv)
	return nil
}

// UseItem 使用物品
func (s *Service) UseItem(playerID string, itemID string, count int) (*model.Player, error) {
	inv := s.GetInventory(playerID)
	if !inv.RemoveItem(itemID, count) {
		return nil, fmt.Errorf("物品不足")
	}
	s.store.UpdateInventory(inv)

	player, _ := s.store.GetPlayer(playerID)
	if player == nil {
		return nil, fmt.Errorf("玩家不存在")
	}

	item := GetPresetItem(itemID)
	if item == nil {
		return player, nil
	}

	for _, effect := range item.Effects {
		switch effect.Type {
		case "hp":
			player.HP = min(player.HP+effect.Value, player.MaxHP)
		case "mp":
			player.MP = min(player.MP+effect.Value, player.MaxMP)
		case "attack":
			// 临时攻击加成（不持久化，MVP简化处理）
		case "coins":
			inv.Coins += effect.Value
		}
	}
	s.store.UpdatePlayer(player)
	return player, nil
}

// EquipItem 装备物品
func (s *Service) EquipItem(playerID string, slotIndex int) (*model.Equipment, error) {
	inv := s.GetInventory(playerID)
	if slotIndex < 0 || slotIndex >= len(inv.Slots) || inv.Slots[slotIndex].Item == nil {
		return nil, fmt.Errorf("无效的背包槽位")
	}
	item := inv.Slots[slotIndex].Item
	if item.Type != model.ItemTypeWeapon && item.Type != model.ItemTypeArmor && item.Type != model.ItemTypeAccessory {
		return nil, fmt.Errorf("该物品类型不可装备")
	}
	inv.Slots[slotIndex].Equipped = true

	eq, _ := s.store.GetEquipment(playerID)
	if eq == nil {
		eq = &model.Equipment{PlayerID: playerID}
	}
	switch item.Type {
	case model.ItemTypeWeapon:
		eq.Weapon = item
	case model.ItemTypeArmor:
		eq.Armor = item
	case model.ItemTypeAccessory:
		if eq.Accessory1 == nil {
			eq.Accessory1 = item
		} else {
			eq.Accessory2 = item
		}
	}
	s.store.UpdateEquipment(eq)
	s.store.UpdateInventory(inv)
	return eq, nil
}

// UnequipItem 卸下装备
func (s *Service) UnequipItem(playerID string, slotType string) (*model.InventorySlot, error) {
	eq, _ := s.store.GetEquipment(playerID)
	if eq == nil {
		return nil, fmt.Errorf("没有装备")
	}
	inv := s.GetInventory(playerID)
	var item *model.Item
	switch slotType {
	case "weapon":
		item = eq.Weapon
		eq.Weapon = nil
	case "armor":
		item = eq.Armor
		eq.Armor = nil
	case "accessory1":
		item = eq.Accessory1
		eq.Accessory1 = eq.Accessory2
		eq.Accessory2 = nil
	default:
		return nil, fmt.Errorf("无效装备槽位")
	}
	if item != nil {
		slotIdx := inv.FindEmptySlot()
		if slotIdx < 0 {
			return nil, fmt.Errorf("背包已满，无法卸下")
		}
		inv.Slots[slotIdx] = model.InventorySlot{Item: item, Count: 1, Equipped: false}
		s.store.UpdateInventory(inv)
	}
	s.store.UpdateEquipment(eq)
	slot := &model.InventorySlot{Item: item, Count: 1}
	return slot, nil
}

// GetShopInventory 获取商店商品
func (s *Service) GetShopInventory(shopType string) []ShopItem {
	if items, ok := ShopInventories[shopType]; ok {
		return items
	}
	return []ShopItem{}
}
