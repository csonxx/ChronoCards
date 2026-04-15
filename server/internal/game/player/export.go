package player

import (
	"encoding/base64"
	"encoding/json"
	"os"

)

// ExportPlayerData 导出玩家存档为base64字符串
// 用于跨平台迁移、多设备同步
func ExportPlayerData(playerID string) (string, error) {
	savePath := getSavePath(playerID)

	data, err := os.ReadFile(savePath)
	if err != nil {
		if os.IsNotExist(err) {
			return "", ErrSaveNotFound
		}
		return "", err
	}

	// 序列化为JSON后做base64编码
	jsonStr := base64.StdEncoding.EncodeToString(data)
	return jsonStr, nil
}

// ExportSaveResponse 导出存档响应
type ExportSaveResponse struct {
	PlayerID  string `json:"player_id"`
	SaveData  string `json:"save_data"` // base64编码的存档数据
	Version   int    `json:"version"`  // 存档版本号，用于兼容
}

// ExportPlayer 导出玩家存档（带版本号和元数据）
func ExportPlayer(playerID string) (*ExportSaveResponse, error) {
	_, err := LoadPlayer(playerID)
	if err != nil {
		return nil, err
	}

	base64Data, err := ExportPlayerData(playerID)
	if err != nil {
		return nil, err
	}

	return &ExportSaveResponse{
		PlayerID: playerID,
		SaveData: base64Data,
		Version:  1, // 当前版本
	}, nil
}

// ImportPlayerDataRequest 导入存档请求
type ImportPlayerDataRequest struct {
	PlayerID string `json:"player_id"`
	SaveData string `json:"save_data"` // base64编码的存档数据
}

// ValidateImportData 验证导入数据是否有效
func ValidateImportData(base64Data string) (*PlayerSaveData, error) {
	// 解码base64
	data, err := base64.StdEncoding.DecodeString(base64Data)
	if err != nil {
		return nil, ErrInvalidSaveData
	}

	// 解析JSON
	var saveData PlayerSaveData
	if err := json.Unmarshal(data, &saveData); err != nil {
		return nil, ErrInvalidSaveData
	}

	// 验证必要字段
	if saveData.Player == nil {
		return nil, ErrInvalidSaveData
	}

	return &saveData, nil
}

// ExportAllSaves 导出所有存档（用于管理员备份）
func ExportAllSaves() (map[string]string, error) {
	dir := GetSaveDir()
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	result := make(map[string]string)
	for _, entry := range entries {
		if entry.IsDir() || entry.Name() == ".gitkeep" {
			continue
		}

		// 提取player_id（去掉.json后缀）
		name := entry.Name()
		if len(name) > 5 && name[len(name)-5:] == ".json" {
			playerID := name[:len(name)-5]
			data, err := ExportPlayerData(playerID)
			if err != nil {
				continue // 跳过无效存档
			}
			result[playerID] = data
		}
	}

	return result, nil
}
