import { WebSocketServer } from 'ws';
import { handleCommandSocket } from './commands.js';
// import { handleGestureSocket } from './gestures.js';
import { handleChatSocket, registerChatClient } from './chat.js';
import { fileURLToPath } from 'url';
import { createServer } from 'https';
import path from 'path';
import fs from 'fs';
import { env } from '../core/loadEnv.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const httpsOptions = {
	key: fs.readFileSync(path.join(__dirname, '../../config/tls/server.key')),
	cert: fs.readFileSync(path.join(__dirname, '../../config/tls/server.crt'))
};

const server = createServer(httpsOptions);
const wss = new WebSocketServer({ server });

wss.on('connection', ws => {
	console.log('Client connected');

	registerChatClient(ws);

	ws.on('message', message => {
		const command = message.toString();
		console.log(`Received command: ${command}`);

		if (command.startsWith('chat:')) {
			handleChatSocket(wss, ws, command);
		} else {
			handleCommandSocket(ws, command);
		}
	});

	ws.on('close', () => {
		console.log('Client disconnected');
	});
});

server.listen(env.WS_PORT, env.LISTEN_ADDR, () => {
	console.log(`WebSocket server running on wss://${env.LAN_IP_ADDR}:${env.WS_PORT}`);
});
