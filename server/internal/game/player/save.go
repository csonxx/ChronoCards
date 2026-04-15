package player

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/csonxx/ChronoCards/server/internal/model"
)

// PlayerSaveData 玩家存档数据结构（包含所有需要持久化的数据）
type PlayerSaveData struct {
	Player     *model.Player          `json:"player"`
	Decks      []*model.Deck          `json:"decks"`
	Inventory  *model.PlayerInventory `json:"inventory"`
	Equipment  *model.Equipment       `json:"equipment"`
	Location   *model.PlayerLocation  `json:"location"`
}

// GetSaveDir 获取存档目录
func GetSaveDir() string {
	return "saves"
}

// EnsureSaveDir 确保存档目录存在
func EnsureSaveDir() error {
	dir := GetSaveDir()
	return os.MkdirAll(dir, 0755)
}

// getSavePath 获取玩家存档文件路径
func getSavePath(playerID string) string {
	return filepath.Join(GetSaveDir(), playerID+".json")
}

// SavePlayer 保存玩家存档到JSON文件
// 包含玩家数据、卡组、背包、装备、位置
func SavePlayer(store SaveStoreInterface, playerID string) error {
	if err := EnsureSaveDir(); err != nil {
		return err
	}

	// 获取玩家数据
	player, ok := store.GetPlayer(playerID)
	if !ok {
		return ErrPlayerNotFound
	}

	// 获取卡组列表
	decks := store.GetDecksByPlayer(playerID)

	// 获取背包
	inv, _ := store.GetInventory(playerID)
	if inv == nil {
		inv = &model.PlayerInventory{
			PlayerID: playerID,
			Slots:    []model.InventorySlot{},
			Capacity: 30,
			Coins:    player.Money,
		}
	}

	// 获取装备
	eq, _ := store.GetEquipment(playerID)
	if eq == nil {
		eq = &model.Equipment{PlayerID: playerID}
	}

	// 获取位置
	loc, _ := store.GetPlayerLocation(playerID)
	if loc == nil {
		loc = &model.PlayerLocation{
			PlayerID:       playerID,
			CurrentLocation: "start-location",
			CurrentRegion:  "region-central-plains",
			VisitedLocations: []string{},
			VisitedRegions: []string{},
		}
	}

	// 组装存档数据
	saveData := &PlayerSaveData{
		Player:    player,
		Decks:     decks,
		Inventory: inv,
		Equipment: eq,
		Location:  loc,
	}

	// 序列化为JSON
	data, err := json.MarshalIndent(saveData, "", "  ")
	if err != nil {
		return err
	}

	// 写入文件
	savePath := getSavePath(playerID)
	return os.WriteFile(savePath, data, 0644)
}

// SaveStoreInterface 存档服务需要的存储接口
type SaveStoreInterface interface {
	GetPlayer(id string) (*model.Player, bool)
	GetDecksByPlayer(playerID string) []*model.Deck
	GetInventory(playerID string) (*model.PlayerInventory, bool)
	GetEquipment(playerID string) (*model.Equipment, bool)
	GetPlayerLocation(playerID string) (*model.PlayerLocation, error)
}
