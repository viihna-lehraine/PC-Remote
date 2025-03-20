// File: frontend/src/hooks/useWebSocket.ts

import { useContext } from 'react';
import { WebSocketContext } from '../context/WebSocketContext.js';

export const useWebSocket = () => {
	const ws = useContext(WebSocketContext);
	if (!ws) {
		throw new Error('useWebSocket must be used within a WebSocketProvider');
	}
	return ws;
};
