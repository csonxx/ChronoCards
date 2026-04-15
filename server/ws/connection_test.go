package ws

import (
	"sync"
	"sync/atomic"
	"testing"
)

// TestClient_NewClient 测试客户端创建
func TestClient_NewClient(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	// NewClient 需要 websocket.Conn，这里用 nil 测试基本结构
	client := NewClient(hub, nil, "test-id")
	
	if client == nil {
		t.Fatal("Expected non-nil client")
	}
	if client.ID != "test-id" {
		t.Errorf("Expected ID 'test-id', got '%s'", client.ID)
	}
	if client.Send == nil {
		t.Error("Expected Send channel to be initialized")
	}
	if client.ctx == nil {
		t.Error("Expected ctx to be initialized")
	}
}

// TestClient_SetAuthenticated 测试设置认证状态
func TestClient_SetAuthenticated(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	client := NewClient(hub, nil, "test-id")
	
	// 初始状态未认证
	if client.IsAuthenticated() {
		t.Error("Expected client to be unauthenticated initially")
	}
	
	// 设置认证
	client.SetAuthenticated("player-001", "device-001", "session-001")
	
	// 验证认证状态
	if !client.IsAuthenticated() {
		t.Error("Expected client to be authenticated after SetAuthenticated")
	}
	if client.PlayerID != "player-001" {
		t.Errorf("Expected PlayerID 'player-001', got '%s'", client.PlayerID)
	}
	if client.DeviceID != "device-001" {
		t.Errorf("Expected DeviceID 'device-001', got '%s'", client.DeviceID)
	}
	if client.SessionID != "session-001" {
		t.Errorf("Expected SessionID 'session-001', got '%s'", client.SessionID)
	}
}

// TestClient_UpdateSeq_LastSeq 测试序列号更新
func TestClient_UpdateSeq_LastSeq(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	client := NewClient(hub, nil, "test-id")
	
	// 初始序列号应该是0
	if client.LastSeq() != 0 {
		t.Errorf("Expected initial LastSeq 0, got %d", client.LastSeq())
	}
	
	// 更新序列号
	client.UpdateSeq(100)
	if client.LastSeq() != 100 {
		t.Errorf("Expected LastSeq 100, got %d", client.LastSeq())
	}
	
	client.UpdateSeq(200)
	if client.LastSeq() != 200 {
		t.Errorf("Expected LastSeq 200, got %d", client.LastSeq())
	}
}

// TestClient_Close 测试客户端关闭
func TestClient_Close(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	client := NewClient(hub, nil, "test-id")
	
	// 首次关闭应该成功
	client.Close("normal closure")
	
	// 重复关闭应该安全
	client.Close("second close")
	
	// IsClosed 应该返回true
	if !client.IsClosed() {
		t.Error("Expected client to be closed")
	}
}

// TestClient_ConcurrentSetAuthenticated 测试并发设置认证状态
func TestClient_ConcurrentSetAuthenticated(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	client := NewClient(hub, nil, "test-id")
	
	var wg sync.WaitGroup
	
	// 并发设置认证状态
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func(idx int) {
			defer wg.Done()
			client.SetAuthenticated("player-001", "device-001", "session-001")
		}(i)
	}
	
	wg.Wait()
	
	// 认证状态应该一致
	if !client.IsAuthenticated() {
		t.Error("Expected client to be authenticated")
	}
}

// TestClient_idleResetChannel 测试idleReset通道
func TestClient_idleResetChannel(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	client := NewClient(hub, nil, "test-id")
	
	// 验证 idleReset 通道存在
	if client.idleReset == nil {
		t.Error("Expected idleReset channel to be initialized")
	}
	
	// 发送idleReset信号（非阻塞）
	select {
	case client.idleReset <- struct{}{}:
	default:
		t.Error("Failed to send to idleReset channel")
	}
}

// TestClient_LastSeq_Atomic 测试序列号原子性
func TestClient_LastSeq_Atomic(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	client := NewClient(hub, nil, "test-id")
	
	var wg sync.WaitGroup
	counter := atomic.Int64{}
	
	// 并发更新序列号
	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			val := counter.Add(1)
			client.UpdateSeq(val)
		}()
	}
	
	wg.Wait()
	
	// 最终序列号应该是100（最后一个值）
	finalSeq := client.LastSeq()
	if finalSeq != 100 {
		t.Errorf("Expected final seq 100, got %d", finalSeq)
	}
}
