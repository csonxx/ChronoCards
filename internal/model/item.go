package model

// ItemType 物品类型
type ItemType string

const (
	ItemTypeWeapon     ItemType = "weapon"      // 武器
	ItemTypeArmor      ItemType = "armor"       // 防具
	ItemTypeAccessory  ItemType = "accessory"   // 饰品
	ItemTypeConsumable ItemType = "consumable" // 消耗品
	ItemTypeMaterial   ItemType = "material"    // 材料
	ItemTypeQuest      ItemType = "quest"       // 任务物品
)

// Item 物品定义
type Item struct {
	ID          string       `json:"id"`
	Name        string       `json:"name"`
	Type        ItemType     `json:"type"`
	Rarity      int          `json:"rarity"`       // 1=普通 2=精良 3=稀有 4=传说
	Description string       `json:"description"`
	Icon        string       `json:"icon"`          // 图标资源路径
	Stackable   bool         `json:"stackable"`     // 是否可堆叠
	MaxStack    int          `json:"max_stack"`      // 堆叠上限
	Price       int          `json:"price"`          // 售价
	Effects     []ItemEffect `json:"effects"`        // 装备效果
}

// ItemEffect 物品效果
type ItemEffect struct {
	Type  string `json:"type"`  // "hp"|"mp"|"attack"|"defense"|"element"|"skill"
	Value int    `json:"value"`
}

// Equipment 玩家装备槽位
type Equipment struct {
	PlayerID   string `json:"player_id"`
	Weapon     *Item  `json:"weapon,omitempty"`
	Armor      *Item  `json:"armor,omitempty"`
	Accessory1 *Item  `json:"accessory1,omitempty"`
	Accessory2 *Item  `json:"accessory2,omitempty"`
}

// InventorySlot 背包格子
type InventorySlot struct {
	Item     *Item `json:"item,omitempty"`
	Count    int   `json:"count"`
	Equipped bool  `json:"equipped"` // 是否已装备在身上
}

// PlayerInventory 玩家背包
type PlayerInventory struct {
	PlayerID string          `json:"player_id"`
	Slots    []InventorySlot `json:"slots"` // 最多30格
	Capacity int             `json:"capacity"` // 最大格子数
	Coins    int             `json:"coins"` // 游戏货币（金币）
}

// DefaultInventoryCapacity 默认背包容量
const DefaultInventoryCapacity = 30
