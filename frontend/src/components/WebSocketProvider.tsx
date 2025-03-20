// File: frontend/src/components/WebSocketProvider.tsx

import React, { useEffect, useRef } from 'react';
import { WebSocketContext } from '../context/WebSocketContext.js';

const WS_URL = `${window.location.protocol === 'https:' ? 'wss' : 'ws'}://${
	window.location.hostname
}:3060`;

export const WebSocketProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
	const ws = useRef<WebSocket | null>(null);

	useEffect(() => {
		ws.current = new WebSocket(WS_URL);

		ws.current.onopen = () => console.log('Connected to PC WebSocket');
		ws.current.onmessage = event => {
			const message = event.data;
			console.log('Received:', message);

			if (message.startsWith('TTS: ')) {
				const speech = new SpeechSynthesisUtterance(message.replace('TTS: ', ''));
				speechSynthesis.speak(speech);
			}
		};

		ws.current.onerror = error => console.error('WebSocket error:', error);
		ws.current.onclose = () => console.log('WebSocket disconnected');

		return () => {
			ws.current?.close();
		};
	}, []);

	return <WebSocketContext.Provider value={ws.current}>{children}</WebSocketContext.Provider>;
};
