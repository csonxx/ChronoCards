package item

import "github.com/csonxx/ChronoCards/internal/model"

// PresetItems 预设物品数据
var PresetItems = []model.Item{
	// === 武器 ===
	{ID: "weapon_iron_sword", Name: "铁剑", Type: model.ItemTypeWeapon, Rarity: 1,
		Description: "最基础的武器，铁制长剑，锋利度一般。", Icon: "/assets/items/weapon_iron_sword.webp",
		Stackable: false, MaxStack: 1, Price: 200,
		Effects: []model.ItemEffect{{Type: "attack", Value: 5}}},
	{ID: "weapon_steel_sword", Name: "钢剑", Type: model.ItemTypeWeapon, Rarity: 2,
		Description: "精钢打造，比铁剑锋利许多。", Icon: "/assets/items/weapon_steel_sword.webp",
		Stackable: false, MaxStack: 1, Price: 800,
		Effects: []model.ItemEffect{{Type: "attack", Value: 12}}},
	{ID: "weapon_wudang_blade", Name: "武当剑", Type: model.ItemTypeWeapon, Rarity: 3,
		Description: "武当派制式佩剑，剑身修长，剑气凌厉。", Icon: "/assets/items/weapon_wudang_blade.webp",
		Stackable: false, MaxStack: 1, Price: 3000,
		Effects: []model.ItemEffect{{Type: "attack", Value: 25}}},
	{ID: "weapon_shenghuo", Name: "圣火令", Type: model.ItemTypeWeapon, Rarity: 4,
		Description: "明教至宝，火焰纹路，传闻能引动圣火。", Icon: "/assets/items/weapon_shenghuo.webp",
		Stackable: false, MaxStack: 1, Price: 8000,
		Effects: []model.ItemEffect{{Type: "attack", Value: 40}, {Type: "element", Value: 10}}},
	// === 防具 ===
	{ID: "armor_cloth", Name: "布衣", Type: model.ItemTypeArmor, Rarity: 1,
		Description: "普通布料所制，几乎无防护。", Icon: "/assets/items/armor_cloth.webp",
		Stackable: false, MaxStack: 1, Price: 100,
		Effects: []model.ItemEffect{{Type: "defense", Value: 2}}},
	{ID: "armor_leather", Name: "皮甲", Type: model.ItemTypeArmor, Rarity: 2,
		Description: "皮革缝制，有一定防护力。", Icon: "/assets/items/armor_leather.webp",
		Stackable: false, MaxStack: 1, Price: 500,
		Effects: []model.ItemEffect{{Type: "defense", Value: 8}}},
	{ID: "armor_iron", Name: "铁甲", Type: model.ItemTypeArmor, Rarity: 3,
		Description: "铁片串联，防护优异，但较为笨重。", Icon: "/assets/items/armor_iron.webp",
		Stackable: false, MaxStack: 1, Price: 1500,
		Effects: []model.ItemEffect{{Type: "defense", Value: 20}}},
	// === 饰品 ===
	{ID: "acc_jade", Name: "玉佩", Type: model.ItemTypeAccessory, Rarity: 2,
		Description: "佩戴可宁心静气，内力恢复加快。", Icon: "/assets/items/acc_jade.webp",
		Stackable: false, MaxStack: 1, Price: 600,
		Effects: []model.ItemEffect{{Type: "mp", Value: 20}}},
	{ID: "acc_silver_bracelet", Name: "银镯", Type: model.ItemTypeAccessory, Rarity: 2,
		Description: "精银打造，佩戴者福运加身。", Icon: "/assets/items/acc_silver_bracelet.webp",
		Stackable: false, MaxStack: 1, Price: 600,
		Effects: []model.ItemEffect{{Type: "hp", Value: 30}}},
	// === 消耗品 ===
	{ID: "potion_hp", Name: "疗伤丹", Type: model.ItemTypeConsumable, Rarity: 1,
		Description: "服用后恢复50点生命值。", Icon: "/assets/items/potion_hp.webp",
		Stackable: true, MaxStack: 10, Price: 50,
		Effects: []model.ItemEffect{{Type: "hp", Value: 50}}},
	{ID: "potion_mp", Name: "回蓝丹", Type: model.ItemTypeConsumable, Rarity: 1,
		Description: "服用后恢复30点内力值。", Icon: "/assets/items/potion_mp.webp",
		Stackable: true, MaxStack: 10, Price: 80,
		Effects: []model.ItemEffect{{Type: "mp", Value: 30}}},
	{ID: "scroll_teleport", Name: "传送符", Type: model.ItemTypeConsumable, Rarity: 2,
		Description: "使用后传送到平阳城（主城）。", Icon: "/assets/items/scroll_teleport.webp",
		Stackable: true, MaxStack: 5, Price: 200,
		Effects: []model.ItemEffect{}},
	{ID: "daliwan", Name: "大力丸", Type: model.ItemTypeConsumable, Rarity: 1,
		Description: "短时间内攻击翻倍。", Icon: "/assets/items/daliwan.webp",
		Stackable: true, MaxStack: 5, Price: 150,
		Effects: []model.ItemEffect{{Type: "attack", Value: 9999}}}, // 9999表示临时buff，MVP简化处理
	// === 材料 ===
	{ID: "mat_iron_ore", Name: "铁矿石", Type: model.ItemTypeMaterial, Rarity: 1,
		Description: "普通的铁矿石，可用于锻造。", Icon: "/assets/items/mat_iron_ore.webp",
		Stackable: true, MaxStack: 99, Price: 10,
		Effects: []model.ItemEffect{}},
	{ID: "mat_grass", Name: "灵草", Type: model.ItemTypeMaterial, Rarity: 1,
		Description: "有灵气的草药，可入药。", Icon: "/assets/items/mat_grass.webp",
		Stackable: true, MaxStack: 50, Price: 20,
		Effects: []model.ItemEffect{}},
}

// GetPresetItem 根据ID获取预设物品
func GetPresetItem(id string) *model.Item {
	for i := range PresetItems {
		if PresetItems[i].ID == id {
			return &PresetItems[i]
		}
	}
	return nil
}

// AllPresetItems 返回所有预设物品
func AllPresetItems() []*model.Item {
	result := make([]*model.Item, len(PresetItems))
	for i := range PresetItems {
		result[i] = &PresetItems[i]
	}
	return result
}
