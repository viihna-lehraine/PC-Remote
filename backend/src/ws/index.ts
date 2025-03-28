import { WebSocket, WebSocketServer } from 'ws';
import { handleCommandSocket } from './commands.js';
// import { handleGestureSocket } from './gestures.js';
import { handleChatSocket, registerChatClient } from './chat.js';
import { createServer } from 'http';
import { env } from '../core/env/loadEnv.js';

const server = createServer();
const wss = new WebSocketServer({ server });

const clients: Set<WebSocket> = new Set();

wss.on('connection', ws => {
	console.log('Client connected');

	clients.add(ws);

	registerChatClient(ws);

	ws.on('message', message => {
		const command = message.toString();
		console.log(`Received command: ${command}`);

		if (!command) {
			ws.send('ERROR: Empty message received');
			return;
		}

		if (command.startsWith('chat:')) {
			handleChatSocket(wss, ws, command);
		} else {
			handleCommandSocket(ws, command);
		}
	});

	ws.on('close', () => {
		console.log('Client disconnected');
		clients.delete(ws);
	});

	ws.on('error', error => {
		console.error('WebSocket error:', error);
		ws.send('ERROR: Something went wrong with the WebSocket connection!');
	});
});

server.listen(env.WS_PORT, env.LISTEN_ADDR, () => {
	console.log(`WebSocket server running on ws://${env.LAN_IP_ADDR}:${env.WS_PORT}`);
});
