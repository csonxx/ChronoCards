package player

import (
	"encoding/json"
	"os"

	"github.com/csonxx/ChronoCards/server/internal/model"
)

// LoadPlayer 从JSON文件加载玩家存档
// 返回存档数据（需要调用方自行恢复到store）
func LoadPlayer(playerID string) (*PlayerSaveData, error) {
	savePath := getSavePath(playerID)

	data, err := os.ReadFile(savePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrSaveNotFound
		}
		return nil, err
	}

	var saveData PlayerSaveData
	if err := json.Unmarshal(data, &saveData); err != nil {
		return nil, err
	}

	return &saveData, nil
}

// LoadAndRestorePlayer 从JSON文件加载存档并恢复到store
func LoadAndRestorePlayer(store LoadStoreInterface, playerID string) error {
	saveData, err := LoadPlayer(playerID)
	if err != nil {
		return err
	}

	// 恢复玩家数据
	if saveData.Player != nil {
		store.UpdatePlayer(saveData.Player)
	}

	// 恢复卡组
	for _, deck := range saveData.Decks {
		store.UpdateDeck(deck)
	}

	// 恢复背包
	if saveData.Inventory != nil {
		store.UpdateInventory(saveData.Inventory)
	}

	// 恢复装备
	if saveData.Equipment != nil {
		store.UpdateEquipment(saveData.Equipment)
	}

	// 恢复位置
	if saveData.Location != nil {
		store.SetPlayerLocation(playerID, saveData.Location.CurrentLocation)
	}

	return nil
}

// LoadStoreInterface 加载存档需要的存储接口
type LoadStoreInterface interface {
	GetPlayer(id string) (*model.Player, bool)
	UpdatePlayer(player *model.Player)
	UpdateDeck(deck *model.Deck)
	UpdateInventory(inv *model.PlayerInventory)
	UpdateEquipment(eq *model.Equipment)
	SetPlayerLocation(playerID, locationID string) error
}
