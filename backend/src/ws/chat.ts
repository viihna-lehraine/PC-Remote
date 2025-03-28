// File: backend/src/ws/chat.ts

import { WebSocket, WebSocketServer } from 'ws';

const clients: Set<WebSocket> = new Set();

export function handleChatSocket(wss: WebSocketServer, ws: WebSocket, message: string) {
	const parts = message.split(':');
	if (parts.length < 3) {
		console.error('Invalid chat message format:', message);
		ws.send('ERROR: Invalid chat message format');
		return;
	}

	const [, username, chatMessage] = parts;
	const formattedMessage: string = `${username}: ${chatMessage}`;

	console.log(`💬 Chat Message: ${formattedMessage}`);

	// broadcast message to all connected clients
	wss.clients.forEach((client: WebSocket) => {
		if (client.readyState === WebSocket.OPEN) {
			client.send(`chat:${formattedMessage}`);
		}
	});
}

export function registerChatClient(ws: WebSocket) {
	clients.add(ws);
	ws.on('close', () => clients.delete(ws));
}
