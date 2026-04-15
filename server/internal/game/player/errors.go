package player

import "errors"

// 存档相关错误
var (
	ErrPlayerNotFound     = errors.New("player not found")
	ErrSaveNotFound       = errors.New("save file not found")
	ErrSaveAlreadyExists  = errors.New("save already exists, use force to overwrite")
	ErrInvalidSaveData    = errors.New("invalid save data")
	ErrSaveOperationFailed = errors.New("save operation failed")
)
