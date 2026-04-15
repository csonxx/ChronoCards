package ws

import (
	"testing"
	"time"
)

// TestAuthenticator_ValidateToken_EmptyToken 测试空token验证
func TestAuthenticator_ValidateToken_EmptyToken(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	_, err := auth.ValidateToken("")
	if err == nil {
		t.Error("Expected error for empty token, got nil")
	}
}

// TestAuthenticator_ValidateToken_ValidToken 测试有效token验证
func TestAuthenticator_ValidateToken_ValidToken(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	
	// 生成有效token
	token, err := auth.GenerateToken("player-001", 1*time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}
	
	// 验证token
	claims, err := auth.ValidateToken(token)
	if err != nil {
		t.Errorf("Expected valid token, got error: %v", err)
	}
	if claims == nil {
		t.Error("Expected claims, got nil")
	}
	if claims.PlayerID != "player-001" {
		t.Errorf("Expected player_id 'player-001', got '%s'", claims.PlayerID)
	}
}

// TestAuthenticator_ValidateToken_ExpiredToken 测试过期token验证
func TestAuthenticator_ValidateToken_ExpiredToken(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	
	// 生成已过期的token (expiresIn = -1h)
	token, err := auth.GenerateToken("player-001", -1*time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}
	
	// 验证token应该失败
	_, err = auth.ValidateToken(token)
	if err == nil {
		t.Error("Expected error for expired token, got nil")
	}
}

// TestAuthenticator_ValidateToken_WrongSecret 测试错误密钥签名的token
func TestAuthenticator_ValidateToken_WrongSecret(t *testing.T) {
	auth1 := NewAuthenticator("secret-1")
	auth2 := NewAuthenticator("secret-2")
	
	// 用auth1生成token
	token, err := auth1.GenerateToken("player-001", 1*time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}
	
	// 用auth2验证应该失败
	_, err = auth2.ValidateToken(token)
	if err == nil {
		t.Error("Expected error for wrong secret, got nil")
	}
}

// TestAuthenticator_ValidateToken_BearerPrefix 测试带Bearer前缀的token
func TestAuthenticator_ValidateToken_BearerPrefix(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	
	token, err := auth.GenerateToken("player-001", 1*time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}
	
	// 带Bearer前缀
	claims, err := auth.ValidateToken("Bearer " + token)
	if err != nil {
		t.Errorf("Expected valid token with Bearer prefix, got error: %v", err)
	}
	if claims.PlayerID != "player-001" {
		t.Errorf("Expected player_id 'player-001', got '%s'", claims.PlayerID)
	}
}

// TestAuthenticator_GenerateToken 测试token生成
func TestAuthenticator_GenerateToken(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	
	token, err := auth.GenerateToken("player-001", 1*time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}
	if token == "" {
		t.Error("Expected non-empty token")
	}
	
	// 验证生成的token
	claims, err := auth.ValidateToken(token)
	if err != nil {
		t.Errorf("Failed to validate generated token: %v", err)
	}
	if claims.PlayerID != "player-001" {
		t.Errorf("Expected player_id 'player-001', got '%s'", claims.PlayerID)
	}
}
