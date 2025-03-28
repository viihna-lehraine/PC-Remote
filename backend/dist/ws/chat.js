// File: backend/src/ws/chat.ts
import { WebSocket } from 'ws';
const clients = new Set();
export function handleChatSocket(wss, ws, message) {
    const parts = message.split(':');
    if (parts.length < 3) {
        console.error('Invalid chat message format:', message);
        ws.send('ERROR: Invalid chat message format');
        return;
    }
    const [, username, chatMessage] = parts;
    const formattedMessage = `${username}: ${chatMessage}`;
    console.log(`💬 Chat Message: ${formattedMessage}`);
    // broadcast message to all connected clients
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(`chat:${formattedMessage}`);
        }
    });
}
export function registerChatClient(ws) {
    clients.add(ws);
    ws.on('close', () => clients.delete(ws));
}
//# sourceMappingURL=chat.js.map