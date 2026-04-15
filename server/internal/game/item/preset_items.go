package item

import "github.com/csonxx/ChronoCards/server/internal/model"

// MVPItems MVP版本预设物品列表
var MVPItems = []model.Item{
	// === 武器 ===
	{
		ID:          "weapon_iron_sword",
		Name:        "铁剑",
		Type:        model.ItemTypeWeapon,
		Rarity:      1,
		Description: "最基础的铁剑，江湖新人常用",
		Icon:        "icons/weapon_iron_sword.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       100,
		Effects: []model.ItemEffect{
			{Type: "attack", Value: 5},
		},
	},
	{
		ID:          "weapon_steel_sword",
		Name:        "钢剑",
		Type:        model.ItemTypeWeapon,
		Rarity:      2,
		Description: "精钢打造，比铁剑锋利许多",
		Icon:        "icons/weapon_steel_sword.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       300,
		Effects: []model.ItemEffect{
			{Type: "attack", Value: 12},
		},
	},
	{
		ID:          "weapon_wudang_blade",
		Name:        "武当剑",
		Type:        model.ItemTypeWeapon,
		Rarity:      3,
		Description: "武当派制式长剑，剑身刻有太极图案",
		Icon:        "icons/weapon_wudang_blade.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       800,
		Effects: []model.ItemEffect{
			{Type: "attack", Value: 25},
			{Type: "mp", Value: 10},
		},
	},
	{
		ID:          "weapon_mingjiao_blade",
		Name:        "圣火令",
		Type:        model.ItemTypeWeapon,
		Rarity:      4,
		Description: "明教至宝，蕴含圣火之力",
		Icon:        "icons/weapon_mingjiao_blade.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       2000,
		Effects: []model.ItemEffect{
			{Type: "attack", Value: 40},
			{Type: "fire", Value: 15},
		},
	},

	// === 防具 ===
	{
		ID:          "armor_cloth",
		Name:        "布衣",
		Type:        model.ItemTypeArmor,
		Rarity:      1,
		Description: "普通布料制成的衣物，防护有限",
		Icon:        "icons/armor_cloth.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       50,
		Effects: []model.ItemEffect{
			{Type: "defense", Value: 2},
		},
	},
	{
		ID:          "armor_leather",
		Name:        "皮甲",
		Type:        model.ItemTypeArmor,
		Rarity:      2,
		Description: "皮革缝制的轻甲，适合江湖行走",
		Icon:        "icons/armor_leather.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       200,
		Effects: []model.ItemEffect{
			{Type: "defense", Value: 8},
		},
	},
	{
		ID:          "armor_iron",
		Name:        "铁甲",
		Type:        model.ItemTypeArmor,
		Rarity:      3,
		Description: "铁片铆接的铠甲，防护性强但略显笨重",
		Icon:        "icons/armor_iron.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       600,
		Effects: []model.ItemEffect{
			{Type: "defense", Value: 18},
			{Type: "stamina", Value: -5},
		},
	},

	// === 饰品 ===
	{
		ID:          "accessory_jade_ring",
		Name:        "玉佩",
		Type:        model.ItemTypeAccessory,
		Rarity:      1,
		Description: "普通玉石制成的佩饰",
		Icon:        "icons/accessory_jade_ring.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       80,
		Effects: []model.ItemEffect{
			{Type: "mp", Value: 5},
		},
	},
	{
		ID:          "accessory_silver_bracelet",
		Name:        "银镯",
		Type:        model.ItemTypeAccessory,
		Rarity:      2,
		Description: "纯银打造，有驱邪之效",
		Icon:        "icons/accessory_silver_bracelet.png",
		Stackable:   false,
		MaxStack:    1,
		Price:       250,
		Effects: []model.ItemEffect{
			{Type: "mp", Value: 15},
			{Type: "hp", Value: 10},
		},
	},

	// === 消耗品 ===
	{
		ID:          "potion_hp",
		Name:        "疗伤丹",
		Type:        model.ItemTypeConsumable,
		Rarity:      1,
		Description: "服用后恢复50点生命值",
		Icon:        "icons/potion_hp.png",
		Stackable:   true,
		MaxStack:    10,
		Price:       50,
		Effects: []model.ItemEffect{
			{Type: "hp", Value: 50},
		},
	},
	{
		ID:          "potion_mp",
		Name:        "回蓝丹",
		Type:        model.ItemTypeConsumable,
		Rarity:      1,
		Description: "服用后恢复30点内力",
		Icon:        "icons/potion_mp.png",
		Stackable:   true,
		MaxStack:    10,
		Price:       80,
		Effects: []model.ItemEffect{
			{Type: "mp", Value: 30},
		},
	},
	{
		ID:          "scroll_teleport",
		Name:        "传送符",
		Type:        model.ItemTypeConsumable,
		Rarity:      2,
		Description: "使用后可传送回主城存档点",
		Icon:        "icons/scroll_teleport.png",
		Stackable:   true,
		MaxStack:    5,
		Price:       200,
		Effects: []model.ItemEffect{
			{Type: "teleport", Value: 1},
		},
	},
	{
		ID:          "elixir_strength",
		Name:        "大力丸",
		Type:        model.ItemTypeConsumable,
		Rarity:      2,
		Description: "临时提升10点攻击力，持续一场战斗",
		Icon:        "icons/elixir_strength.png",
		Stackable:   true,
		MaxStack:    5,
		Price:       150,
		Effects: []model.ItemEffect{
			{Type: "attack", Value: 10},
			{Type: "buff", Value: 1},
		},
	},

	// === 材料 ===
	{
		ID:          "material_iron_ore",
		Name:        "铁矿石",
		Type:        model.ItemTypeMaterial,
		Rarity:      1,
		Description: "可用于锻造武器的基础材料",
		Icon:        "icons/material_iron_ore.png",
		Stackable:   true,
		MaxStack:    99,
		Price:       10,
		Effects:     []model.ItemEffect{},
	},
	{
		ID:          "material_herb",
		Name:        "灵草",
		Type:        model.ItemTypeMaterial,
		Rarity:      1,
		Description: "生长于深山的灵药，可炼丹",
		Icon:        "icons/material_herb.png",
		Stackable:   true,
		MaxStack:    99,
		Price:       15,
		Effects:     []model.ItemEffect{},
	},
}

// ItemMap 物品ID到物品的映射，方便查找
var ItemMap = make(map[string]*model.Item)

func init() {
	for i := range MVPItems {
		ItemMap[MVPItems[i].ID] = &MVPItems[i]
	}
}

// GetItemByID 根据ID获取物品
func GetItemByID(id string) *model.Item {
	return ItemMap[id]
}
