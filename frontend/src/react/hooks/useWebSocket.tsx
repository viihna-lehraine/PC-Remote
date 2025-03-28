// File: frontend/src/react/hooks/useWebSocket.ts

import { useContext } from 'react';
import { WebSocketContext } from '../context/WebSocketContext.js';

export const useWebSocket = () => {
	const context = useContext(WebSocketContext);
	if (!context) {
		throw new Error('useWebSocket must be used within a WebSocketProvider');
	}
	return context;
};
