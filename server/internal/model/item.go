package model

// ItemType 物品类型
type ItemType string

const (
	ItemTypeWeapon     ItemType = "weapon"
	ItemTypeArmor     ItemType = "armor"
	ItemTypeAccessory ItemType = "accessory"
	ItemTypeConsumable ItemType = "consumable"
	ItemTypeMaterial  ItemType = "material"
	ItemTypeQuest     ItemType = "quest"
)

// Item 物品定义
type Item struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	Type        ItemType   `json:"type"`
	Rarity      int        `json:"rarity"` // 1=普通 2=精良 3=稀有 4=传说
	Description string     `json:"description"`
	Icon        string     `json:"icon,omitempty"`
	Stackable   bool       `json:"stackable"`
	MaxStack    int        `json:"max_stack"`
	Price       int        `json:"price"`
	Effects     []ItemEffect `json:"effects,omitempty"`
}

// ItemEffect 物品效果
type ItemEffect struct {
	Type  string `json:"type"` // hp/mp/attack/defense/element/skill
	Value int    `json:"value"`
}

// Equipment 玩家装备槽位
type Equipment struct {
	PlayerID    string `json:"player_id"`
	Weapon      *Item  `json:"weapon,omitempty"`
	Armor       *Item  `json:"armor,omitempty"`
	Accessory1  *Item  `json:"accessory1,omitempty"`
	Accessory2  *Item  `json:"accessory2,omitempty"`
}

// InventorySlot 背包格子
type InventorySlot struct {
	Item     *Item  `json:"item,omitempty"`
	Count    int    `json:"count"`
	Equipped bool   `json:"equipped"`
}

// PlayerInventory 玩家背包
type PlayerInventory struct {
	PlayerID string          `json:"player_id"`
	Slots    []InventorySlot `json:"slots"` // 最多30格
	Capacity int             `json:"capacity"`
	Coins    int             `json:"coins"`
}

// NewInventory 创建新背包
func NewInventory(playerID string) *PlayerInventory {
	return &PlayerInventory{
		PlayerID: playerID,
		Slots:    make([]InventorySlot, 0, 30),
		Capacity: 30,
		Coins:    100, // 初始金币
	}
}

// FindSlotByItemID 查找指定物品的槽位
func (inv *PlayerInventory) FindSlotByItemID(itemID string) int {
	for i, slot := range inv.Slots {
		if slot.Item != nil && slot.Item.ID == itemID && !slot.Equipped {
			return i
		}
	}
	return -1
}

// FindEmptySlot 查找空槽位
func (inv *PlayerInventory) FindEmptySlot() int {
	for i, slot := range inv.Slots {
		if slot.Item == nil {
			return i
		}
	}
	if len(inv.Slots) < inv.Capacity {
		inv.Slots = append(inv.Slots, InventorySlot{})
		return len(inv.Slots) - 1
	}
	return -1 // 背包满
}

// CanAddItem 检查是否能添加物品
func (inv *PlayerInventory) CanAddItem(itemID string, count int) bool {
	return inv.FindEmptySlot() >= 0
}

// AddItem 添加物品
func (inv *PlayerInventory) AddItem(item *Item, count int) bool {
	if item.Stackable {
		slotIdx := inv.FindSlotByItemID(item.ID)
		if slotIdx >= 0 {
			inv.Slots[slotIdx].Count += count
			if inv.Slots[slotIdx].Count > item.MaxStack {
				inv.Slots[slotIdx].Count = item.MaxStack
			}
			return true
		}
	}
	slotIdx := inv.FindEmptySlot()
	if slotIdx < 0 {
		return false
	}
	inv.Slots[slotIdx] = InventorySlot{Item: item, Count: count}
	return true
}

// RemoveItem 移除物品
func (inv *PlayerInventory) RemoveItem(itemID string, count int) bool {
	slotIdx := inv.FindSlotByItemID(itemID)
	if slotIdx < 0 {
		return false
	}
	inv.Slots[slotIdx].Count -= count
	if inv.Slots[slotIdx].Count <= 0 {
		inv.Slots[slotIdx] = InventorySlot{}
	}
	return true
}
