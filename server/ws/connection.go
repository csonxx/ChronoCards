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
	// idleReset signals that client activity was detected, resetting the idle timeout.
	idleReset chan struct{}
}

// NewClient creates a new client connection
func NewClient(hub *Hub, conn *websocket.Conn, id string) *Client {
	ctx, cancel := context.WithCancel(context.Background())
	return &Client{
		ID:        id,
		Conn:      conn,
		Hub:       hub,
		Send:      make(chan []byte, 256),
		ctx:       ctx,
		cancel:    cancel,
		idleReset: make(chan struct{}, 1),
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

	for {
		if c.IsClosed() {
			return
		}

		_, msg, err := c.Conn.Read(c.ctx)
		if err != nil {
			if c.IsClosed() {
				return
			}
			c.Hub.Unregister <- c
			return
		}

		// Signal activity to reset idle timeout
		select {
		case c.idleReset <- struct{}{}:
		default:
		}

		select {
		case c.Hub.Receive <- &MessagePacket{Client: c, Data: msg}:
		default:
			// Drop if buffer full
		}
	}
}

// WritePump pumps messages from the hub send channel to the websocket connection
func (c *Client) WritePump() {
	pingTick := time.NewTicker(30 * time.Second)
	defer func() {
		pingTick.Stop()
		c.Conn.Close(websocket.StatusNormalClosure, "")
	}()

	idleTimeout := c.Hub.IdleTimeout
	idleTimer := time.NewTimer(idleTimeout)
	idleTimer.Stop() // start stopped; first ping starts it

	// Single goroutine managing idle timeout.
	// Whenever a message is received from the client (ReadPump signals idleReset),
	// or whenever a ping is sent, the timer resets.
	// If the timer fires, the client is unresponsive → close.
	go func() {
		for {
			select {
			case <-c.ctx.Done():
				return
			case <-c.idleReset:
				idleTimer.Reset(idleTimeout)
			case <-idleTimer.C:
				c.Hub.Unregister <- c
				return
			}
		}
	}()

	for {
		select {
		case <-c.ctx.Done():
			return

		case <-pingTick.C:
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
				// Ping sent → reset idle timeout
				idleTimer.Reset(idleTimeout)
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
