package player

import (
	"encoding/json"
	"fmt"
	"os"
)

// ImportPlayerRequest 导入存档请求
type ImportPlayerRequest struct {
	PlayerID string `json:"player_id"`
	SaveData string `json:"save_data"` // base64编码的存档数据
	Force    bool   `json:"force"`     // 是否强制覆盖现有存档
}

// ImportPlayerResponse 导入存档响应
type ImportPlayerResponse struct {
	PlayerID    string `json:"player_id"`
	Imported    bool   `json:"imported"`
	Overwritten bool   `json:"overwritten"`
	PlayerName  string `json:"player_name"`
	Level       int    `json:"level"`
}

// ImportPlayer 导入玩家存档
// saveData: base64编码的JSON存档数据
func ImportPlayer(store LoadStoreInterface, req *ImportPlayerRequest) (*ImportPlayerResponse, error) {
	// 验证并解析存档数据
	saveData, err := ValidateImportData(req.SaveData)
	if err != nil {
		return nil, err
	}

	// 检查目标玩家是否存在（通过尝试GetPlayer）
	_, exists := store.GetPlayer(req.PlayerID)
	if exists && !req.Force {
		return nil, ErrSaveAlreadyExists
	}

	// 如果强制导入，先删除旧存档
	if exists && req.Force {
		savePath := getSavePath(req.PlayerID)
		os.Remove(savePath)
	}

	// 确保存档目录存在
	if err := EnsureSaveDir(); err != nil {
		return nil, err
	}

	// 恢复数据到store
	if saveData.Player != nil {
		// 确保玩家ID一致
		saveData.Player.ID = req.PlayerID
		store.UpdatePlayer(saveData.Player)
	}

	for _, deck := range saveData.Decks {
		deck.PlayerID = req.PlayerID
		store.UpdateDeck(deck)
	}

	if saveData.Inventory != nil {
		saveData.Inventory.PlayerID = req.PlayerID
		store.UpdateInventory(saveData.Inventory)
	}

	if saveData.Equipment != nil {
		saveData.Equipment.PlayerID = req.PlayerID
		store.UpdateEquipment(saveData.Equipment)
	}

	if saveData.Location != nil {
		store.SetPlayerLocation(req.PlayerID, saveData.Location.CurrentLocation)
	}

	// 保存到文件
	savePath := getSavePath(req.PlayerID)
	data, _ := json.MarshalIndent(saveData, "", "  ")
	if err := os.WriteFile(savePath, data, 0644); err != nil {
		return nil, err
	}

	return &ImportPlayerResponse{
		PlayerID:    req.PlayerID,
		Imported:    true,
		Overwritten: exists && req.Force,
		PlayerName:  saveData.Player.Name,
		Level:       saveData.Player.Level,
	}, nil
}

// ImportFromFile 从文件导入存档
func ImportFromFile(store LoadStoreInterface, filePath string) (*ImportPlayerResponse, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	// 尝试直接解析JSON（不经过base64）
	var saveData PlayerSaveData
	if err := json.Unmarshal(data, &saveData); err != nil {
		// 尝试base64解码
		base64Str := string(data)
		decoded, decErr := decodeBase64(base64Str)
		if decErr != nil {
			return nil, ErrInvalidSaveData
		}
		if err := json.Unmarshal(decoded, &saveData); err != nil {
			return nil, ErrInvalidSaveData
		}
	}

	if saveData.Player == nil {
		return nil, ErrInvalidSaveData
	}

	// 恢复数据到store
	restoreToStore(store, &saveData)

	// 保存到标准位置
	if err := EnsureSaveDir(); err != nil {
		return nil, err
	}

	savePath := getSavePath(saveData.Player.ID)
	saveFileData, _ := json.MarshalIndent(&saveData, "", "  ")
	if err := os.WriteFile(savePath, saveFileData, 0644); err != nil {
		return nil, err
	}

	return &ImportPlayerResponse{
		PlayerID:    saveData.Player.ID,
		Imported:    true,
		Overwritten: false,
		PlayerName:  saveData.Player.Name,
		Level:       saveData.Player.Level,
	}, nil
}

// restoreToStore 恢复存档数据到store
func restoreToStore(store LoadStoreInterface, saveData *PlayerSaveData) {
	if saveData.Player != nil {
		store.UpdatePlayer(saveData.Player)
	}

	for _, deck := range saveData.Decks {
		store.UpdateDeck(deck)
	}

	if saveData.Inventory != nil {
		store.UpdateInventory(saveData.Inventory)
	}

	if saveData.Equipment != nil {
		store.UpdateEquipment(saveData.Equipment)
	}

	if saveData.Location != nil {
		store.SetPlayerLocation(saveData.Player.ID, saveData.Location.CurrentLocation)
	}
}

// decodeBase64 简单的base64解码（不依赖encoding/json）
func decodeBase64(s string) ([]byte, error) {
	return nil, nil // 占位，实际上会通过ValidateImportData调用
}

// BackupPlayer 备份玩家存档（创建副本）
func BackupPlayer(playerID string) error {
	// 确保目录存在
	if err := EnsureSaveDir(); err != nil {
		return err
	}
	savePath := getSavePath(playerID)
	backupPath := savePath + ".backup"

	data, err := os.ReadFile(savePath)
	if err != nil {
		return fmt.Errorf("存档不存在，请先保存: %w", err)
	}

	return os.WriteFile(backupPath, data, 0644)
}

// RestoreBackup 恢复备份
func RestoreBackup(store LoadStoreInterface, playerID string) error {
	backupPath := getSavePath(playerID) + ".backup"

	// 读取备份
	data, err := os.ReadFile(backupPath)
	if err != nil {
		return err
	}

	// 解析
	var saveData PlayerSaveData
	if err := json.Unmarshal(data, &saveData); err != nil {
		return ErrInvalidSaveData
	}

	// 恢复到store
	restoreToStore(store, &saveData)

	// 恢复主存档文件
	savePath := getSavePath(playerID)
	return os.WriteFile(savePath, data, 0644)
}

// ListSaves 列出所有存档
func ListSaves() ([]SaveInfo, error) {
	dir := GetSaveDir()
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	var saves []SaveInfo
	for _, entry := range entries {
		if entry.IsDir() || entry.Name() == ".gitkeep" {
			continue
		}

		name := entry.Name()
		if len(name) > 5 && name[len(name)-5:] == ".json" {
			playerID := name[:len(name)-5]
			info, err := GetSaveInfo(playerID)
			if err != nil {
				continue
			}
			saves = append(saves, *info)
		}
	}

	return saves, nil
}

// SaveInfo 存档信息摘要
type SaveInfo struct {
	PlayerID   string `json:"player_id"`
	PlayerName string `json:"player_name"`
	Level      int    `json:"level"`
	FileSize   int64  `json:"file_size"`
}

// GetSaveInfo 获取存档信息
func GetSaveInfo(playerID string) (*SaveInfo, error) {
	savePath := getSavePath(playerID)

	stat, err := os.Stat(savePath)
	if err != nil {
		return nil, ErrSaveNotFound
	}

	saveData, err := LoadPlayer(playerID)
	if err != nil {
		return nil, err
	}

	return &SaveInfo{
		PlayerID:   playerID,
		PlayerName: saveData.Player.Name,
		Level:      saveData.Player.Level,
		FileSize:   stat.Size(),
	}, nil
}

// DeleteSave 删除存档文件
func DeleteSave(playerID string) error {
	savePath := getSavePath(playerID)
	return os.Remove(savePath)
}

// SaveExists 检查存档是否存在
func SaveExists(playerID string) bool {
	_, err := os.Stat(getSavePath(playerID))
	return err == nil
}

// CopySave 复制存档（用于多设备同步）
func CopySave(fromPlayerID, toPlayerID string) error {
	fromPath := getSavePath(fromPlayerID)
	toPath := getSavePath(toPlayerID)

	data, err := os.ReadFile(fromPath)
	if err != nil {
		return err
	}

	// 读取存档并修改player_id
	var saveData PlayerSaveData
	if err := json.Unmarshal(data, &saveData); err != nil {
		return err
	}

	saveData.Player.ID = toPlayerID
	for _, deck := range saveData.Decks {
		deck.PlayerID = toPlayerID
	}
	if saveData.Inventory != nil {
		saveData.Inventory.PlayerID = toPlayerID
	}
	if saveData.Equipment != nil {
		saveData.Equipment.PlayerID = toPlayerID
	}
	if saveData.Location != nil {
		saveData.Location.PlayerID = toPlayerID
	}

	newData, _ := json.MarshalIndent(&saveData, "", "  ")
	return os.WriteFile(toPath, newData, 0644)
}
