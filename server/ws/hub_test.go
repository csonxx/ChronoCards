package ws

import (
	"sync"
	"testing"
	"time"
)

// TestHub_NewHub 测试Hub创建
func TestHub_NewHub(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	if hub == nil {
		t.Fatal("Expected non-nil hub")
	}
	if hub.Clients == nil {
		t.Error("Expected Clients map to be initialized")
	}
	if hub.IdleTimeout != 5*time.Minute {
		t.Errorf("Expected IdleTimeout 5m, got %v", hub.IdleTimeout)
	}
}

// TestHub_Run_Stop 测试Hub运行和停止
func TestHub_Run_Stop(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	// 运行hub
	hub.Run()
	
	// 再次运行应该直接返回（防止重复运行）
	hub.Run()
	
	// 停止hub
	hub.Stop()
	
	// 再次停止应该直接返回
	hub.Stop()
}

// TestHub_ClientCount 测试客户端计数
func TestHub_ClientCount(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	if hub.ClientCount() != 0 {
		t.Errorf("Expected 0 clients, got %d", hub.ClientCount())
	}
}

// TestHub_NextSeq 测试序列号生成
func TestHub_NextSeq(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	seq1 := hub.NextSeq()
	seq2 := hub.NextSeq()
	seq3 := hub.NextSeq()
	
	if seq2 != seq1+1 {
		t.Errorf("Expected seq2=%d, got %d", seq1+1, seq2)
	}
	if seq3 != seq2+1 {
		t.Errorf("Expected seq3=%d, got %d", seq2+1, seq3)
	}
}

// TestHub_Register_Unregister 测试客户端注册和注销
func TestHub_Register_Unregister(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	// 运行hub
	hub.Run()
	defer hub.Stop()
	
	// 创建测试客户端
	client := &Client{
		ID:   "test-client-1",
		Send: make(chan []byte, 256),
	}
	
	// 注册客户端
	hub.Register <- client
	
	// 等待处理
	time.Sleep(10 * time.Millisecond)
	
	if hub.ClientCount() != 1 {
		t.Errorf("Expected 1 client after register, got %d", hub.ClientCount())
	}
	
	// 注销客户端
	hub.Unregister <- client
	
	// 等待处理
	time.Sleep(10 * time.Millisecond)
	
	if hub.ClientCount() != 0 {
		t.Errorf("Expected 0 clients after unregister, got %d", hub.ClientCount())
	}
}

// TestHub_SendToPlayerID 测试向特定玩家发送消息
func TestHub_SendToPlayerID(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	hub.Run()
	defer hub.Stop()
	
	// 创建已认证的客户端
	client := &Client{
		ID:    "test-client-1",
		Send:  make(chan []byte, 256),
	}
	client.SetAuthenticated("player-001", "device-001", "session-001")
	
	hub.Register <- client
	time.Sleep(10 * time.Millisecond)
	
	// 向player-001发送消息
	msg := []byte("test message")
	hub.SendToPlayerID("player-001", msg)
	
	// 验证消息被发送
	select {
	case received := <-client.Send:
		if string(received) != string(msg) {
			t.Errorf("Expected message '%s', got '%s'", msg, received)
		}
	case <-time.After(100 * time.Millisecond):
		t.Error("Timeout waiting for message")
	}
	
	// 向不存在的玩家发送消息应该不阻塞
	hub.SendToPlayerID("player-999", msg)
}

// TestHub_Broadcast 测试广播消息
func TestHub_Broadcast(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	
	hub.Run()
	defer hub.Stop()
	
	// 创建多个已认证的客户端
	client1 := &Client{
		ID:    "client-1",
		Send:  make(chan []byte, 256),
	}
	client1.SetAuthenticated("player-001", "device-001", "session-001")
	
	client2 := &Client{
		ID:    "client-2",
		Send:  make(chan []byte, 256),
	}
	client2.SetAuthenticated("player-002", "device-002", "session-002")
	
	hub.Register <- client1
	hub.Register <- client2
	time.Sleep(10 * time.Millisecond)
	
	// 广播消息
	msg := []byte("broadcast message")
	hub.Broadcast(msg)
	
	// 验证两个客户端都收到消息
	for i, client := range []*Client{client1, client2} {
		select {
		case received := <-client.Send:
			if string(received) != string(msg) {
				t.Errorf("Client %d: Expected message '%s', got '%s'", i, msg, received)
			}
		case <-time.After(100 * time.Millisecond):
			t.Errorf("Client %d: Timeout waiting for broadcast message", i)
		}
	}
}

// TestHub_ConcurrentAccess 测试并发访问
func TestHub_ConcurrentAccess(t *testing.T) {
	auth := NewAuthenticator("test-secret")
	hub := NewHub(auth)
	hub.Run()
	defer hub.Stop()
	
	var wg sync.WaitGroup
	
	// 并发注册客户端
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			client := &Client{
				ID:   "client-" + string(rune('0'+id)),
				Send: make(chan []byte, 256),
			}
			hub.Register <- client
		}(i)
	}
	
	wg.Wait()
	time.Sleep(50 * time.Millisecond)
	
	count := hub.ClientCount()
	if count != 10 {
		t.Errorf("Expected 10 clients, got %d", count)
	}
}
