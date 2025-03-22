// File: frontend/src/components/WebSocketProvider.tsx

import { WebSocketStatus } from '../types/index.js';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { WebSocketContext } from '../context/WebSocketContext.js';

const WS_URL = (() => {
	const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
	const hostWithPort = window.location.host;
	return `${protocol}//${hostWithPort}/ws/`;
})();
console.log(`[Websocket] Connecting to: ${WS_URL}`);

export const WebSocketProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
	const [status, setStatus] = useState<WebSocketStatus>('connecting');
	const wsRef = useRef<WebSocket | null>(null);
	const reconnectTimeout = useRef<number | null>(null);

	const connect = useCallback(() => {
		setStatus('connecting');

		const ws = new WebSocket(WS_URL);
		wsRef.current = ws;

		ws.onopen = () => {
			console.log('[WebSocket] Connected');
			setStatus('connected');
		};

		const scheduleReconnect = () => {
			if (reconnectTimeout.current) return;

			reconnectTimeout.current = window.setTimeout(() => {
				reconnectTimeout.current = null;
				connect();
			}, 3000);
		};

		ws.onclose = () => {
			console.warn('[WebSocket] Disconnected');
			setStatus('disconnected');
			scheduleReconnect();
		};

		ws.onerror = error => {
			console.error('[WebSocket] Error:', error);
			setStatus('error');
			scheduleReconnect();
		};

		ws.onmessage = event => {
			const message = event.data;
			console.log('[WebSocket] Received:', message);

			if (message.startsWith('TTS: ')) {
				const speech = new SpeechSynthesisUtterance(message.replace('TTS: ', ''));
				speechSynthesis.speak(speech);
			}
		};
	}, []);

	useEffect(() => {
		connect();
		return () => {
			wsRef.current?.close();
			if (reconnectTimeout.current) clearTimeout(reconnectTimeout.current);
		};
	}, [connect]);

	return (
		<WebSocketContext.Provider value={{ socket: wsRef.current, status }}>
			{children}
		</WebSocketContext.Provider>
	);
};
