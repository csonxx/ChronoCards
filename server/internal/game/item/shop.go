package item

import "github.com/csonxx/ChronoCards/internal/model"

// ShopItem 商店商品
type ShopItem struct {
	Item      *model.Item `json:"item"`
	Price     int         `json:"price"`
	Stock     int         `json:"stock"`      // -1=无限
	Currency  string      `json:"currency"`  // coins/jinyiwei
}

// ShopInventories 商店库存
var ShopInventories = map[string][]ShopItem{
	"general_store": {
		{Item: MustGetItem("potion_hp"), Price: 50, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("potion_mp"), Price: 80, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("scroll_teleport"), Price: 200, Stock: 10, Currency: "coins"},
		{Item: MustGetItem("daliwan"), Price: 150, Stock: -1, Currency: "coins"},
	},
	"weapon_shop": {
		{Item: MustGetItem("weapon_iron_sword"), Price: 200, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("weapon_steel_sword"), Price: 800, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("weapon_wudang_blade"), Price: 3000, Stock: 3, Currency: "coins"},
	},
	"armor_shop": {
		{Item: MustGetItem("armor_cloth"), Price: 100, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("armor_leather"), Price: 500, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("armor_iron"), Price: 1500, Stock: 5, Currency: "coins"},
	},
	"inn": {
		{Item: MustGetItem("potion_hp"), Price: 60, Stock: -1, Currency: "coins"},
		{Item: MustGetItem("potion_mp"), Price: 100, Stock: -1, Currency: "coins"},
	},
}

// MustGetItem 安全获取物品
func MustGetItem(id string) *model.Item {
	item := GetPresetItem(id)
	if item == nil {
		return &model.Item{ID: id, Name: id, Type: model.ItemTypeMaterial, Rarity: 1, Price: 0}
	}
	return item
}
