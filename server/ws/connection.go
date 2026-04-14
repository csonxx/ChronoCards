package ws

import (
	"context"
	"sync"
	"sync/atomic"
	"time"

	"nhooyr.io/websocket"
)

// Client represents a single WebSocket client connection
type Client struct {
	ID         string
	PlayerID   string
	DeviceID   string
	SessionID  string
	Conn       *websocket.Conn
	Hub        *Hub
	Send       chan []byte
	mu         sync.RWMutex
	authenticated bool
	lastSeq    int64
	closeOnce  sync.Once
	closed     atomic.Bool
	ctx        context.Context
	cancel     context.CancelFunc
	pingCount  int32 // consecutive missed pongs
}

// NewClient creates a new client connection
func NewClient(hub *Hub, conn *websocket.Conn, id string) *Client {
	ctx, cancel := context.WithCancel(context.Background())
	return &Client{
		ID:     id,
		Conn:   conn,
		Hub:    hub,
		Send:   make(chan []byte, 256),
		ctx:    ctx,
		cancel: cancel,
	}
}

// SetAuthenticated marks the client as authenticated
func (c *Client) SetAuthenticated(playerID, deviceID, sessionID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.authenticated = true
	c.PlayerID = playerID
	c.DeviceID = deviceID
	c.SessionID = sessionID
}

// IsAuthenticated returns whether the client has been authenticated
func (c *Client) IsAuthenticated() bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.authenticated
}

// UpdateSeq updates the last seen sequence number
func (c *Client) UpdateSeq(seq int64) {
	atomic.StoreInt64(&c.lastSeq, seq)
}

// LastSeq returns the last seen sequence number
func (c *Client) LastSeq() int64 {
	return atomic.LoadInt64(&c.lastSeq)
}

// Close gracefully closes the client connection
func (c *Client) Close(reason string) {
	if c.closed.Swap(true) {
		return
	}
	c.cancel()
	c.closeOnce.Do(func() {
		close(c.Send)
	})
}

// IsClosed returns whether the client is closed
func (c *Client) IsClosed() bool {
	return c.closed.Load()
}

// ReadPump pumps messages from the websocket connection to the hub
func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Conn.Close(websocket.StatusNormalClosure, "")
	}()

	// Idle timeout: disconnect if no message received for 60 seconds
	idleTimer := time.NewTimer(60 * time.Second)
	defer idleTimer.Stop()

	for {
		if c.IsClosed() {
			return
		}

		// Reset idle timer on each read attempt
		if !idleTimer.Stop() {
			<-idleTimer.C
		}
		idleTimer.Reset(60 * time.Second)

		_, msg, err := c.Conn.Read(c.ctx)
		if err != nil {
			if c.IsClosed() {
				return
			}
			c.Hub.Unregister <- c
			return
		}

		select {
		case c.Hub.Receive <- &MessagePacket{Client: c, Data: msg}:
		default:
			// Drop if buffer full
		}

		// Check if idle timer fired (client was idle too long)
		select {
		case <-idleTimer.C:
			c.Hub.Unregister <- c
			return
		default:
		}
	}
}

// WritePump pumps messages from the hub send channel to the websocket connection
func (c *Client) WritePump() {
	// Server-side ping ticker: every 30 seconds
	pingTick := time.NewTicker(30 * time.Second)
	defer func() {
		pingTick.Stop()
		c.Conn.Close(websocket.StatusNormalClosure, "")
	}()

	for {
		select {
		case <-c.ctx.Done():
			return

		case <-pingTick.C:
			// Server-side ping: require client to respond with pong
			c.mu.RLock()
			authenticated := c.authenticated
			c.mu.RUnlock()

			if !authenticated {
				continue
			}

			pingMsg := MustMarshal(BaseMessage{
				Type:      TypeRequest,
				Event:     EventPing,
				Seq:       atomic.AddInt64(&c.Hub.seqCounter, 1),
				Timestamp: NowISO(),
				Data:      map[string]interface{}{},
			})

			select {
			case c.Send <- pingMsg:
				// sent
			default:
				// skip if buffer full
			}

		case message, ok := <-c.Send:
			if !ok {
				c.Conn.Close(websocket.StatusNormalClosure, "")
				return
			}

			err := c.Conn.Write(c.ctx, websocket.MessageText, message)
			if err != nil {
				return
			}
		}
	}
}

// MessagePacket is a message received from a client
type MessagePacket struct {
	Client *Client
	Data   []byte
}
