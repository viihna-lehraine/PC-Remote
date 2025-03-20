// File: frontend/src/context/WebSocketContext.ts

import { createContext } from 'react';

export const WebSocketContext = createContext<WebSocket | null>(null);
