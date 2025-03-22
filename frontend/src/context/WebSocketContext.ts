// File: frontend/src/context/WebSocketContext.ts

import { WebSocketContextType } from '../types/index.js';
import { createContext } from 'react';

export const WebSocketContext = createContext<WebSocketContextType>({
	socket: null,
	status: 'connecting'
});
