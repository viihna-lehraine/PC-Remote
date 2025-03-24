import { WebSocketServer } from 'ws';
import { handleCommandSocket } from './commands.js';
// import { handleGestureSocket } from './gestures.js';
import { handleChatSocket, registerChatClient } from './chat.js';
import { createServer } from 'http';
import { env } from '../core/loadEnv.js';
const server = createServer();
const wss = new WebSocketServer({ server });
wss.on('connection', ws => {
    console.log('Client connected');
    registerChatClient(ws);
    ws.on('message', message => {
        const command = message.toString();
        console.log(`Received command: ${command}`);
        if (command.startsWith('chat:')) {
            handleChatSocket(wss, ws, command);
        }
        else {
            handleCommandSocket(ws, command);
        }
    });
    ws.on('close', () => {
        console.log('Client disconnected');
    });
});
server.listen(env.WS_PORT, env.LISTEN_ADDR, () => {
    console.log(`WebSocket server running on ws://${env.LAN_IP_ADDR}:${env.WS_PORT}`);
});
//# sourceMappingURL=index.js.map