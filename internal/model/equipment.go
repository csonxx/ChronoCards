package model

import "time"

// EquipmentSlotType 装备槽位类型
type EquipmentSlotType string

const (
	EquipSlotWeapon     EquipmentSlotType = "weapon"
	EquipSlotArmor      EquipmentSlotType = "armor"
	EquipSlotAccessory1 EquipmentSlotType = "accessory1"
	EquipSlotAccessory2 EquipmentSlotType = "accessory2"
)

// EquipmentSlot 装备槽位
type EquipmentSlot struct {
	Type       EquipmentSlotType `json:"type"`        // 槽位类型
	ItemID     string            `json:"item_id"`     // 装备的物品ID（为空表示空槽）
	EquippedAt time.Time         `json:"equipped_at"` // 装备时间
}

// PlayerEquipment 玩家装备数据
type PlayerEquipment struct {
	PlayerID  string          `json:"player_id"`
	Slots     map[EquipmentSlotType]*EquipmentSlot `json:"slots"` // 槽位映射
	StatsBonus PlayerStatsBonus `json:"stats_bonus"` // 来自装备的属性加成
}

// PlayerStatsBonus 装备属性加成汇总
type PlayerStatsBonus struct {
	Attack   int `json:"attack"`   // 攻击加成
	Defense  int `json:"defense"`  // 防御加成
	MaxHP    int `json:"max_hp"`   // 生命上限加成
	MaxMP    int `json:"max_mp"`   // 内力上限加成
	Wind     int `json:"wind"`     // 风元素精通
	Fire     int `json:"fire"`     // 火元素精通
	Water    int `json:"water"`    // 水元素精通
	Thunder  int `json:"thunder"`  // 雷元素精通
	Ice      int `json:"ice"`      // 冰元素精通
	Poison   int `json:"poison"`   // 毒元素精通
}

// NewPlayerEquipment 创建空装备数据
func NewPlayerEquipment(playerID string) *PlayerEquipment {
	return &PlayerEquipment{
		PlayerID: playerID,
		Slots: map[EquipmentSlotType]*EquipmentSlot{
			EquipSlotWeapon:     {Type: EquipSlotWeapon},
			EquipSlotArmor:      {Type: EquipSlotArmor},
			EquipSlotAccessory1: {Type: EquipSlotAccessory1},
			EquipSlotAccessory2: {Type: EquipSlotAccessory2},
		},
		StatsBonus: PlayerStatsBonus{},
	}
}

// EquipItem 装备物品到槽位
func (e *PlayerEquipment) EquipItem(slotType EquipmentSlotType, itemID string) {
	if slot, ok := e.Slots[slotType]; ok {
		slot.ItemID = itemID
		slot.EquippedAt = time.Now()
	}
}

// UnequipItem 卸下槽位装备
func (e *PlayerEquipment) UnequipItem(slotType EquipmentSlotType) {
	if slot, ok := e.Slots[slotType]; ok {
		slot.ItemID = ""
	}
}

// GetEquippedItemIDs 获取所有已装备的物品ID
func (e *PlayerEquipment) GetEquippedItemIDs() []string {
	var ids []string
	for _, slot := range e.Slots {
		if slot.ItemID != "" {
			ids = append(ids, slot.ItemID)
		}
	}
	return ids
}

// IsSlotEmpty 检查槽位是否为空
func (e *PlayerEquipment) IsSlotEmpty(slotType EquipmentSlotType) bool {
	if slot, ok := e.Slots[slotType]; ok {
		return slot.ItemID == ""
	}
	return true
}
