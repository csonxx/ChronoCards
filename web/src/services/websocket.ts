// WebSocket 服务 - 对接 api_schema_websocket.md v1.0

import { saveManager } from './save-system';

export interface WSMessage {
  type: 'event' | 'request' | 'response' | 'error';
  event: string;
  seq: number;
  timestamp: string;
  data: unknown;
}

export interface AuthMessage {
  type: 'auth';
  player_id: string;
  token: string;
  device_id: string;
}

export interface AuthAckData {
  success: boolean;
  player_id?: string;
  session_id?: string;
  server_time?: string;
  error_code?: string;
  message?: string;
}

// Narrative event from server
export interface EventNarrativeData {
  trigger_type: string;
  player_id: string;
  card_id?: string;
  card_title?: string;
  dealer_id?: string;
  location?: string;
  content: {
    text: string;
    dialogue?: string;
    atmosphere?: string;
    audio_cue?: string;
  };
  display_duration_ms: number;
}

type NarrativeCallback = (data: EventNarrativeData) => void;
type ConnectionCallback = (connected: boolean) => void;

class NarrativeWebSocket {
  private ws: WebSocket | null = null;
  private url: string;
  private seq = 0;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private pingInterval: ReturnType<typeof setInterval> | null = null;
  private isConnecting = false;

  private narrativeCallbacks: Set<NarrativeCallback> = new Set();
  private connectionCallbacks: Set<ConnectionCallback> = new Set();

  constructor() {
    const wsBase = import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:8080';
    this.url = `${wsBase}/ws/v1`;
  }

  connect(): Promise<void> {
    if (this.ws?.readyState === WebSocket.OPEN || this.isConnecting) {
      return Promise.resolve();
    }

    this.isConnecting = true;
    return new Promise((resolve, reject) => {
      try {
        console.log('[WS] Connecting to', this.url);
        this.ws = new WebSocket(this.url);

        this.ws.onopen = () => {
          console.log('[WS] Connected');
          this.isConnecting = false;
          this.reconnectAttempts = 0;
          this.startPing();
          this.sendAuth();
          this.notifyConnection(true);
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            const msg: WSMessage = JSON.parse(event.data);
            this.handleMessage(msg);
          } catch (e) {
            console.error('[WS] Parse error:', e);
          }
        };

        this.ws.onerror = (error) => {
          console.error('[WS] Error:', error);
          this.isConnecting = false;
          reject(error);
        };

        this.ws.onclose = () => {
          console.log('[WS] Disconnected');
          this.isConnecting = false;
          this.stopPing();
          this.notifyConnection(false);
          this.scheduleReconnect();
        };
      } catch (err) {
        this.isConnecting = false;
        reject(err);
      }
    });
  }

  private sendAuth(): void {
    const player = saveManager.current?.player;
    if (!player) return;

    const authMsg: AuthMessage = {
      type: 'auth',
      player_id: player.id,
      token: import.meta.env.VITE_API_KEY || '',
      device_id: `web-${Date.now()}`,
    };
    this.send(authMsg);
  }

  private startPing(): void {
    this.pingInterval = setInterval(() => {
      this.send({ type: 'request', event: 'ping', seq: this.nextSeq(), timestamp: new Date().toISOString(), data: {} });
    }, 30000);
  }

  private stopPing(): void {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('[WS] Max reconnect attempts reached');
      return;
    }
    const delay = Math.min(this.reconnectDelay * Math.pow(2, this.reconnectAttempts), 30000);
    console.log(`[WS] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts + 1})`);
    setTimeout(() => {
      this.reconnectAttempts++;
      this.connect().catch(() => {});
    }, delay);
  }

  private send(msg: object): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(msg));
    }
  }

  private nextSeq(): number {
    return ++this.seq;
  }

  private handleMessage(msg: WSMessage): void {
    switch (msg.event) {
      case 'auth_ack': {
        const data = msg.data as AuthAckData;
        if (data.success) {
          console.log('[WS] Auth success, session:', data.session_id);
        } else {
          console.error('[WS] Auth failed:', data.message);
        }
        break;
      }
      case 'pong':
        // ping ack, nothing to do
        break;
      case 'event_narrative': {
        const narrativeData = msg.data as EventNarrativeData;
        this.narrativeCallbacks.forEach(cb => cb(narrativeData));
        break;
      }
      case 'sync': {
        console.log('[WS] Sync event:', msg.data);
        break;
      }
      default:
        console.log('[WS] Unknown event:', msg.event);
    }
  }

  // Public API

  onNarrative(callback: NarrativeCallback): () => void {
    this.narrativeCallbacks.add(callback);
    return () => this.narrativeCallbacks.delete(callback);
  }

  onConnection(callback: ConnectionCallback): () => void {
    this.connectionCallbacks.add(callback);
    return () => this.connectionCallbacks.delete(callback);
  }

  disconnect(): void {
    this.stopPing();
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  get connected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}

// Singleton
export const narrativeWS = new NarrativeWebSocket();