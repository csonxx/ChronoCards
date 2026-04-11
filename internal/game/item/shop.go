package item

import "github.com/csonxx/ChronoCards/internal/model"

// ShopItem 商店商品
type ShopItem struct {
	Item     *model.Item `json:"item"`
	Price    int         `json:"price"`      // 实际售价（可为折扣价）
	Stock    int         `json:"stock"`      // -1表示无限
	Currency string      `json:"currency"`  // "coins"|"jinyiwei_coins"
}

// ShopService 商店服务
type ShopService struct{}

// NewShopService 创建商店服务
func NewShopService() *ShopService {
	return &ShopService{}
}

// GetShopInventory 获取商店库存
func (s *ShopService) GetShopInventory(shopType string) []ShopItem {
	switch shopType {
	case "weapon_shop":
		return WeaponShopItems
	case "armor_shop":
		return ArmorShopItems
	case "general_store":
		return GeneralStoreItems
	case "inn":
		return InnItems
	default:
		return GeneralStoreItems
	}
}

// DefaultShops 商店列表
var DefaultShops = map[string]string{
	"weapon_shop":   "武器铺",
	"armor_shop":    "防具铺",
	"general_store": "杂货铺",
	"inn":           "客栈",
}

// WeaponShopItems 武器铺商品
var WeaponShopItems = []ShopItem{
	{Item: GetItemByID("weapon_iron_sword"), Price: 100, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("weapon_steel_sword"), Price: 300, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("weapon_wudang_blade"), Price: 800, Stock: 1, Currency: "coins"},
}

// ArmorShopItems 防具铺商品
var ArmorShopItems = []ShopItem{
	{Item: GetItemByID("armor_cloth"), Price: 50, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("armor_leather"), Price: 200, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("armor_iron"), Price: 600, Stock: 2, Currency: "coins"},
}

// GeneralStoreItems 杂货铺商品
var GeneralStoreItems = []ShopItem{
	{Item: GetItemByID("potion_hp"), Price: 50, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("potion_mp"), Price: 80, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("scroll_teleport"), Price: 200, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("elixir_strength"), Price: 150, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("material_iron_ore"), Price: 10, Stock: -1, Currency: "coins"},
	{Item: GetItemByID("material_herb"), Price: 15, Stock: -1, Currency: "coins"},
}

// InnItems 客栈商品（主要为恢复类）
var InnItems = []ShopItem{
	{Item: GetItemByID("potion_hp"), Price: 60, Stock: -1, Currency: "coins"},   // 比杂货铺略贵
	{Item: GetItemByID("potion_mp"), Price: 100, Stock: -1, Currency: "coins"},  // 比杂货铺略贵
}

// BuyItem 购买物品（简化版本，实际需要处理金币扣除）
func (s *ShopService) BuyItem(playerCoins int, itemID string, count int) (int, error) {
	for _, shopItems := range [][]ShopItem{WeaponShopItems, ArmorShopItems, GeneralStoreItems, InnItems} {
		for _, shopItem := range shopItems {
			if shopItem.Item.ID == itemID {
				totalPrice := shopItem.Price * count
				if playerCoins < totalPrice {
					return 0, ErrInsufficientCount
				}
				return totalPrice, nil
			}
		}
	}
	return 0, ErrItemNotFound
}
