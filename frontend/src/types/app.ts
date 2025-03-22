// File: frontend/src/types/app.ts

export interface WebSocketContextType {
	socket: WebSocket | null;
	status: WebSocketStatus;
}

export interface WebSocketContextValue {
	ws: WebSocket | null;
	status: WebSocketStatus;
}

export type WebSocketStatus = 'connecting' | 'connected' | 'disconnected' | 'error';
